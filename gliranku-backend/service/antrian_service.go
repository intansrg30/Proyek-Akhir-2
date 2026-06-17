package service

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"gliranku/dto/request"
	"gliranku/dto/response"
	"gliranku/models"
	"gliranku/repository"
)

type AntrianService interface {
	GetPoliklinik() ([]response.LayananResponse, error)
	GetAvailablePoliklinik(tanggal string) ([]response.LayananResponse, error)
	VerifyNIK(nik string) (*response.CekNIKResponse, error)
	CreateAntrian(req request.AntrianRequest) (*response.AntrianResponse, error)
	GetDashboardStats() (int, int, int, error)
	GetKunjunganStats(period string) ([]models.KunjunganStatPoli, error)
	GetTicketByBookingCode(code string) (*response.AntrianResponse, error)
	CreatePharmacyTicket() (*models.TiketFarmasi, error)
	CreateBpjsTicket(nik string) (*response.AntrianResponse, error)
	CreateBpjsAntrian(req request.BpjsAntrianRequest) (*response.AntrianResponse, error)
	GetRiwayatAntrian(nik string) ([]response.AntrianResponse, error)
	DeleteAntrian(kodeBooking string) error
	GetRujukanBPJS(nik string) ([]response.RujukanResponse, error)
}

type antrianService struct {
	repo repository.AntrianRepository
	mu   sync.Mutex
}

func NewAntrianService(repo repository.AntrianRepository) AntrianService {
	return &antrianService{repo: repo}
}

func (s *antrianService) GetPoliklinik() ([]response.LayananResponse, error) {
	polis, err := s.repo.FetchPoliklinik()
	if err != nil {
		return nil, err
	}
	var result []response.LayananResponse
	for _, p := range polis {
		result = append(result, response.LayananResponse{
			ID:   p.PolyID,
			Nama: p.PolyName,
		})
	}
	return result, nil
}

func (s *antrianService) GetAvailablePoliklinik(tanggal string) ([]response.LayananResponse, error) {
	polis, err := s.repo.FetchAvailablePoliklinik(tanggal)
	if err != nil {
		return nil, err
	}
	var result []response.LayananResponse
	for _, p := range polis {
		result = append(result, response.LayananResponse{
			ID:   p.PolyID,
			Nama: p.PolyName,
		})
	}
	return result, nil
}

func (s *antrianService) VerifyNIK(nik string) (*response.CekNIKResponse, error) {
	pasien, err := s.repo.CheckNIK(nik)
	if err != nil {
		return nil, err
	}
	if pasien == nil {
		return &response.CekNIKResponse{
			IsValid: false,
			Message: "Data pasien tidak ditemukan",
		}, nil
	}

	isBPJS := pasien.NoBPJS != nil && *pasien.NoBPJS != ""

	return &response.CekNIKResponse{
		IsValid:    true,
		IsBPJS:     isBPJS,
		NamaPasien: pasien.PatientName,
		Message:    "Data pasien ditemukan",
	}, nil
}

func (s *antrianService) CreateAntrian(req request.AntrianRequest) (*response.AntrianResponse, error) {
	if !req.IsPasienLama && req.NamaPasien != "-" {
		pasien, _ := s.repo.CheckNIK(req.NIK)
		if pasien != nil {
			if !strings.EqualFold(pasien.PatientName, req.NamaPasien) {
				return nil, fmt.Errorf("nama tidak sesuai dengan NIK yang terdaftar")
			}
		}
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	var tanggal time.Time
	var err error
	if req.Tanggal != "" {
		tanggal, err = time.Parse("2006-01-02", req.Tanggal)
		if err != nil {
			return nil, fmt.Errorf("format tanggal tidak valid, gunakan YYYY-MM-DD")
		}
	} else {
		tanggal = time.Now()
	}

	loc, _ := time.LoadLocation("Asia/Jakarta")
	nowWIB := time.Now().In(loc)
	if nowWIB.Weekday() == time.Sunday {
		return nil, fmt.Errorf("pendaftaran antrian tidak tersedia pada hari Minggu")
	}
	hour := nowWIB.Hour()
	if hour < 8 || hour >= 16 {
		return nil, fmt.Errorf("pendaftaran antrian hanya tersedia pada jam operasional (08:00 - 16:00 WIB)")
	}

	hasActive, err := s.repo.HasActiveAntrianInPoli(req.NIK, tanggal, req.PoliID)
	if err != nil {
		return nil, fmt.Errorf("gagal memeriksa antrian aktif: %w", err)
	}
	if hasActive {
		return nil, fmt.Errorf("Anda sudah mengambil antrian ke poli ini pada hari ini")
	}

	if req.DokterID != nil {
		tanggalStr := tanggal.Format("2006-01-02")
		docStatus, wMulai, wSelesai, err := s.repo.GetDoctorStatusOnDate(*req.DokterID, tanggalStr)
		if err != nil {
			return nil, fmt.Errorf("gagal memeriksa status dokter: %w", err)
		}
		if strings.ToLower(docStatus) != "hadir" {
			if wMulai != "" && wSelesai != "" {
				loc, _ := time.LoadLocation("Asia/Jakarta")
				nowWIB := time.Now().In(loc)
				var checkTime time.Time
				if tanggal.Format("2006-01-02") == nowWIB.Format("2006-01-02") {
					checkTime = nowWIB
				} else {
					checkTime, _ = time.ParseInLocation("2006-01-02 15:04", tanggal.Format("2006-01-02")+" 08:00", loc)
				}
				tMulai, err1 := time.ParseInLocation("2006-01-02 15:04", tanggal.Format("2006-01-02")+" "+wMulai, loc)
				tSelesai, err2 := time.ParseInLocation("2006-01-02 15:04", tanggal.Format("2006-01-02")+" "+wSelesai, loc)
				
				if err1 == nil && err2 == nil {
					if (checkTime.Equal(tMulai) || checkTime.After(tMulai)) && (checkTime.Equal(tSelesai) || checkTime.Before(tSelesai)) {
						return nil, fmt.Errorf("dokter sedang %s dari jam %s sampai %s", docStatus, wMulai, wSelesai)
					}
				} else {
					return nil, fmt.Errorf("dokter tidak tersedia pada tanggal tersebut (status: %s)", docStatus)
				}
			} else {
				return nil, fmt.Errorf("dokter tidak tersedia pada tanggal tersebut (status: %s)", docStatus)
			}
		}
		remaining, err := s.repo.GetRemainingQuotaOnDate(*req.DokterID, tanggalStr)
		if err != nil {
			return nil, fmt.Errorf("gagal memeriksa sisa kuota dokter: %w", err)
		}
		if remaining <= 0 {
			return nil, fmt.Errorf("kuota pendaftaran dokter tersebut pada tanggal ini sudah habis")
		}
	}

	var polyName string
	var kodePoli string = "A"
	polis, _ := s.repo.FetchPoliklinik()
	for _, p := range polis {
		if p.PolyID == req.PoliID {
			polyName = p.PolyName
			if p.KodePoli != nil {
				kodePoli = *p.KodePoli
			}
			break
		}
	}

	lastGlobal, err := s.repo.GetLastQueueNumberGlobal(tanggal)
	if err != nil {
		return nil, fmt.Errorf("gagal mendapatkan nomor antrian global: %w", err)
	}
	nomorUrutGlobal := lastGlobal + 1
	noAntrian := fmt.Sprintf("%03d", nomorUrutGlobal)

	lastPoli, err := s.repo.GetLastQueueNumberPoli(req.PoliID, tanggal)
	if err != nil {
		return nil, fmt.Errorf("gagal mendapatkan nomor antrian poli: %w", err)
	}
	nomorUrutPoli := lastPoli + 1
	noAntrianPoli := fmt.Sprintf("%s%03d", kodePoli, nomorUrutPoli)

	kodeBooking := repository.GenerateKodeBooking(tanggal, kodePoli, nomorUrutPoli)

	pembayaran := "Umum"
	
	namaPasien := req.NamaPasien
	telepon := req.Telepon

	if req.IsPasienLama || req.NamaPasien == "-" {
		if p, err := s.repo.CheckNIK(req.NIK); err == nil && p != nil {
			namaPasien = p.PatientName
			if p.Phone != nil {
				telepon = *p.Phone
			}
		}
	}

	antrian := &models.Antrian{
		NoAntrian:     noAntrian,
		NoAntrianPoli: noAntrianPoli,
		KodeBooking:   kodeBooking,
		NIK:           req.NIK,
		NamaPasien:    namaPasien,
		Telepon:       telepon,
		PoliID:        req.PoliID,
		DokterID:      req.DokterID,
		Tanggal:       tanggal,
		WaktuMulai:    "09:00",
		WaktuSelesai:  "12:00",
		Pembayaran:    pembayaran,
		IsPasienLama:  req.IsPasienLama,
		Status:        "menunggu",
	}

	if err := s.repo.SaveAntrian(antrian); err != nil {
		fmt.Printf("Error SaveAntrian: %v\n", err)
		return nil, fmt.Errorf("gagal menyimpan antrian: %w", err)
	}

	dokterName := "-"
	if req.DokterID != nil {
		name, err := s.repo.GetDoctorNameByID(*req.DokterID)
		if err == nil {
			dokterName = name
		}
	}

	return &response.AntrianResponse{
		NoAntrian:     noAntrian,
		NoAntrianPoli: noAntrianPoli,
		KodeBooking:   kodeBooking,
		Poliklinik:    polyName,
		Dokter:        dokterName,
		Tanggal:       tanggal.Format("02-01-2006"),
		Waktu:         "09:00 - 12:00",
		Pembayaran:    pembayaran,
		Status:        "menunggu",
	}, nil
}

func (s *antrianService) GetDashboardStats() (int, int, int, error) {
	return s.repo.GetDashboardStats()
}

func (s *antrianService) GetKunjunganStats(period string) ([]models.KunjunganStatPoli, error) {
	return s.repo.GetKunjunganStats(period)
}

func (s *antrianService) GetTicketByBookingCode(code string) (*response.AntrianResponse, error) {
	a, err := s.repo.GetTicketByBookingCode(code)
	if err != nil {
		return nil, err
	}
	if a == nil {
		return nil, nil
	}

	if a.PrintCount >= 3 {
		return nil, fmt.Errorf("Kode booking sudah mencapai limit penggunaan (3 kali)")
	}

	_ = s.repo.IncrementPrintCount(code)
	
	namaPoliklinik := fmt.Sprintf("Poli %d", a.PoliID)
	polis, _ := s.repo.FetchPoliklinik()
	for _, p := range polis {
		if p.PolyID == a.PoliID {
			namaPoliklinik = p.PolyName
			break
		}
	}
	
	namaDokter := "dr. -"
	if a.DokterID != nil {
		if name, err := s.repo.GetDoctorNameByID(*a.DokterID); err == nil && name != "" {
			namaDokter = name
		}
	}
	
	return &response.AntrianResponse{
		NoAntrian:     a.NoAntrian,
		NoAntrianPoli: a.NoAntrianPoli,
		KodeBooking:   a.KodeBooking,
		Poliklinik:    namaPoliklinik,
		Dokter:        namaDokter,
		Tanggal:       a.Tanggal.Format("02 Jan 2006"),
		Waktu:         fmt.Sprintf("%s - %s", a.WaktuMulai, a.WaktuSelesai),
		Pembayaran:    a.Pembayaran,
		NamaPasien:    a.NamaPasien,
	}, nil
}

func (s *antrianService) CreatePharmacyTicket() (*models.TiketFarmasi, error) {
	return s.repo.CreatePharmacyTicket()
}

func (s *antrianService) CreateBpjsTicket(nik string) (*response.AntrianResponse, error) {
	pasien, err := s.repo.CheckNIK(nik)
	if err != nil {
		return nil, fmt.Errorf("gagal memeriksa NIK: %w", err)
	}
	if pasien == nil {
		return nil, fmt.Errorf("pasien dengan NIK %s tidak ditemukan", nik)
	}

	referral, err := s.repo.GetBpjsReferralByNik(nik)
	if err != nil {
		return nil, fmt.Errorf("gagal mencari rujukan BPJS: %w", err)
	}
	if referral == nil {
		return nil, fmt.Errorf("rujukan BPJS untuk NIK %s belum tersedia", nik)
	}

	req := request.AntrianRequest{
		NIK:          nik,
		NamaPasien:   pasien.PatientName,
		Telepon:      "-",
		PoliID:       referral.PoliID,
		DokterID:     &referral.DoctorID,
		IsPasienLama: true,
	}

	if pasien.Phone != nil && *pasien.Phone != "" {
		req.Telepon = *pasien.Phone
	}

	return s.CreateAntrian(req)
}

func (s *antrianService) GetRiwayatAntrian(nik string) ([]response.AntrianResponse, error) {
	data, err := s.repo.GetRiwayatByNIK(nik)
	if err != nil {
		return nil, err
	}

	var results []response.AntrianResponse
	for _, item := range data {
		results = append(results, response.AntrianResponse{
			NoAntrian:   item.NoAntrian,
			KodeBooking: item.KodeBooking,
			Poliklinik:  item.Poliklinik,
			Dokter:      item.Dokter,
			Tanggal:     item.Tanggal.Format("02-01-2006"),
			Waktu:       fmt.Sprintf("%s - %s", item.WaktuMulai, item.WaktuSelesai),
			Pembayaran:  item.Pembayaran,
			Status:      item.Status,
		})
	}
	return results, nil
}

func (s *antrianService) CreateBpjsAntrian(req request.BpjsAntrianRequest) (*response.AntrianResponse, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	loc, _ := time.LoadLocation("Asia/Jakarta")
	nowWIB := time.Now().In(loc)
	if nowWIB.Weekday() == time.Sunday {
		return nil, fmt.Errorf("pendaftaran antrian tidak tersedia pada hari Minggu")
	}
	bpjsHour := nowWIB.Hour()
	if bpjsHour < 8 || bpjsHour >= 16 {
		return nil, fmt.Errorf("pendaftaran antrian hanya tersedia pada jam operasional (08:00 - 16:00 WIB)")
	}

	tanggal := time.Now()

	if req.DokterID != nil {
		tanggalStr := tanggal.Format("2006-01-02")
		docStatus, wMulai, wSelesai, err := s.repo.GetDoctorStatusOnDate(*req.DokterID, tanggalStr)
		if err != nil {
			return nil, fmt.Errorf("gagal memeriksa status dokter: %w", err)
		}
		if strings.ToLower(docStatus) != "hadir" {
			if wMulai != "" && wSelesai != "" {
				loc, _ := time.LoadLocation("Asia/Jakarta")
				nowWIB := time.Now().In(loc)
				
				tMulai, err1 := time.ParseInLocation("2006-01-02 15:04", tanggal.Format("2006-01-02")+" "+wMulai, loc)
				tSelesai, err2 := time.ParseInLocation("2006-01-02 15:04", tanggal.Format("2006-01-02")+" "+wSelesai, loc)
				
				if err1 == nil && err2 == nil {
					if (nowWIB.Equal(tMulai) || nowWIB.After(tMulai)) && (nowWIB.Equal(tSelesai) || nowWIB.Before(tSelesai)) {
						return nil, fmt.Errorf("dokter sedang %s dari jam %s sampai %s", docStatus, wMulai, wSelesai)
					}
				} else {
					return nil, fmt.Errorf("dokter tidak tersedia pada hari ini (status: %s)", docStatus)
				}
			} else {
				return nil, fmt.Errorf("dokter tidak tersedia pada hari ini (status: %s)", docStatus)
			}
		}
		remaining, err := s.repo.GetRemainingQuotaOnDate(*req.DokterID, tanggalStr)
		if err != nil {
			return nil, fmt.Errorf("gagal memeriksa sisa kuota dokter: %w", err)
		}
		if remaining <= 0 {
			return nil, fmt.Errorf("kuota pendaftaran dokter tersebut pada hari ini sudah habis")
		}
	}

	const bpjsApiKey = ""
	const bpjsApiUrl = ""

	type BpjsRujukanResponse struct {
		MetaHead struct {
			Code    string `json:"code"`
			Message string `json:"message"`
		} `json:"metaHead"`
		Response struct {
			Rujukan struct {
				NoRujukan   string `json:"noRujukan"`
				TglRujukan  string `json:"tglRujukan"`
				PoliRujukan struct {
					Kode string `json:"kode"`
					Nama string `json:"nama"`
				} `json:"poliRujukan"`
				Peserta struct {
					Nama    string `json:"nama"`
					Nik     string `json:"nik"`
					NoMr    string `json:"noMr"`
					NoKartu string `json:"noKartu"`
				} `json:"peserta"`
				ProvPerujuk struct {
					Kode string `json:"kode"`
					Nama string `json:"nama"`
				} `json:"provPerujuk"`
			} `json:"rujukan"`
		} `json:"response"`
	}

	var bpjsPoliName = "Poli Bedah"
	var namaPasien = "ROMAULI MANURUNG"
	var noRM = "449985"
	var bpjsSuccess = false

	if bpjsApiKey != "" {
		client := &http.Client{Timeout: 5 * time.Second}
		reqUrl := fmt.Sprintf("%s/%s", bpjsApiUrl, req.NoRujukan)
		reqHttp, err := http.NewRequest("GET", reqUrl, nil)
		if err == nil {
			reqHttp.Header.Set("X-Cons-ID", bpjsApiKey)
			resp, errDo := client.Do(reqHttp)
			if errDo == nil {
				defer resp.Body.Close()
				bodyBytes, errRead := io.ReadAll(resp.Body)
				if errRead == nil && resp.StatusCode == http.StatusOK {
					var rujukanData BpjsRujukanResponse
					if errUnmarshal := json.Unmarshal(bodyBytes, &rujukanData); errUnmarshal == nil && rujukanData.MetaHead.Code == "200" {
						bpjsPoliName = rujukanData.Response.Rujukan.PoliRujukan.Nama
						namaPasien = rujukanData.Response.Rujukan.Peserta.Nama
						noRM = rujukanData.Response.Rujukan.Peserta.NoMr
						bpjsSuccess = true
					}
				}
			}
		}
	}

	if !bpjsSuccess {
		pasien, err := s.repo.CheckNIK(req.NIK)
		if err == nil && pasien != nil {
			namaPasien = pasien.PatientName
			if pasien.NoRM != nil {
				noRM = *pasien.NoRM
			}
		}
		lowered := strings.ToLower(req.NoRujukan)
		if strings.Contains(lowered, "bedah") {
			bpjsPoliName = "Poli Bedah"
		} else if strings.Contains(lowered, "anak") {
			bpjsPoliName = "Poli Anak"
		} else if strings.Contains(lowered, "umum") {
			bpjsPoliName = "Poli Umum"
		} else if strings.Contains(lowered, "gigi") {
			bpjsPoliName = "Poli Gigi"
		}
	}

	var poliID int = 1
	var polyName string = "Poli Umum"
	var kodePoli string = "A"

	polis, err := s.repo.FetchPoliklinik()
	if err == nil {
		for _, p := range polis {
			if strings.Contains(strings.ToLower(p.PolyName), strings.ToLower(bpjsPoliName)) {
				poliID = p.PolyID
				polyName = p.PolyName
				if p.KodePoli != nil {
					kodePoli = *p.KodePoli
				}
				break
			}
		}
	}

	hasActiveBpjs, errCheck := s.repo.HasActiveAntrianInPoli(req.NIK, tanggal, poliID)
	if errCheck != nil {
		return nil, fmt.Errorf("gagal memeriksa antrian aktif: %w", errCheck)
	}
	if hasActiveBpjs {
		return nil, fmt.Errorf("Anda sudah mengambil antrian ke poli ini pada hari ini")
	}

	lastGlobal, err := s.repo.GetLastQueueNumberGlobal(tanggal)
	if err != nil {
		return nil, fmt.Errorf("gagal mendapatkan nomor antrian global: %w", err)
	}
	nomorUrutGlobal := lastGlobal + 1
	noAntrian := fmt.Sprintf("%03d", nomorUrutGlobal)

	lastPoli, err := s.repo.GetLastQueueNumberPoli(poliID, tanggal)
	if err != nil {
		return nil, fmt.Errorf("gagal mendapatkan nomor antrian poli: %w", err)
	}
	nomorUrutPoli := lastPoli + 1
	noAntrianPoli := fmt.Sprintf("%s%03d", kodePoli, nomorUrutPoli)

	kodeBooking := repository.GenerateKodeBooking(tanggal, kodePoli, nomorUrutPoli)

	sourceVal := req.Source
	if sourceVal == "" {
		sourceVal = "smartphone"
	}

	antrian := &models.Antrian{
		NoAntrian:     noAntrian,
		NoAntrianPoli: noAntrianPoli,
		KodeBooking:   kodeBooking,
		NIK:           req.NIK,
		NamaPasien:    namaPasien,
		Telepon:       "-",
		PoliID:        poliID,
		DokterID:      req.DokterID,
		Tanggal:       tanggal,
		WaktuMulai:    "09:00",
		WaktuSelesai:  "12:00",
		Pembayaran:    "BPJS",
		IsPasienLama:  true,
		Status:        "menunggu",
		Source:        sourceVal,
		NoRM:          noRM,
	}

	if err := s.repo.SaveAntrian(antrian); err != nil {
		return nil, fmt.Errorf("gagal menyimpan antrian BPJS: %w", err)
	}

	dokterName := "dr. -"
	if req.DokterID != nil {
		if name, err := s.repo.GetDoctorNameByID(*req.DokterID); err == nil {
			dokterName = name
		}
	}

	return &response.AntrianResponse{
		NoAntrian:     noAntrian,
		NoAntrianPoli: noAntrianPoli,
		KodeBooking:   kodeBooking,
		Poliklinik:    polyName,
		Dokter:        dokterName,
		Tanggal:       tanggal.Format("02-01-2006"),
		Waktu:         "09:00 - 12:00",
		Pembayaran:    "BPJS",
		Status:        "menunggu",
		Source:        sourceVal,
		NoRM:          noRM,
		NamaPasien:    namaPasien,
	}, nil
}

func (s *antrianService) DeleteAntrian(kodeBooking string) error {
	return s.repo.DeleteAntrian(kodeBooking)
}

func (s *antrianService) GetRujukanBPJS(nik string) ([]response.RujukanResponse, error) {
	var result []response.RujukanResponse
	ref, err := s.repo.GetBpjsReferralByNik(nik)
	
	if err == nil && ref != nil {
		poliNama := "Poli Bedah"
		if ref.PoliID == 2 {
			poliNama = "Poli Anak"
		} else if ref.PoliID == 3 {
			poliNama = "Poli Umum"
		}

		result = append(result, response.RujukanResponse{
			NoRujukan:  fmt.Sprintf("RJ-%s-01", nik),
			Tanggal:    time.Now().Format("02-01-2006"),
			PoliNama:   poliNama,
			PoliID:     ref.PoliID,
			AsalFaskes: "Puskesmas Laguboti",
			Diagnosa:   "A00 - Cholera",
		})
	}

	if len(result) == 0 {
		result = append(result, response.RujukanResponse{
			NoRujukan:  fmt.Sprintf("BPJS-%s-99", nik),
			Tanggal:    time.Now().Format("02-01-2006"),
			PoliNama:   "Poli Bedah",
			PoliID:     1,
			AsalFaskes: "Klinik Utama",
			Diagnosa:   "K30 - Dyspepsia",
		})
	}

	return result, nil
}
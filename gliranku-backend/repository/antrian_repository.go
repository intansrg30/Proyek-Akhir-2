package repository

import (
	"database/sql"
	"fmt"
	"math/rand"
	"strings"
	"time"

	"gliranku/models"
)

type AntrianRepository interface {
	FetchPoliklinik() ([]models.Poliklinik, error)
	FetchAvailablePoliklinik(tanggal string) ([]models.Poliklinik, error)
	CheckNIK(nik string) (*models.Pasien, error)
	CheckNameCaseInsensitive(name string) (*models.Pasien, error)
	GetLastQueueNumberPoli(poliID int, tanggal time.Time) (int, error)
	GetLastQueueNumberGlobal(tanggal time.Time) (int, error)
	SaveAntrian(antrian *models.Antrian) error
	GetDashboardStats() (int, int, int, error)
	GetKunjunganStats(period string) ([]models.KunjunganStatPoli, error)
	GetTicketByBookingCode(code string) (*models.Antrian, error)
	CreatePharmacyTicket() (*models.TiketFarmasi, error)
	GetBpjsReferralByNik(nik string) (*models.BpjsReferral, error)
	GetRiwayatByNIK(nik string) ([]models.AntrianResponseExtended, error)
	DecrementDoctorQuota(doctorID int) error
	GetDoctorNameByID(doctorID int) (string, error)
	DeleteAntrian(kodeBooking string) error
	IncrementPrintCount(kodeBooking string) error
	HasActiveAntrianInPoli(nik string, tanggal time.Time, poliID int) (bool, error)
	GetDoctorStatusOnDate(dokterID int, tanggal string) (string, string, string, error)
	GetRemainingQuotaOnDate(dokterID int, tanggal string) (int, error)
}

type antrianRepository struct {
	db *sql.DB
}

func NewAntrianRepository(db *sql.DB) AntrianRepository {
	return &antrianRepository{db: db}
}

func (r *antrianRepository) FetchPoliklinik() ([]models.Poliklinik, error) {
	rows, err := r.db.Query(
		`SELECT "IdPoli", "NamaPoli", "KodePoli" FROM tbpoli ORDER BY "NamaPoli"`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []models.Poliklinik
	for rows.Next() {
		var p models.Poliklinik
		if err := rows.Scan(&p.PolyID, &p.PolyName, &p.KodePoli); err != nil {
			continue
		}
		p.IsActive = true
		result = append(result, p)
	}
	return result, nil
}

func (r *antrianRepository) FetchAvailablePoliklinik(tanggal string) ([]models.Poliklinik, error) {
	query := `
		SELECT DISTINCT p."IdPoli", p."NamaPoli", p."KodePoli"
		FROM tbpoli p
		WHERE EXISTS (
			SELECT 1 FROM category c
			LEFT JOIN status_dokter sk ON sk.dokter_id = c.id AND sk.tanggal = $1::date
			WHERE c."IdPoli" = p."IdPoli" AND c.app = 1
			AND COALESCE(sk.status, 'hadir') = 'hadir'
			AND (
				(EXTRACT(ISODOW FROM $1::date) = 1 AND COALESCE(c.senin, '') != '') OR
				(EXTRACT(ISODOW FROM $1::date) = 2 AND COALESCE(c.selasa, '') != '') OR
				(EXTRACT(ISODOW FROM $1::date) = 3 AND COALESCE(c.rabu, '') != '') OR
				(EXTRACT(ISODOW FROM $1::date) = 4 AND COALESCE(c.kamis, '') != '') OR
				(EXTRACT(ISODOW FROM $1::date) = 5 AND COALESCE(c.jumat, '') != '') OR
				(EXTRACT(ISODOW FROM $1::date) = 6 AND COALESCE(c.sabtu, '') != '') OR
				(EXTRACT(ISODOW FROM $1::date) = 7 AND COALESCE(c.minggu, '') != '') OR
				sk.id IS NOT NULL
			)
			AND (COALESCE(sk.kuota_custom, c."KuotaNonJKN", 30) - (SELECT COUNT(*) FROM antrian a WHERE a.dokter_id = c.id AND DATE(a.tanggal) = $1::date AND a.status != 'dibatalkan')) > 0
		)
		ORDER BY p."NamaPoli"
	`
	rows, err := r.db.Query(query, tanggal)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []models.Poliklinik
	for rows.Next() {
		var p models.Poliklinik
		if err := rows.Scan(&p.PolyID, &p.PolyName, &p.KodePoli); err != nil {
			continue
		}
		p.IsActive = true
		result = append(result, p)
	}
	return result, nil
}

func (r *antrianRepository) CheckNIK(nik string) (*models.Pasien, error) {
	row := r.db.QueryRow(
		`SELECT nik, norm, patientname, phone, "noBPJS"
		 FROM pasien WHERE nik = $1`, nik)

	var p models.Pasien
	err := row.Scan(&p.NIK, &p.NoRM, &p.PatientName, &p.Phone, &p.NoBPJS)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *antrianRepository) CheckNameCaseInsensitive(name string) (*models.Pasien, error) {
	row := r.db.QueryRow(
		`SELECT nik, norm, patientname, phone, "noBPJS"
		 FROM pasien WHERE LOWER(patientname) = LOWER($1)`, name)

	var p models.Pasien
	err := row.Scan(&p.NIK, &p.NoRM, &p.PatientName, &p.Phone, &p.NoBPJS)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}

func (r *antrianRepository) GetLastQueueNumberPoli(poliID int, tanggal time.Time) (int, error) {
	dateStr := tanggal.Format("2006-01-02")
	fmt.Printf("GetLastQueueNumberPoli: Checking count for Poli %d on %s\n", poliID, dateStr)
	
	row := r.db.QueryRow(`
		SELECT COUNT(*)
		FROM antrian
		WHERE poli_id = $1 AND tanggal >= $2::date AND tanggal < ($2::date + interval '1 day')
	`, poliID, dateStr)

	var count int
	err := row.Scan(&count)
	fmt.Printf("GetLastQueueNumberPoli: Found %d records\n", count)
	return count, err
}

func (r *antrianRepository) GetLastQueueNumberGlobal(tanggal time.Time) (int, error) {
	dateStr := tanggal.Format("2006-01-02")
	fmt.Printf("GetLastQueueNumberGlobal: Checking count for Global on %s\n", dateStr)

	row := r.db.QueryRow(`
		SELECT COUNT(*)
		FROM antrian
		WHERE tanggal >= $1::date AND tanggal < ($1::date + interval '1 day')
	`, dateStr)

	var count int
	err := row.Scan(&count)
	fmt.Printf("GetLastQueueNumberGlobal: Found %d records\n", count)
	return count, err
}

func (r *antrianRepository) SaveAntrian(a *models.Antrian) error {
	_, err := r.db.Exec(`
		INSERT INTO antrian
		(no_antrian, no_antrian_poli, kode_booking, nik, nama_pasien, telepon, poli_id, dokter_id,
		 tanggal, waktu_mulai, waktu_selesai, pembayaran, is_pasien_lama, status, source, no_rm, print_count)
		VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,0)
	`,
		a.NoAntrian, a.NoAntrianPoli, a.KodeBooking, a.NIK, a.NamaPasien, a.Telepon,
		a.PoliID, a.DokterID, a.Tanggal, a.WaktuMulai, a.WaktuSelesai,
		a.Pembayaran, a.IsPasienLama, a.Status, a.Source, a.NoRM,
	)
	return err
}

func (r *antrianRepository) DecrementDoctorQuota(doctorID int) error {
	_, err := r.db.Exec(`
		UPDATE category 
		SET "KuotaNonJKN" = "KuotaNonJKN" - 1 
		WHERE id = $1 AND "KuotaNonJKN" > 0
	`, doctorID)
	return err
}

func (r *antrianRepository) GetDoctorNameByID(doctorID int) (string, error) {
	var name string
	err := r.db.QueryRow(`SELECT namadokter FROM category WHERE id = $1`, doctorID).Scan(&name)
	if err != nil {
		if err == sql.ErrNoRows {
			return "-", nil
		}
		return "", err
	}
	return name, nil
}

func GenerateKodeBooking(tanggal time.Time, kodePoli string, urut int) string {
	const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

	kode := strings.ToUpper(kodePoli)
	for len(kode) < 3 {
		kode += "X"
	}
	if len(kode) > 3 {
		kode = kode[:3]
	}

	tanggalPart := tanggal.Format("02")

	r := rand.New(rand.NewSource(tanggal.UnixNano() + int64(urut)))
	randPart := make([]byte, 3)
	for i := range randPart {
		randPart[i] = chars[r.Intn(len(chars))]
	}

	return fmt.Sprintf("%s%s%s", kode, tanggalPart, string(randPart))
}

func (r *antrianRepository) GetDashboardStats() (int, int, int, error) {
	var pasienHariIni, dokterAktif, jumlahPoli int

	_ = r.db.QueryRow(
		`SELECT COUNT(*) FROM antrian WHERE tanggal >= CURRENT_DATE AND tanggal < CURRENT_DATE + INTERVAL '1 day'`,
	).Scan(&pasienHariIni)

	err := r.db.QueryRow(
		`SELECT COUNT(*) FROM category WHERE app = 1`,
	).Scan(&dokterAktif)
	if err != nil {
		return 0, 0, 0, err
	}

	err = r.db.QueryRow(
		`SELECT COUNT(*) FROM tbpoli`,
	).Scan(&jumlahPoli)
	if err != nil {
		return 0, 0, 0, err
	}

	return pasienHariIni, dokterAktif, jumlahPoli, nil
}

func (r *antrianRepository) GetKunjunganStats(period string) ([]models.KunjunganStatPoli, error) {
	var dateFilter string
	var apotekDateFilter string
	switch period {
	case "weekly":
		dateFilter = `a.tanggal >= CURRENT_DATE - INTERVAL '7 days'`
		apotekDateFilter = `createdat >= CURRENT_DATE - INTERVAL '7 days'`
	case "monthly":
		dateFilter = `a.tanggal >= CURRENT_DATE - INTERVAL '30 days'`
		apotekDateFilter = `createdat >= CURRENT_DATE - INTERVAL '30 days'`
	default:
		dateFilter = `a.tanggal >= CURRENT_DATE AND a.tanggal < CURRENT_DATE + INTERVAL '1 day'`
		apotekDateFilter = `createdat >= CURRENT_DATE AND createdat < CURRENT_DATE + INTERVAL '1 day'`
	}

	rows, err := r.db.Query(fmt.Sprintf(`
		SELECT p."IdPoli", p."NamaPoli", COUNT(a.id) AS jumlah
		FROM tbpoli p
		LEFT JOIN antrian a ON a.poli_id = p."IdPoli" AND %s
		GROUP BY p."IdPoli", p."NamaPoli"
		ORDER BY jumlah DESC
	`, dateFilter))
	if err != nil {
		fallbackRows, fbErr := r.db.Query(
			`SELECT "IdPoli", "NamaPoli" FROM tbpoli ORDER BY "NamaPoli"`)
		if fbErr != nil {
			return nil, fbErr
		}
		defer fallbackRows.Close()

		var result []models.KunjunganStatPoli
		for fallbackRows.Next() {
			var s models.KunjunganStatPoli
			if err := fallbackRows.Scan(&s.PolyID, &s.PolyName); err != nil {
				continue
			}
			s.Jumlah = 0
			result = append(result, s)
		}
		return result, nil
	}
	defer rows.Close()

	var result []models.KunjunganStatPoli
	for rows.Next() {
		var s models.KunjunganStatPoli
		if err := rows.Scan(&s.PolyID, &s.PolyName, &s.Jumlah); err != nil {
			continue
		}
		result = append(result, s)
	}

	var apotekCount int
	apotekErr := r.db.QueryRow(fmt.Sprintf(
		`SELECT COUNT(*) FROM Tiket_Apotek WHERE %s`, apotekDateFilter,
	)).Scan(&apotekCount)
	if apotekErr == nil {
		result = append(result, models.KunjunganStatPoli{
			PolyID:   999,
			PolyName: "Apotek",
			Jumlah:   apotekCount,
		})
	}

	return result, nil
}

func (r *antrianRepository) GetTicketByBookingCode(code string) (*models.Antrian, error) {
	var a models.Antrian
	err := r.db.QueryRow(`
		SELECT no_antrian, no_antrian_poli, kode_booking, nik, nama_pasien, telepon, poli_id,
		       dokter_id, tanggal, waktu_mulai, waktu_selesai, pembayaran, is_pasien_lama, status, COALESCE(print_count, 0)
		FROM antrian
		WHERE kode_booking = $1
	`, code).Scan(
		&a.NoAntrian, &a.NoAntrianPoli, &a.KodeBooking, &a.NIK, &a.NamaPasien, &a.Telepon, &a.PoliID,
		&a.DokterID, &a.Tanggal, &a.WaktuMulai, &a.WaktuSelesai, &a.Pembayaran, &a.IsPasienLama, &a.Status, &a.PrintCount,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &a, nil
}

func (r *antrianRepository) CreatePharmacyTicket() (*models.TiketFarmasi, error) {
	var queueNumber int
	var displayQueueNumber int
	var createdAt = time.Now()

	err := r.db.QueryRow(`
		INSERT INTO Tiket_Apotek (createdat) 
		VALUES ($1)
		RETURNING queuenumber, createdat
	`, createdAt).Scan(&queueNumber, &createdAt)

	if err != nil {
		return nil, err
	}

	err = r.db.QueryRow(`
		SELECT COUNT(*) 
		FROM Tiket_Apotek 
		WHERE DATE(createdat) = CURRENT_DATE AND queuenumber <= $1
	`, queueNumber).Scan(&displayQueueNumber)

	if err != nil {
		return nil, err
	}

	return &models.TiketFarmasi{
		QueueNumber: displayQueueNumber,
		CreatedAt:   createdAt,
		NoAntrian:   fmt.Sprintf("APT-%03d", displayQueueNumber),
	}, nil
}

func (r *antrianRepository) GetBpjsReferralByNik(nik string) (*models.BpjsReferral, error) {
	var ref models.BpjsReferral
	err := r.db.QueryRow(`
		SELECT patient_nik, poli_id, doctor_id
		FROM bpjs_referral
		WHERE patient_nik = $1
	`, nik).Scan(&ref.PatientNik, &ref.PoliID, &ref.DoctorID)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &ref, nil
}

func (r *antrianRepository) GetRiwayatByNIK(nik string) ([]models.AntrianResponseExtended, error) {
	query := `
		SELECT a.no_antrian, a.no_antrian_poli, a.kode_booking, p."NamaPoli", COALESCE(c.namadokter, 'dr. -'),
		       a.tanggal, a.waktu_mulai, a.waktu_selesai, a.pembayaran, a.status, COALESCE(a.print_count, 0)
		FROM antrian a
		JOIN tbpoli p ON a.poli_id = p."IdPoli"
		LEFT JOIN category c ON a.dokter_id = c.id
		WHERE a.nik = $1
		ORDER BY a.tanggal DESC, a.waktu_mulai DESC
	`

	rows, err := r.db.Query(query, nik)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.AntrianResponseExtended
	for rows.Next() {
		var a models.AntrianResponseExtended
		err := rows.Scan(
			&a.NoAntrian, &a.NoAntrianPoli, &a.KodeBooking, &a.Poliklinik, &a.Dokter,
			&a.Tanggal, &a.WaktuMulai, &a.WaktuSelesai, &a.Pembayaran, &a.Status, &a.PrintCount,
		)
		if err != nil {
			return nil, err
		}
		results = append(results, a)
	}
	return results, nil
}

func (r *antrianRepository) DeleteAntrian(kodeBooking string) error {
	result, err := r.db.Exec(`
		DELETE FROM antrian
		WHERE kode_booking = $1
	`, kodeBooking)
	if err != nil {
		return err
	}
	rows, _ := result.RowsAffected()
	if rows == 0 {
		return fmt.Errorf("antrian tidak ditemukan")
	}
	return nil
}

func (r *antrianRepository) IncrementPrintCount(kodeBooking string) error {
	_, err := r.db.Exec(`
		UPDATE antrian
		SET print_count = COALESCE(print_count, 0) + 1,
		    status = 'Selesai'
		WHERE kode_booking = $1
	`, kodeBooking)
	return err
}

func (r *antrianRepository) HasActiveAntrianInPoli(nik string, tanggal time.Time, poliID int) (bool, error) {
	dateStr := tanggal.Format("2006-01-02")
	var count int
	err := r.db.QueryRow(`
		SELECT COUNT(*) FROM antrian
		WHERE nik = $1
		  AND tanggal >= $2::date
		  AND tanggal < ($2::date + interval '1 day')
		  AND poli_id = $3
		  AND status != 'dibatalkan'
	`, nik, dateStr, poliID).Scan(&count)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *antrianRepository) GetDoctorStatusOnDate(dokterID int, tanggal string) (string, string, string, error) {
	var status string
	var wMulai, wSelesai sql.NullString
	err := r.db.QueryRow(`SELECT status, waktu_mulai, waktu_selesai FROM status_dokter WHERE dokter_id = $1 AND tanggal = $2::date`, dokterID, tanggal).Scan(&status, &wMulai, &wSelesai)
	if err != nil {
		if err == sql.ErrNoRows {
			return "hadir", "", "", nil
		}
		return "", "", "", err
	}
	return status, wMulai.String, wSelesai.String, nil
}

func (r *antrianRepository) GetRemainingQuotaOnDate(dokterID int, tanggal string) (int, error) {
	var remaining int
	query := `
		SELECT (COALESCE(sk.kuota_custom, c."KuotaNonJKN", 30) - (SELECT COUNT(*) FROM antrian a WHERE a.dokter_id = c.id AND DATE(a.tanggal) = $2::date AND status != 'dibatalkan'))
		FROM category c
		LEFT JOIN status_dokter sk ON sk.dokter_id = c.id AND sk.tanggal = $2::date
		WHERE c.id = $1
	`
	err := r.db.QueryRow(query, dokterID, tanggal).Scan(&remaining)
	if err != nil {
		if err == sql.ErrNoRows {
			return 0, fmt.Errorf("dokter tidak ditemukan")
		}
		return 0, err
	}
	return remaining, nil
}
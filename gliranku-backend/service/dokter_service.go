package service

import (
	"fmt"
	"gliranku/dto/request"
	"gliranku/models"
	"gliranku/repository"
)

type DokterService struct {
	DokterRepo *repository.DokterRepository
}

func NewDokterService(repo *repository.DokterRepository) *DokterService {
	return &DokterService{DokterRepo: repo}
}

func (s *DokterService) Create(req request.DokterRequest) (*models.Dokter, error) {
	d := &models.Dokter{
		DoctorName:       req.DoctorName,
		SpecializationID: req.SpecializationID,
		PolyID:           req.PolyID,
		Phone:            req.Phone,
		Schedule:         req.Schedule,
		MaxKuotaNonJKN:   req.MaxKuotaNonJKN,
		Senin:            req.Senin,
		Selasa:           req.Selasa,
		Rabu:             req.Rabu,
		Kamis:            req.Kamis,
		Jumat:            req.Jumat,
		Sabtu:            req.Sabtu,
		Minggu:           req.Minggu,
	}

	result, err := s.DokterRepo.Create(d)
	if err != nil {
		return nil, fmt.Errorf("gagal menambahkan dokter: %w", err)
	}
	return result, nil
}

func (s *DokterService) Update(id int, req request.DokterRequest) (*models.Dokter, error) {
	existing, err := s.DokterRepo.FindByID(id)
	if err != nil {
		return nil, fmt.Errorf("gagal mencari data dokter: %w", err)
	}
	if existing == nil {
		return nil, fmt.Errorf("dokter dengan ID %d tidak ditemukan", id)
	}

	existing.DoctorName = req.DoctorName
	existing.SpecializationID = req.SpecializationID
	existing.PolyID = req.PolyID
	existing.Phone = req.Phone
	existing.Schedule = req.Schedule
	existing.MaxKuotaNonJKN = req.MaxKuotaNonJKN
	existing.Senin = req.Senin
	existing.Selasa = req.Selasa
	existing.Rabu = req.Rabu
	existing.Kamis = req.Kamis
	existing.Jumat = req.Jumat
	existing.Sabtu = req.Sabtu
	existing.Minggu = req.Minggu

	result, err := s.DokterRepo.Update(existing)
	if err != nil {
		return nil, fmt.Errorf("gagal memperbarui dokter: %w", err)
	}
	return result, nil
}

func (s *DokterService) Delete(id int) error {
	existing, err := s.DokterRepo.FindByID(id)
	if err != nil {
		return fmt.Errorf("gagal mencari data dokter: %w", err)
	}
	if existing == nil {
		return fmt.Errorf("dokter dengan ID %d tidak ditemukan", id)
	}

	used, err := s.DokterRepo.IsUsedInAntrian(id)
	if err != nil {
		return fmt.Errorf("gagal memeriksa data antrian: %w", err)
	}
	if used {
		return fmt.Errorf("dokter tidak dapat dihapus karena masih memiliki data antrian terkait")
	}

	err = s.DokterRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("gagal menghapus dokter: %w", err)
	}
	return nil
}

func (s *DokterService) SaveStatusKhusus(sk *models.DokterStatusKhusus) error {
	if sk.DokterID <= 0 {
		return fmt.Errorf("dokter_id tidak valid")
	}
	if sk.Tanggal == "" {
		return fmt.Errorf("tanggal tidak boleh kosong")
	}
	if sk.Status == "" {
		return fmt.Errorf("status tidak boleh kosong")
	}
	return s.DokterRepo.SaveStatusKhusus(sk)
}

func (s *DokterService) GetStatusKhusus(dokterID int) ([]models.DokterStatusKhusus, error) {
	return s.DokterRepo.GetStatusKhususByDoctor(dokterID)
}

func (s *DokterService) DeleteStatusKhusus(id int) error {
	return s.DokterRepo.DeleteStatusKhusus(id)
}
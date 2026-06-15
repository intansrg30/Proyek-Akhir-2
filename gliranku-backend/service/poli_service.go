package service

import (
	"fmt"
	"gliranku/dto/request"
	"gliranku/models"
	"gliranku/repository"
)

type PoliService struct {
	PoliRepo *repository.PoliRepository
}

func NewPoliService(repo *repository.PoliRepository) *PoliService {
	return &PoliService{PoliRepo: repo}
}

func (s *PoliService) Create(req request.PoliRequest) (*models.Poliklinik, error) {
	poli := &models.Poliklinik{
		PolyName:    req.PolyName,
		KodePoli:    &req.KodePoli,
		Description: &req.Description,
	}

	result, err := s.PoliRepo.Create(poli)
	if err != nil {
		return nil, fmt.Errorf("gagal menambahkan poliklinik: %w", err)
	}
	return result, nil
}

func (s *PoliService) Update(id int, req request.PoliRequest) (*models.Poliklinik, error) {
	existing, err := s.PoliRepo.FindByID(id)
	if err != nil {
		return nil, fmt.Errorf("gagal mencari data poliklinik: %w", err)
	}
	if existing == nil {
		return nil, fmt.Errorf("poliklinik dengan ID %d tidak ditemukan", id)
	}

	existing.PolyName = req.PolyName
	existing.KodePoli = &req.KodePoli
	existing.Description = &req.Description

	result, err := s.PoliRepo.Update(existing)
	if err != nil {
		return nil, fmt.Errorf("gagal memperbarui poliklinik: %w", err)
	}
	return result, nil
}

func (s *PoliService) Delete(id int) error {
	existing, err := s.PoliRepo.FindByID(id)
	if err != nil {
		return fmt.Errorf("gagal mencari data poliklinik: %w", err)
	}
	if existing == nil {
		return fmt.Errorf("poliklinik dengan ID %d tidak ditemukan", id)
	}

	hasDoctors, err := s.PoliRepo.HasDoctors(id)
	if err != nil {
		return fmt.Errorf("gagal memeriksa data dokter: %w", err)
	}
	if hasDoctors {
		return fmt.Errorf("poliklinik tidak dapat dihapus karena masih memiliki dokter terdaftar")
	}

	hasAntrian, err := s.PoliRepo.HasAntrian(id)
	if err != nil {
		return fmt.Errorf("gagal memeriksa data antrian: %w", err)
	}
	if hasAntrian {
		return fmt.Errorf("poliklinik tidak dapat dihapus karena masih memiliki data antrian terkait")
	}

	err = s.PoliRepo.Delete(id)
	if err != nil {
		return fmt.Errorf("gagal menghapus poliklinik: %w", err)
	}
	return nil
}
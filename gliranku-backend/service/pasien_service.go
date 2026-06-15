package service

import (
	"fmt"
	"gliranku/models"
	"gliranku/repository"
	"strings"

	"golang.org/x/crypto/bcrypt"
)

type PasienService struct {
	PasienRepo *repository.PasienRepository
}

func NewPasienService(repo *repository.PasienRepository) *PasienService {
	return &PasienService{PasienRepo: repo}
}

func (s *PasienService) Login(username string, password string) (*models.Pasien, error) {
	username = strings.TrimSpace(username)
	password = strings.TrimSpace(password)

	if username == "" {
		return nil, fmt.Errorf("username tidak boleh kosong")
	}
	if password == "" {
		return nil, fmt.Errorf("password tidak boleh kosong")
	}

	pasien, err := s.PasienRepo.FindByUsername(username)
	if err != nil {
		return nil, fmt.Errorf("gagal mencari data pasien: %w", err)
	}
	if pasien == nil {
		return nil, fmt.Errorf("username atau password salah")
	}

	if pasien.Password == nil || *pasien.Password == "" {
		return nil, fmt.Errorf("akun belum memiliki password, silakan daftar ulang")
	}

	err = bcrypt.CompareHashAndPassword([]byte(*pasien.Password), []byte(password))
	if err != nil {
		return nil, fmt.Errorf("username atau password salah")
	}

	return pasien, nil
}

func (s *PasienService) Register(nik string, patientName string, username string, password string, phone string) (*models.Pasien, error) {
	nik = strings.TrimSpace(nik)
	patientName = strings.TrimSpace(patientName)
	username = strings.TrimSpace(username)
	password = strings.TrimSpace(password)

	if len(nik) != 16 {
		return nil, fmt.Errorf("NIK harus terdiri dari 16 digit")
	}
	if patientName == "" {
		return nil, fmt.Errorf("nama tidak boleh kosong")
	}
	if len(username) < 4 {
		return nil, fmt.Errorf("username minimal 4 karakter")
	}
	if len(password) < 6 {
		return nil, fmt.Errorf("password minimal 6 karakter")
	}

	existingByUsername, err := s.PasienRepo.FindByUsername(username)
	if err != nil {
		return nil, fmt.Errorf("gagal memeriksa ketersediaan username: %w", err)
	}
	if existingByUsername != nil {
		return nil, fmt.Errorf("username sudah digunakan")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("gagal mengenkripsi password: %w", err)
	}
	hashedStr := string(hashedPassword)

	existingByNIK, err := s.PasienRepo.FindByNIK(nik)
	if err != nil {
		return nil, fmt.Errorf("gagal memeriksa NIK: %w", err)
	}

	if existingByNIK != nil {
		if existingByNIK.Username != nil && *existingByNIK.Username != "" {
			return nil, fmt.Errorf("NIK sudah terdaftar dengan username lain")
		}
		err = s.PasienRepo.UpdateAuth(nik, username, hashedStr)
		if err != nil {
			return nil, fmt.Errorf("gagal memperbarui data autentikasi: %w", err)
		}
		updated, err := s.PasienRepo.FindByNIK(nik)
		if err != nil {
			return nil, fmt.Errorf("gagal mengambil data terbaru: %w", err)
		}
		return updated, nil
	}

	phonePtr := &phone
	usernamePtr := &username
	newPasien := &models.Pasien{
		NIK:         nik,
		PatientName: patientName,
		Username:    usernamePtr,
		Password:    &hashedStr,
		Phone:       phonePtr,
	}

	result, err := s.PasienRepo.Register(newPasien)
	if err != nil {
		return nil, fmt.Errorf("gagal mendaftarkan pasien: %w", err)
	}

	return result, nil
}

func (s *PasienService) GetProfile(nik string) (*models.Pasien, error) {
	pasien, err := s.PasienRepo.FindByNIK(nik)
	if err != nil {
		return nil, fmt.Errorf("gagal mengambil profil: %w", err)
	}
	if pasien == nil {
		return nil, fmt.Errorf("pasien dengan NIK %s tidak ditemukan", nik)
	}
	return pasien, nil
}

func (s *PasienService) UpdateProfile(p *models.Pasien) (*models.Pasien, error) {
	existing, err := s.PasienRepo.FindByNIK(p.NIK)
	if err != nil {
		return nil, fmt.Errorf("gagal mencari data pasien: %w", err)
	}
	if existing == nil {
		return nil, fmt.Errorf("pasien dengan NIK %s tidak ditemukan", p.NIK)
	}

	result, err := s.PasienRepo.UpdateProfile(p)
	if err != nil {
		return nil, fmt.Errorf("gagal memperbarui profil: %w", err)
	}
	return result, nil
}
package repository

import (
	"database/sql"
	"gliranku/models"
)

type PasienRepository struct {
	DB *sql.DB
}

func NewPasienRepository(db *sql.DB) *PasienRepository {
	return &PasienRepository{DB: db}
}

func (r *PasienRepository) FindByNIK(nik string) (*models.Pasien, error) {
	query := `
		SELECT nik, norm, patientname, username, password, phone, email,
		       "noBPJS", "golonganDarah", "tanggalLahir", alamat, "jenisKelamin"
		FROM pasien WHERE nik = $1
	`

	var p models.Pasien
	err := r.DB.QueryRow(query, nik).Scan(
		&p.NIK, &p.NoRM, &p.PatientName, &p.Username, &p.Password, &p.Phone, &p.Email,
		&p.NoBPJS, &p.GolonganDarah, &p.TanggalLahir, &p.Alamat, &p.JenisKelamin,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &p, nil
}

func (r *PasienRepository) FindByUsername(username string) (*models.Pasien, error) {
	query := `
		SELECT nik, norm, patientname, username, password, phone, email,
		       "noBPJS", "golonganDarah", "tanggalLahir", alamat, "jenisKelamin"
		FROM pasien WHERE LOWER(username) = LOWER($1)
	`

	var p models.Pasien
	err := r.DB.QueryRow(query, username).Scan(
		&p.NIK, &p.NoRM, &p.PatientName, &p.Username, &p.Password, &p.Phone, &p.Email,
		&p.NoBPJS, &p.GolonganDarah, &p.TanggalLahir, &p.Alamat, &p.JenisKelamin,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &p, nil
}

func (r *PasienRepository) Register(p *models.Pasien) (*models.Pasien, error) {
	query := `
		INSERT INTO pasien (nik, patientname, username, password, phone)
		VALUES ($1, $2, $3, $4, $5)
		RETURNING nik, norm, patientname, username, phone, email,
		          "noBPJS", "golonganDarah", "tanggalLahir", alamat, "jenisKelamin"
	`

	var result models.Pasien
	err := r.DB.QueryRow(query, p.NIK, p.PatientName, p.Username, p.Password, p.Phone).Scan(
		&result.NIK, &result.NoRM, &result.PatientName, &result.Username, &result.Phone, &result.Email,
		&result.NoBPJS, &result.GolonganDarah, &result.TanggalLahir, &result.Alamat, &result.JenisKelamin,
	)
	if err != nil {
		return nil, err
	}
	return &result, nil
}

func (r *PasienRepository) UpdateAuth(nik string, username string, passwordHash string) error {
	query := `UPDATE pasien SET username = $2, password = $3 WHERE nik = $1`
	_, err := r.DB.Exec(query, nik, username, passwordHash)
	return err
}

func (r *PasienRepository) UpdateProfile(p *models.Pasien) (*models.Pasien, error) {
	query := `
		UPDATE pasien SET
			patientname = COALESCE($2, patientname),
			phone = COALESCE($3, phone),
			email = COALESCE($4, email),
			"noBPJS" = COALESCE($5, "noBPJS"),
			"golonganDarah" = COALESCE($6, "golonganDarah"),
			"tanggalLahir" = COALESCE($7::date, "tanggalLahir"),
			alamat = COALESCE($8, alamat),
			"jenisKelamin" = COALESCE($9, "jenisKelamin")
		WHERE nik = $1
		RETURNING nik, norm, patientname, username, phone, email,
		          "noBPJS", "golonganDarah", "tanggalLahir", alamat, "jenisKelamin"
	`

	var result models.Pasien
	err := r.DB.QueryRow(query,
		p.NIK, &p.PatientName, p.Phone, p.Email,
		p.NoBPJS, p.GolonganDarah, p.TanggalLahir, p.Alamat, p.JenisKelamin,
	).Scan(
		&result.NIK, &result.NoRM, &result.PatientName, &result.Username, &result.Phone, &result.Email,
		&result.NoBPJS, &result.GolonganDarah, &result.TanggalLahir, &result.Alamat, &result.JenisKelamin,
	)
	if err != nil {
		return nil, err
	}
	return &result, nil
}

func (r *PasienRepository) FindByNameCaseInsensitive(name string) (*models.Pasien, error) {
	query := `
		SELECT nik, norm, patientname, username, password, phone, email,
		       "noBPJS", "golonganDarah", "tanggalLahir", alamat, "jenisKelamin"
		FROM pasien WHERE LOWER(patientname) = LOWER($1)
	`

	var p models.Pasien
	err := r.DB.QueryRow(query, name).Scan(
		&p.NIK, &p.NoRM, &p.PatientName, &p.Username, &p.Password, &p.Phone, &p.Email,
		&p.NoBPJS, &p.GolonganDarah, &p.TanggalLahir, &p.Alamat, &p.JenisKelamin,
	)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return &p, nil
}
package repository

import (
	"database/sql"
	"gliranku/models"
)

type DokterRepository struct {
	DB *sql.DB
}

func NewDokterRepository(db *sql.DB) *DokterRepository {
	return &DokterRepository{DB: db}
}

func (r *DokterRepository) FindByPolyID(polyID int, tanggal string) ([]models.Dokter, error) {
	query := `
		SELECT c.id as category_id, c.namadokter, c."IdPoli", p."NamaPoli", d."NoTelp", d."Spesialisasi", s.nama, c.options as schedule,
		       COALESCE(c.senin,''), COALESCE(c.selasa,''), COALESCE(c.rabu,''),
		       COALESCE(c.kamis,''), COALESCE(c.jumat,''), COALESCE(c.sabtu,''), COALESCE(c.minggu,''),
		       (COALESCE(sk.kuota_custom, c."KuotaNonJKN", 30) - (SELECT COUNT(*) FROM antrian a WHERE a.dokter_id = c.id AND DATE(a.tanggal) = $2::date AND status != 'dibatalkan')), COALESCE(sk.kuota_custom, c."KuotaNonJKN", 30),
		       COALESCE(sk.status, 'hadir'), COALESCE(sk.keterangan, '')
		FROM category c
		JOIN tbpoli p ON c."IdPoli" = p."IdPoli"
		LEFT JOIN tbdaftardokter d ON c."IdDokter" = d."IdDokter"
		LEFT JOIN tbspesialis s ON d."Spesialisasi" = s.id
		LEFT JOIN status_dokter sk ON sk.dokter_id = c.id AND sk.tanggal = $2::date
		WHERE c."IdPoli" = $1 AND c.app = 1
		ORDER BY c.namadokter ASC
	`

	rows, err := r.DB.Query(query, polyID, tanggal)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.Dokter
	for rows.Next() {
		var d models.Dokter
		var spesialisasi sql.NullInt64
		var telp sql.NullString
		var schedule sql.NullString

		var spesialisasiNama sql.NullString

		err := rows.Scan(&d.DoctorID, &d.DoctorName, &d.PolyID, &d.PolyName, &telp, &spesialisasi, &spesialisasiNama, &schedule,
			&d.Senin, &d.Selasa, &d.Rabu, &d.Kamis, &d.Jumat, &d.Sabtu, &d.Minggu, &d.KuotaNonJKN, &d.MaxKuotaNonJKN,
			&d.StatusInfo, &d.StatusKeterangan)
		if err != nil {
			return nil, err
		}
		if telp.Valid {
			d.Phone = telp.String
		}
		if schedule.Valid {
			d.Schedule = schedule.String
		}
		if spesialisasi.Valid {
			d.SpecializationID = int(spesialisasi.Int64)
		}
		if spesialisasiNama.Valid {
			d.Specialization = spesialisasiNama.String
		}
		d.Status = true
		results = append(results, d)
	}
	return results, nil
}

func (r *DokterRepository) FindAll(tanggal string) ([]models.Dokter, error) {
	query := `
		SELECT c.id as category_id, c.namadokter, c."IdPoli", p."NamaPoli", d."NoTelp", d."Spesialisasi", s.nama, c.options as schedule,
		       COALESCE(c.senin,''), COALESCE(c.selasa,''), COALESCE(c.rabu,''),
		       COALESCE(c.kamis,''), COALESCE(c.jumat,''), COALESCE(c.sabtu,''), COALESCE(c.minggu,''),
		       (COALESCE(sk.kuota_custom, c."KuotaNonJKN", 30) - (SELECT COUNT(*) FROM antrian a WHERE a.dokter_id = c.id AND DATE(a.tanggal) = $1::date AND status != 'dibatalkan')), COALESCE(sk.kuota_custom, c."KuotaNonJKN", 30),
		       COALESCE(sk.status, 'hadir'), COALESCE(sk.keterangan, '')
		FROM category c
		JOIN tbpoli p ON c."IdPoli" = p."IdPoli"
		LEFT JOIN tbdaftardokter d ON c."IdDokter" = d."IdDokter"
		LEFT JOIN tbspesialis s ON d."Spesialisasi" = s.id
		LEFT JOIN status_dokter sk ON sk.dokter_id = c.id AND sk.tanggal = $1::date
		WHERE c.app = 1
		ORDER BY c.namadokter ASC
	`

	rows, err := r.DB.Query(query, tanggal)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.Dokter
	for rows.Next() {
		var d models.Dokter
		var spesialisasi sql.NullInt64
		var telp sql.NullString
		var schedule sql.NullString

		var spesialisasiNama sql.NullString

		err := rows.Scan(&d.DoctorID, &d.DoctorName, &d.PolyID, &d.PolyName, &telp, &spesialisasi, &spesialisasiNama, &schedule,
			&d.Senin, &d.Selasa, &d.Rabu, &d.Kamis, &d.Jumat, &d.Sabtu, &d.Minggu, &d.KuotaNonJKN, &d.MaxKuotaNonJKN,
			&d.StatusInfo, &d.StatusKeterangan)
		if err != nil {
			return nil, err
		}
		if telp.Valid {
			d.Phone = telp.String
		}
		if schedule.Valid {
			d.Schedule = schedule.String
		}
		if spesialisasi.Valid {
			d.SpecializationID = int(spesialisasi.Int64)
		}
		if spesialisasiNama.Valid {
			d.Specialization = spesialisasiNama.String
		}
		d.Status = true
		results = append(results, d)
	}
	return results, nil
}

func (r *DokterRepository) FindByID(id int) (*models.Dokter, error) {
	query := `
		SELECT c.id as category_id, c.namadokter, c."IdPoli", p."NamaPoli", d."NoTelp", d."Spesialisasi", s.nama, c.options as schedule,
		       COALESCE(c.senin,''), COALESCE(c.selasa,''), COALESCE(c.rabu,''),
		       COALESCE(c.kamis,''), COALESCE(c.jumat,''), COALESCE(c.sabtu,''), COALESCE(c.minggu,''),
		       COALESCE(c."KuotaNonJKN", 0), COALESCE(c."KuotaNonJKN", 30)
		FROM category c
		JOIN tbpoli p ON c."IdPoli" = p."IdPoli"
		LEFT JOIN tbdaftardokter d ON c."IdDokter" = d."IdDokter"
		LEFT JOIN tbspesialis s ON d."Spesialisasi" = s.id
		WHERE c.id = $1 AND c.app = 1
	`

	var d models.Dokter
	var spesialisasi sql.NullInt64
	var telp sql.NullString
	var schedule sql.NullString

	var spesialisasiNama sql.NullString

	err := r.DB.QueryRow(query, id).Scan(&d.DoctorID, &d.DoctorName, &d.PolyID, &d.PolyName, &telp, &spesialisasi, &spesialisasiNama, &schedule,
		&d.Senin, &d.Selasa, &d.Rabu, &d.Kamis, &d.Jumat, &d.Sabtu, &d.Minggu, &d.KuotaNonJKN, &d.MaxKuotaNonJKN)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	if telp.Valid {
		d.Phone = telp.String
	}
	if schedule.Valid {
		d.Schedule = schedule.String
	}
	if spesialisasi.Valid {
		d.SpecializationID = int(spesialisasi.Int64)
	}
	if spesialisasiNama.Valid {
		d.Specialization = spesialisasiNama.String
	}
	d.Status = true
	return &d, nil
}

func (r *DokterRepository) Create(d *models.Dokter) (*models.Dokter, error) {
	tx, err := r.DB.Begin()
	if err != nil {
		return nil, err
	}

	queryDokter := `
		INSERT INTO tbdaftardokter ("NamaDokter", "NoTelp", "Spesialisasi", "Kategori", "Status", "Gambar", "TandaTangan", "IdBPJS")
		VALUES ($1, $2, $3, 0, 'aktif', '', '', '')
		RETURNING "IdDokter"
	`
	var realDokterID int
	err = tx.QueryRow(queryDokter, d.DoctorName, d.Phone, d.SpecializationID).Scan(&realDokterID)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	var polyName string
	err = tx.QueryRow(`SELECT "NamaPoli" FROM tbpoli WHERE "IdPoli" = $1`, d.PolyID).Scan(&polyName)
	if err != nil {
		tx.Rollback()
		return nil, err
	}
	d.PolyName = polyName

	queryCategory := `
		INSERT INTO category (name, namadokter, "IdDokter", "IdPoli", app, options, voice_call, "KuotaNonJKN", senin, selasa, rabu, kamis, jumat, sabtu, minggu)
		VALUES ($1, $2, $3, $4, 1, $5, '', $6, $7, $8, $9, $10, $11, $12, $13)
		RETURNING id
	`
	err = tx.QueryRow(queryCategory, polyName, d.DoctorName, realDokterID, d.PolyID, d.Schedule,
		d.MaxKuotaNonJKN, d.Senin, d.Selasa, d.Rabu, d.Kamis, d.Jumat, d.Sabtu, d.Minggu).Scan(&d.DoctorID)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	err = tx.Commit()
	if err != nil {
		return nil, err
	}
	d.Status = true
	return d, nil
}

func (r *DokterRepository) Update(d *models.Dokter) (*models.Dokter, error) {
	tx, err := r.DB.Begin()
	if err != nil {
		return nil, err
	}

	queryCategory := `
		UPDATE category
		SET namadokter = $1, "IdPoli" = $2, options = $3, "KuotaNonJKN" = $4,
		    senin = $5, selasa = $6, rabu = $7, kamis = $8, jumat = $9, sabtu = $10, minggu = $11
		WHERE id = $12
		RETURNING "IdDokter"
	`
	var realDokterID int
	err = tx.QueryRow(queryCategory, d.DoctorName, d.PolyID, d.Schedule,
		d.MaxKuotaNonJKN, d.Senin, d.Selasa, d.Rabu, d.Kamis, d.Jumat, d.Sabtu, d.Minggu, d.DoctorID).Scan(&realDokterID)
	if err != nil {
		tx.Rollback()
		return nil, err
	}

	if realDokterID > 0 {
		queryDokter := `UPDATE tbdaftardokter SET "NamaDokter" = $1, "NoTelp" = $2, "Spesialisasi" = $3 WHERE "IdDokter" = $4`
		_, err = tx.Exec(queryDokter, d.DoctorName, d.Phone, d.SpecializationID, realDokterID)
		if err != nil {
			tx.Rollback()
			return nil, err
		}
	}

	err = tx.Commit()
	if err != nil {
		return nil, err
	}
	return d, nil
}

func (r *DokterRepository) Delete(id int) error {
	query := `DELETE FROM category WHERE id = $1`
	_, err := r.DB.Exec(query, id)
	return err
}

func (r *DokterRepository) IsUsedInAntrian(id int) (bool, error) {
	var count int
	err := r.DB.QueryRow(`SELECT COUNT(*) FROM antrian WHERE dokter_id = $1`, id).Scan(&count)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *DokterRepository) SaveStatusKhusus(sk *models.DokterStatusKhusus) error {
	query := `
		INSERT INTO status_dokter (dokter_id, tanggal, status, keterangan, kuota_custom)
		VALUES ($1, $2, $3, $4, $5)
		ON CONFLICT (dokter_id, tanggal) DO UPDATE SET status = $3, keterangan = $4, kuota_custom = $5
		RETURNING id
	`
	return r.DB.QueryRow(query, sk.DokterID, sk.Tanggal, sk.Status, sk.Keterangan, sk.KuotaCustom).Scan(&sk.ID)
}

func (r *DokterRepository) GetStatusKhususByDoctor(dokterID int) ([]models.DokterStatusKhusus, error) {
	query := `
		SELECT id, dokter_id, tanggal, status, COALESCE(keterangan, ''), kuota_custom
		FROM status_dokter
		WHERE dokter_id = $1
		ORDER BY tanggal ASC
	`
	rows, err := r.DB.Query(query, dokterID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.DokterStatusKhusus
	for rows.Next() {
		var sk models.DokterStatusKhusus
		if err := rows.Scan(&sk.ID, &sk.DokterID, &sk.Tanggal, &sk.Status, &sk.Keterangan, &sk.KuotaCustom); err != nil {
			return nil, err
		}
		results = append(results, sk)
	}
	return results, nil
}

func (r *DokterRepository) DeleteStatusKhusus(id int) error {
	_, err := r.DB.Exec(`DELETE FROM status_dokter WHERE id = $1`, id)
	return err
}

func (r *DokterRepository) GetDoctorStatusOnDate(dokterID int, tanggal string) (string, error) {
	var status string
	err := r.DB.QueryRow(`SELECT status FROM status_dokter WHERE dokter_id = $1 AND tanggal = $2::date`, dokterID, tanggal).Scan(&status)
	if err != nil {
		if err == sql.ErrNoRows {
			return "hadir", nil
		}
		return "", err
	}
	return status, nil
}
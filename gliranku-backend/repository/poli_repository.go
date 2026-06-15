package repository

import (
	"database/sql"
	"gliranku/models"
)

type PoliRepository struct {
	DB *sql.DB
}

func NewPoliRepository(db *sql.DB) *PoliRepository {
	return &PoliRepository{DB: db}
}

func (r *PoliRepository) FindAll() ([]models.Poliklinik, error) {
	query := `
		SELECT "IdPoli", "NamaPoli", "KodePoli"
		FROM tbpoli
		ORDER BY "NamaPoli" ASC
	`

	rows, err := r.DB.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var results []models.Poliklinik
	for rows.Next() {
		var p models.Poliklinik
		err := rows.Scan(&p.PolyID, &p.PolyName, &p.KodePoli)
		if err != nil {
			return nil, err
		}
		p.IsActive = true
		results = append(results, p)
	}
	return results, nil
}

func (r *PoliRepository) FindByID(id int) (*models.Poliklinik, error) {
	query := `SELECT "IdPoli", "NamaPoli", "KodePoli" FROM tbpoli WHERE "IdPoli" = $1`

	var p models.Poliklinik
	err := r.DB.QueryRow(query, id).Scan(&p.PolyID, &p.PolyName, &p.KodePoli)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	p.IsActive = true
	return &p, nil
}

func (r *PoliRepository) Create(p *models.Poliklinik) (*models.Poliklinik, error) {
	query := `
		INSERT INTO tbpoli ("NamaPoli", "KodePoli", "TipePoli", "Spesialis", "KodeSatuSehat")
		VALUES ($1, $2, 0, '[]', NULL)
		RETURNING "IdPoli"
	`
	err := r.DB.QueryRow(query, p.PolyName, p.KodePoli).Scan(&p.PolyID)
	if err != nil {
		return nil, err
	}
	p.IsActive = true
	return p, nil
}

func (r *PoliRepository) Update(p *models.Poliklinik) (*models.Poliklinik, error) {
	query := `
		UPDATE tbpoli
		SET "NamaPoli" = $1, "KodePoli" = $2
		WHERE "IdPoli" = $3
	`
	_, err := r.DB.Exec(query, p.PolyName, p.KodePoli, p.PolyID)
	if err != nil {
		return nil, err
	}
	return p, nil
}

func (r *PoliRepository) Delete(id int) error {
	query := `DELETE FROM tbpoli WHERE "IdPoli" = $1`
	_, err := r.DB.Exec(query, id)
	return err
}

func (r *PoliRepository) HasDoctors(id int) (bool, error) {
	var count int
	err := r.DB.QueryRow(`SELECT COUNT(*) FROM category WHERE "IdPoli" = $1 AND app = 1`, id).Scan(&count)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (r *PoliRepository) HasAntrian(id int) (bool, error) {
	var count int
	err := r.DB.QueryRow(`SELECT COUNT(*) FROM antrian WHERE poli_id = $1`, id).Scan(&count)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}
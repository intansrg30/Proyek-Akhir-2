package models

type Dokter struct {
	DoctorID       int    `json:"doctor_id"`
	DoctorName       string `json:"doctor_name"`
	SpecializationID int    `json:"specialization_id"`
	Specialization   string `json:"specialization"`
	PolyID         int    `json:"poly_id"`
	PolyName       string `json:"poly_name,omitempty"`
	Phone          string `json:"phone,omitempty"`
	Status         bool   `json:"status"`
	Schedule       string `json:"schedule,omitempty"`
	KuotaNonJKN    int    `json:"kuota_non_jkn"`
	MaxKuotaNonJKN int    `json:"max_kuota_non_jkn,omitempty"`
	Senin   string `json:"senin,omitempty"`
	Selasa  string `json:"selasa,omitempty"`
	Rabu    string `json:"rabu,omitempty"`
	Kamis   string `json:"kamis,omitempty"`
	Jumat   string `json:"jumat,omitempty"`
	Sabtu   string `json:"sabtu,omitempty"`
	Minggu  string `json:"minggu,omitempty"`
	StatusInfo       string `json:"status_info,omitempty"`
	StatusKeterangan string `json:"status_keterangan,omitempty"`
}
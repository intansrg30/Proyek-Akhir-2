package models

type DokterStatusKhusus struct {
	ID          int    `json:"id"`
	DokterID    int    `json:"dokter_id"`
	Tanggal     string `json:"tanggal"`
	Status      string `json:"status"`
	Keterangan  string `json:"keterangan"`
	KuotaCustom *int   `json:"kuota_custom,omitempty"`
}
package models

type Pasien struct {
	NIK           string  `json:"nik"`
	NoRM          *string `json:"no_rm,omitempty"`
	PatientName   string  `json:"patient_name"`
	Username      *string `json:"username,omitempty"`
	Password      *string `json:"-"`
	Phone         *string `json:"phone,omitempty"`
	Email         *string `json:"email,omitempty"`
	NoBPJS        *string `json:"no_bpjs,omitempty"`
	GolonganDarah *string `json:"golongan_darah,omitempty"`
	TanggalLahir  *string `json:"tanggal_lahir,omitempty"`
	Alamat        *string `json:"alamat,omitempty"`
	JenisKelamin  *string `json:"jenis_kelamin,omitempty"`
}
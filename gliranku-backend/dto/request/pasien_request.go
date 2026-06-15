package request

type LoginPasienRequest struct {
	Username string `json:"username" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type RegisterPasienRequest struct {
	NIK         string `json:"nik" binding:"required"`
	PatientName string `json:"patient_name" binding:"required"`
	Username    string `json:"username" binding:"required"`
	Password    string `json:"password" binding:"required"`
	Phone       string `json:"phone"`
}

type UpdatePasienProfileRequest struct {
	NIK           string  `json:"nik" binding:"required"`
	PatientName   string  `json:"patient_name"`
	Phone         *string `json:"phone"`
	Email         *string `json:"email"`
	NoBPJS        *string `json:"no_bpjs"`
	GolonganDarah *string `json:"golongan_darah"`
	TanggalLahir  *string `json:"tanggal_lahir"`
	Alamat        *string `json:"alamat"`
	JenisKelamin  *string `json:"jenis_kelamin"`
}
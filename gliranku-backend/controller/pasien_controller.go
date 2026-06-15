package controller

import (
	"gliranku/dto/request"
	"gliranku/models"
	"gliranku/service"
	"gliranku/utils"
	"net/http"

	"github.com/gin-gonic/gin"
)

type PasienController struct {
	Service *service.PasienService
}

func NewPasienController(s *service.PasienService) *PasienController {
	return &PasienController{Service: s}
}

func (ctrl *PasienController) Login(c *gin.Context) {
	var req request.LoginPasienRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationError(c, "Data tidak valid", err.Error())
		return
	}

	result, err := ctrl.Service.Login(req.Username, req.Password)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	token, err := utils.GenerateToken(result.NIK)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "Gagal membuat sesi login: "+err.Error())
		return
	}

	response := gin.H{
		"patient": result,
		"token":   token,
	}

	utils.Success(c, http.StatusOK, "Login berhasil", response)
}

func (ctrl *PasienController) Register(c *gin.Context) {
	var req request.RegisterPasienRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationError(c, "Data tidak valid", err.Error())
		return
	}

	result, err := ctrl.Service.Register(req.NIK, req.PatientName, req.Username, req.Password, req.Phone)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	token, err := utils.GenerateToken(result.NIK)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "Gagal membuat sesi: "+err.Error())
		return
	}

	response := gin.H{
		"patient": result,
		"token":   token,
	}

	utils.Success(c, http.StatusCreated, "Registrasi berhasil", response)
}

func (ctrl *PasienController) GetProfile(c *gin.Context) {
	nik := c.Param("nik")

	result, err := ctrl.Service.GetProfile(nik)
	if err != nil {
		utils.Error(c, http.StatusNotFound, err.Error())
		return
	}

	utils.Success(c, http.StatusOK, "Profil pasien berhasil diambil", result)
}

func (ctrl *PasienController) UpdateProfile(c *gin.Context) {
	var req request.UpdatePasienProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationError(c, "Data tidak valid", err.Error())
		return
	}

	tokenNIK, exists := c.Get("nik")
	if exists && tokenNIK.(string) != req.NIK {
		utils.Error(c, http.StatusForbidden, "Forbidden: Anda tidak diizinkan mengubah data pasien lain (IDOR Protection Active)")
		return
	}

	pasien := &models.Pasien{
		NIK:           req.NIK,
		PatientName:   req.PatientName,
		Phone:         req.Phone,
		Email:         req.Email,
		NoBPJS:        req.NoBPJS,
		GolonganDarah: req.GolonganDarah,
		TanggalLahir:  req.TanggalLahir,
		Alamat:        req.Alamat,
		JenisKelamin:  req.JenisKelamin,
	}

	result, err := ctrl.Service.UpdateProfile(pasien)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	utils.Success(c, http.StatusOK, "Profil berhasil diperbarui", result)
}
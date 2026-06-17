package controller

import (
	"net/http"

	"gliranku/dto/request"
	"gliranku/service"

	"github.com/gin-gonic/gin"
	"github.com/go-playground/validator/v10"
)

type AntrianController struct {
	service  service.AntrianService
	validate *validator.Validate
}

func NewAntrianController(svc service.AntrianService) *AntrianController {
	return &AntrianController{
		service:  svc,
		validate: validator.New(),
	}
}

func (c *AntrianController) GetLayanan(ctx *gin.Context) {
	tanggal := ctx.Query("tanggal")

	var data interface{}
	var err error

	if tanggal != "" {
		data, err = c.service.GetAvailablePoliklinik(tanggal)
	} else {
		data, err = c.service.GetPoliklinik()
	}

	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Gagal memuat layanan",
		})
		return
	}
	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    data,
	})
}

func (c *AntrianController) CekNIK(ctx *gin.Context) {
	var req request.CekNIKRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Format request tidak valid",
		})
		return
	}

	result, err := c.service.VerifyNIK(req.NIK)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": "Gagal verifikasi NIK",
		})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    result,
	})
}

func (c *AntrianController) CreateAntrian(ctx *gin.Context) {
	var req request.AntrianRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Format request tidak valid",
		})
		return
	}

	if err := c.validate.Struct(req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Validasi gagal: " + err.Error(),
		})
		return
	}

	result, err := c.service.CreateAntrian(req)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Antrian berhasil dibuat",
		"data":    result,
	})
}

func (c *AntrianController) CreateBpjsAntrian(ctx *gin.Context) {
	var req request.BpjsAntrianRequest
	if err := ctx.ShouldBindJSON(&req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Format request tidak valid",
		})
		return
	}

	if err := c.validate.Struct(req); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{
			"success": false,
			"message": "Validasi gagal: " + err.Error(),
		})
		return
	}

	result, err := c.service.CreateBpjsAntrian(req)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{
			"success": false,
			"message": err.Error(),
		})
		return
	}

	ctx.JSON(http.StatusCreated, gin.H{
		"success": true,
		"message": "Antrian BPJS berhasil dibuat",
		"data":    result,
	})
}

func (c *AntrianController) GetDashboardStats(ctx *gin.Context) {
	pasienHariIni, dokterAktif, jumlahPoli, err := c.service.GetDashboardStats()
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal memuat statistik"})
		return
	}
	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"data": gin.H{
			"pasien_hari_ini":   pasienHariIni,
			"dokter_aktif":      dokterAktif,
			"jumlah_poliklinik": jumlahPoli,
		},
	})
}

func (c *AntrianController) GetKunjunganStats(ctx *gin.Context) {
	period := ctx.DefaultQuery("period", "daily")
	data, err := c.service.GetKunjunganStats(period)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal memuat statistik kunjungan"})
		return
	}
	ctx.JSON(http.StatusOK, gin.H{"success": true, "data": data})
}

func (c *AntrianController) GetRiwayat(ctx *gin.Context) {
	nik := ctx.Param("nik")
	if nik == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "NIK harus diisi"})
		return
	}

	result, err := c.service.GetRiwayatAntrian(nik)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal memuat riwayat antrian"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    result,
	})
}

func (c *AntrianController) DeleteAntrian(ctx *gin.Context) {
	kodeBooking := ctx.Param("kode_booking")
	if kodeBooking == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "Kode booking harus diisi"})
		return
	}

	if err := c.service.DeleteAntrian(kodeBooking); err != nil {
		ctx.JSON(http.StatusBadRequest, gin.H{"success": false, "message": err.Error()})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{"success": true, "message": "Riwayat antrian berhasil dihapus"})
}

func (c *AntrianController) GetRujukanBPJS(ctx *gin.Context) {
	nik := ctx.Param("nik")
	if nik == "" {
		ctx.JSON(http.StatusBadRequest, gin.H{"success": false, "message": "NIK harus diisi"})
		return
	}

	result, err := c.service.GetRujukanBPJS(nik)
	if err != nil {
		ctx.JSON(http.StatusInternalServerError, gin.H{"success": false, "message": "Gagal memuat rujukan BPJS"})
		return
	}

	ctx.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    result,
	})
}
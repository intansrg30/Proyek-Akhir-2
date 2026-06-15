package controller

import (
	"gliranku/dto/request"
	"gliranku/models"
	"gliranku/repository"
	"gliranku/service"
	"gliranku/utils"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

type DokterController struct {
	Repo    *repository.DokterRepository
	Service *service.DokterService
}

func NewDokterController(repo *repository.DokterRepository, svc *service.DokterService) *DokterController {
	return &DokterController{Repo: repo, Service: svc}
}

func (ctrl *DokterController) GetByPoly(c *gin.Context) {
	tanggal := c.Query("tanggal")
	if tanggal == "" {
		tanggal = time.Now().Format("2006-01-02")
	}

	polyIDStr := c.Query("poly_id")
	if polyIDStr == "" {
		polyIDStr = c.Param("poly_id")
	}
	if polyIDStr == "" {
		results, err := ctrl.Repo.FindAll(tanggal)
		if err != nil {
			utils.Error(c, http.StatusInternalServerError, "Gagal mengambil data dokter")
			return
		}
		utils.Success(c, http.StatusOK, "Data dokter berhasil diambil", results)
		return
	}

	polyID, err := strconv.Atoi(polyIDStr)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, "Parameter poly_id harus berupa angka")
		return
	}

	results, err := ctrl.Repo.FindByPolyID(polyID, tanggal)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "Gagal mengambil data dokter")
		return
	}
	utils.Success(c, http.StatusOK, "Data dokter berhasil diambil", results)
}

func (ctrl *DokterController) Create(c *gin.Context) {
	var req request.DokterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationError(c, "Data tidak valid", err.Error())
		return
	}

	result, err := ctrl.Service.Create(req)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	utils.Success(c, http.StatusCreated, "Dokter berhasil ditambahkan", result)
}

func (ctrl *DokterController) Update(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.Error(c, http.StatusBadRequest, "ID tidak valid")
		return
	}

	var req request.DokterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationError(c, "Data tidak valid", err.Error())
		return
	}

	result, err := ctrl.Service.Update(id, req)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	utils.Success(c, http.StatusOK, "Dokter berhasil diperbarui", result)
}

func (ctrl *DokterController) Delete(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.Error(c, http.StatusBadRequest, "ID tidak valid")
		return
	}

	err = ctrl.Service.Delete(id)
	if err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	utils.Success(c, http.StatusOK, "Dokter berhasil dihapus", nil)
}

type statusKhususRequest struct {
	DokterID    int    `json:"dokter_id" binding:"required"`
	Tanggal     string `json:"tanggal" binding:"required"`
	Status      string `json:"status" binding:"required"`
	Keterangan  string `json:"keterangan"`
	KuotaCustom *int   `json:"kuota_custom"`
}

func (ctrl *DokterController) SetStatusKhusus(c *gin.Context) {
	var req statusKhususRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.ValidationError(c, "Data tidak valid", err.Error())
		return
	}

	sk := &models.DokterStatusKhusus{
		DokterID:    req.DokterID,
		Tanggal:     req.Tanggal,
		Status:      req.Status,
		Keterangan:  req.Keterangan,
		KuotaCustom: req.KuotaCustom,
	}

	if err := ctrl.Service.SaveStatusKhusus(sk); err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	utils.Success(c, http.StatusOK, "Status kehadiran berhasil disimpan", sk)
}

func (ctrl *DokterController) GetStatusKhusus(c *gin.Context) {
	dokterID, err := strconv.Atoi(c.Param("dokter_id"))
	if err != nil {
		utils.Error(c, http.StatusBadRequest, "ID dokter tidak valid")
		return
	}

	results, err := ctrl.Service.GetStatusKhusus(dokterID)
	if err != nil {
		utils.Error(c, http.StatusInternalServerError, "Gagal mengambil status kehadiran")
		return
	}
	utils.Success(c, http.StatusOK, "Data status kehadiran berhasil diambil", results)
}

func (ctrl *DokterController) DeleteStatusKhusus(c *gin.Context) {
	id, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		utils.Error(c, http.StatusBadRequest, "ID tidak valid")
		return
	}

	if err := ctrl.Service.DeleteStatusKhusus(id); err != nil {
		utils.Error(c, http.StatusBadRequest, err.Error())
		return
	}
	utils.Success(c, http.StatusOK, "Status kehadiran berhasil dihapus", nil)
}

package routes

import (
	"gliranku/controller"
	"gliranku/middleware"

	"github.com/gin-gonic/gin"
)

func SetupPasienRoutes(r *gin.Engine, pasienCtrl *controller.PasienController, notifikasiCtrl *controller.NotifikasiController, kontrolRutinCtrl *controller.KontrolRutinController) {
	r.Use(middleware.SecurityHeaders())
	r.Use(middleware.CORS())
	r.Use(middleware.RequestSizeLimit(4 * 1024 * 1024))
	r.Use(middleware.RateLimit())

	api := r.Group("/api/v1")

	pasien := api.Group("/pasien")
	{
		pasien.POST("/login", middleware.StrictRateLimit(), pasienCtrl.Login)
		pasien.POST("/register", middleware.StrictRateLimit(), pasienCtrl.Register)
		pasien.GET("/profile/:nik", middleware.RequireAuth(), middleware.RequirePatientOwnership(), pasienCtrl.GetProfile)
		pasien.PUT("/profile", middleware.RequireAuth(), pasienCtrl.UpdateProfile)
	}

	notifikasi := api.Group("/notifikasi")
	{
		notifikasi.POST("", notifikasiCtrl.Create)
		notifikasi.GET("/pasien/:nik", middleware.RequireAuth(), middleware.RequirePatientOwnership(), notifikasiCtrl.GetByNIK)
		notifikasi.GET("/pending", notifikasiCtrl.GetPending)
		notifikasi.PUT("/:id/mark-sent", notifikasiCtrl.MarkAsSent)
		notifikasi.POST("/process", notifikasiCtrl.ProcessPending)
		notifikasi.DELETE("/:id", notifikasiCtrl.Delete)
	}

	kontrolRutin := api.Group("/kontrol-rutin")
	{
		kontrolRutin.POST("", kontrolRutinCtrl.Create)
		kontrolRutin.GET("/all", kontrolRutinCtrl.GetAll)
		kontrolRutin.GET("/pasien/:nik", middleware.RequireAuth(), middleware.RequirePatientOwnership(), kontrolRutinCtrl.GetByNIK)
		kontrolRutin.GET("/upcoming", kontrolRutinCtrl.GetUpcoming)
		kontrolRutin.DELETE("/:id", kontrolRutinCtrl.Delete)
	}
}
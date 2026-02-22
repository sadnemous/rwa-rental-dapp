package main

import (
	"rwa/db"
	"rwa/eth"
	"rwa/handlers"

	"github.com/gin-gonic/gin"
)

func main() {

	database := db.InitDB()
	eth.Init()

	r := gin.Default()
	r.LoadHTMLGlob("web/templates/*")

	// Routes
	r.GET("/", handlers.ListProperties(database))
	r.POST("/property/create", handlers.CreateProperty(database))
	r.POST("/property/pay-rent", handlers.PayRent(database))
	r.POST("/property/claim-rent", handlers.ClaimRent(database))

	r.Run(":8080")
}

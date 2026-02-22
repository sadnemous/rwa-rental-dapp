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
	r.LoadHTMLGlob("../web/templates/*")

	r.GET("/", handlers.ListProperties(database))

	r.Run(":8080")
}

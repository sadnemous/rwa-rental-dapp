package handlers

import (
	"database/sql"
	"net/http"

	"github.com/gin-gonic/gin"
)

func ListProperties(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		rows, _ := db.Query("SELECT id, name, location FROM properties")
		defer rows.Close()

		var props []map[string]interface{}

		for rows.Next() {
			var id int
			var name, location string
			rows.Scan(&id, &name, &location)

			props = append(props, gin.H{
				"id": id,
				"name": name,
				"location": location,
			})
		}

		c.HTML(http.StatusOK, "index.tmpl", gin.H{
			"properties": props,
		})
	}
}

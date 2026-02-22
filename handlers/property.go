package handlers

import (
	"database/sql"
	"fmt"
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"
)

// ListProperties returns all properties
func ListProperties(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		rows, _ := db.Query("SELECT id, name, location, contract_address, shares, rent_pool FROM properties")
		defer rows.Close()

		var props []map[string]interface{}

		for rows.Next() {
			var id int
			var name, location, contractAddr, rentPool string
			var shares int64
			rows.Scan(&id, &name, &location, &contractAddr, &shares, &rentPool)

			props = append(props, gin.H{
				"id":               id,
				"name":             name,
				"location":         location,
				"contract_address": contractAddr,
				"shares":           shares,
				"rent_pool":        rentPool,
			})
		}

		c.HTML(http.StatusOK, "index.tmpl", gin.H{
			"properties": props,
		})
	}
}

// CreateProperty adds a new RWA property
func CreateProperty(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		name := c.PostForm("name")
		location := c.PostForm("location")
		contractAddr := c.PostForm("contract_address")
		sharesStr := c.PostForm("shares")

		shares, err := strconv.ParseInt(sharesStr, 10, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid shares"})
			return
		}

		stmt, _ := db.Prepare("INSERT INTO properties (name, location, contract_address, shares, rent_pool) VALUES (?, ?, ?, ?, ?)")
		result, _ := stmt.Exec(name, location, contractAddr, shares, "0")
		id, _ := result.LastInsertId()

		c.JSON(http.StatusOK, gin.H{
			"id":               id,
			"name":             name,
			"location":         location,
			"contract_address": contractAddr,
			"shares":           shares,
		})
	}
}

// PayRent adds rent to a property's pool
func PayRent(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.PostForm("property_id")
		amountStr := c.PostForm("amount")

		amount, err := strconv.ParseFloat(amountStr, 64)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid amount"})
			return
		}

		// Get current rent pool
		var currentRent string
		db.QueryRow("SELECT rent_pool FROM properties WHERE id = ?", propertyID).Scan(&currentRent)

		currentAmount := 0.0
		if currentRent != "" && currentRent != "0" {
			currentAmount, _ = strconv.ParseFloat(currentRent, 64)
		}

		newTotal := fmt.Sprintf("%.2f", currentAmount+amount)

		stmt, _ := db.Prepare("UPDATE properties SET rent_pool = ? WHERE id = ?")
		stmt.Exec(newTotal, propertyID)

		c.JSON(http.StatusOK, gin.H{
			"property_id": propertyID,
			"amount":      amount,
			"new_total":   newTotal,
			"message":     "Rent paid successfully",
		})
	}
}

// ClaimRent claims rent for a property based on shares
func ClaimRent(db *sql.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		propertyID := c.PostForm("property_id")
		shareHolderShares := c.PostForm("holder_shares")

		// Get property details
		var rentPoolStr string
		var totalShares int64
		db.QueryRow("SELECT rent_pool, shares FROM properties WHERE id = ?", propertyID).Scan(&rentPoolStr, &totalShares)

		rentPool := 0.0
		if rentPoolStr != "" && rentPoolStr != "0" {
			rentPool, _ = strconv.ParseFloat(rentPoolStr, 64)
		}

		holderShares, _ := strconv.ParseInt(shareHolderShares, 10, 64)

		// Calculate claimable amount
		if totalShares == 0 {
			c.JSON(http.StatusBadRequest, gin.H{"error": "no total shares for this property"})
			return
		}

		claimableAmount := (rentPool * float64(holderShares)) / float64(totalShares)

		// Update rent pool (subtract claimed amount)
		newRentPool := fmt.Sprintf("%.2f", rentPool-claimableAmount)
		if rentPool-claimableAmount <= 0 {
			newRentPool = "0"
		}

		stmt, _ := db.Prepare("UPDATE properties SET rent_pool = ? WHERE id = ?")
		stmt.Exec(newRentPool, propertyID)

		c.JSON(http.StatusOK, gin.H{
			"property_id":     propertyID,
			"holder_shares":   holderShares,
			"total_shares":    totalShares,
			"claimable_amount": claimableAmount,
			"remaining_pool":   newRentPool,
			"message":          "Rent claimed successfully",
		})
	}
}

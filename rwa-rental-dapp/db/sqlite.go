package db

import (
	"database/sql"
	_ "github.com/mattn/go-sqlite3"
)

func InitDB() *sql.DB {
	db, _ := sql.Open("sqlite3", "rwa.db")

	sqlStmt := `
	CREATE TABLE IF NOT EXISTS properties (
		id INTEGER PRIMARY KEY,
		name TEXT,
		location TEXT,
		contract_address TEXT,
		shares INTEGER,
		rent_pool TEXT DEFAULT '0'
	);`
	db.Exec(sqlStmt)

	return db
}

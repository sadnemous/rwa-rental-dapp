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
		location TEXT
	);`
	db.Exec(sqlStmt)

	return db
}

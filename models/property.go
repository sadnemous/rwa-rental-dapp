package models

type Property struct {
	ID              int
	Name            string
	Location        string
	ContractAddress string
	Shares          int64
	RentPool        string
}

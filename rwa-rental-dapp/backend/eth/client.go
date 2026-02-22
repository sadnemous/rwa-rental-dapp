package eth

import (
	"log"

	"github.com/ethereum/go-ethereum/ethclient"
)

var Client *ethclient.Client

func Init() {
	c, err := ethclient.Dial("http://127.0.0.1:8545")
	if err != nil {
		log.Fatal(err)
	}
	Client = c
}

package main

import (
	"fmt"
	"os"

	"github.com/bfibraga/turntide/fetcher/internal/parsers"
)

func main() {
	// Test with card IDs
	content := `Island [LRW] [0271]
Mountain [LRW] [0272]
Sokka, Tenacious Tactician [TLA] [0352]`

	cards := parsers.ParseTurntide(content)
	
	fmt.Println("Parsed cards:")
	for i, card := range cards {
		fmt.Printf("%d. Name: %q, SetCode: %q, CardID: %q\n", i+1, card.Name, card.SetCode, card.CardID)
	}
}

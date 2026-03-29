package parsers

import (
	"strings"
)

// Parse Turntide format card decklist, each line contains a card name and set code with the format:
// <card name> [<set code>]
// or with optional card ID:
// <card name> [<set code>] [<card id>]
// Examples:
//   Island [LRW]
//   Sokka, Tenacious Tactician [TLA] [0352]

type TurntideCardData struct {
	Name    string
	SetCode string
	CardID  string // Optional collector's number / card ID
}

func ParseTurntide(content string) []TurntideCardData {
	cards := []TurntideCardData{}
	for line := range strings.SplitSeq(content, "\n") {
		if line == "" {
			continue
		}

		card := parseLine(line)
		if card != nil {
			cards = append(cards, *card)
		}
	}
	return cards
}

// parseLine parses a single decklist line
func parseLine(line string) *TurntideCardData {
	line = strings.TrimSpace(line)
	if line == "" {
		return nil
	}

	card := &TurntideCardData{}

	// Find all bracket-enclosed sections [...]
	var brackets []string
	var nameEndIdx int

	for i := 0; i < len(line); i++ {
		if line[i] == '[' {
			// Found opening bracket
			closingIdx := strings.Index(line[i:], "]")
			if closingIdx == -1 {
				// Unclosed bracket, skip
				continue
			}

			closingIdx += i
			bracketContent := strings.TrimSpace(line[i+1 : closingIdx])
			brackets = append(brackets, bracketContent)

			if nameEndIdx == 0 {
				// This is the end of the name
				nameEndIdx = i
			}

			i = closingIdx
		}
	}

	// Extract name (everything before first bracket)
	if nameEndIdx > 0 {
		card.Name = strings.TrimSpace(line[:nameEndIdx])
	} else {
		// No brackets found, treat entire line as name
		card.Name = line
		return card
	}

	// Extract SetCode and CardID from brackets
	if len(brackets) > 0 {
		card.SetCode = brackets[0]
	}
	if len(brackets) > 1 {
		card.CardID = brackets[1]
	}

	return card
}

package parsers

import "strings"

// Parse Turntide format card decklist, each line contains a card name and set code with the format:
// <card name> [<set code>]

type TurntideCardData struct {
	Name    string
	SetCode string
}

func ParseTurntide(content string) []TurntideCardData {
	cards := []TurntideCardData{}
	for line := range strings.SplitSeq(content, "\n") {
		if line == "" {
			continue
		}
		card := TurntideCardData{}
		parts := strings.Split(line, " [")
		card.Name = strings.TrimSpace(parts[0])
		if len(parts) > 1 {
			card.SetCode = strings.TrimRight(parts[1], "]")
		}

		cards = append(cards, card)
	}
	return cards
}

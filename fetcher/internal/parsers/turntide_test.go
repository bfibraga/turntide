package parsers

import (
	"testing"
)

// TestParseTurntideBasic tests parsing basic decklist format
func TestParseTurntideBasic(t *testing.T) {
	input := `Island [LRW]
Mountain [LRW]
Forest [LRW]`

	result := ParseTurntide(input)

	if len(result) != 3 {
		t.Errorf("Expected 3 cards, got %d", len(result))
	}

	tests := []struct {
		index   int
		name    string
		setCode string
		cardID  string
	}{
		{0, "Island", "LRW", ""},
		{1, "Mountain", "LRW", ""},
		{2, "Forest", "LRW", ""},
	}

	for _, tt := range tests {
		if result[tt.index].Name != tt.name {
			t.Errorf("Card %d: Expected name %q, got %q", tt.index, tt.name, result[tt.index].Name)
		}
		if result[tt.index].SetCode != tt.setCode {
			t.Errorf("Card %d: Expected SetCode %q, got %q", tt.index, tt.setCode, result[tt.index].SetCode)
		}
		if result[tt.index].CardID != tt.cardID {
			t.Errorf("Card %d: Expected CardID %q, got %q", tt.index, tt.cardID, result[tt.index].CardID)
		}
	}
}

// TestParseTurntideWithCardID tests parsing with optional card ID
func TestParseTurntideWithCardID(t *testing.T) {
	input := `Sokka, Tenacious Tactician [TLA] [0352]
Aang, the Last Airbender [TLA] [0001]
Island [LRW]`

	result := ParseTurntide(input)

	if len(result) != 3 {
		t.Errorf("Expected 3 cards, got %d", len(result))
	}

	tests := []struct {
		index   int
		name    string
		setCode string
		cardID  string
	}{
		{0, "Sokka, Tenacious Tactician", "TLA", "0352"},
		{1, "Aang, the Last Airbender", "TLA", "0001"},
		{2, "Island", "LRW", ""},
	}

	for _, tt := range tests {
		if result[tt.index].Name != tt.name {
			t.Errorf("Card %d: Expected name %q, got %q", tt.index, tt.name, result[tt.index].Name)
		}
		if result[tt.index].SetCode != tt.setCode {
			t.Errorf("Card %d: Expected SetCode %q, got %q", tt.index, tt.setCode, result[tt.index].SetCode)
		}
		if result[tt.index].CardID != tt.cardID {
			t.Errorf("Card %d: Expected CardID %q, got %q", tt.index, tt.cardID, result[tt.index].CardID)
		}
	}
}

// TestParseTurntideMixed tests parsing with mix of formats
func TestParseTurntideMixed(t *testing.T) {
	input := `4 Lightning Bolt [2XM]
Counterspell [A25] [0034]
2 Snapcaster Mage [2XM]`

	result := ParseTurntide(input)

	if len(result) != 3 {
		t.Errorf("Expected 3 cards, got %d", len(result))
	}

	tests := []struct {
		index   int
		name    string
		setCode string
		cardID  string
	}{
		{0, "4 Lightning Bolt", "2XM", ""},
		{1, "Counterspell", "A25", "0034"},
		{2, "2 Snapcaster Mage", "2XM", ""},
	}

	for _, tt := range tests {
		if result[tt.index].Name != tt.name {
			t.Errorf("Card %d: Expected name %q, got %q", tt.index, tt.name, result[tt.index].Name)
		}
		if result[tt.index].SetCode != tt.setCode {
			t.Errorf("Card %d: Expected SetCode %q, got %q", tt.index, tt.setCode, result[tt.index].SetCode)
		}
		if result[tt.index].CardID != tt.cardID {
			t.Errorf("Card %d: Expected CardID %q, got %q", tt.index, tt.cardID, result[tt.index].CardID)
		}
	}
}

// TestParseTurntideEmptyLines tests parsing with empty lines
func TestParseTurntideEmptyLines(t *testing.T) {
	input := `Island [LRW]

Mountain [LRW]


Forest [LRW]`

	result := ParseTurntide(input)

	if len(result) != 3 {
		t.Errorf("Expected 3 cards (empty lines ignored), got %d", len(result))
	}
}

// TestParseTurntideComplexNames tests parsing cards with special characters in name
func TestParseTurntideComplexNames(t *testing.T) {
	input := `Ashiok's Descent [C18]
Time / Tide [LRW] [0042]
"The" Card [MYS] [0001]
Spell Pierce [2XM]`

	result := ParseTurntide(input)

	if len(result) != 4 {
		t.Errorf("Expected 4 cards, got %d", len(result))
	}

	tests := []struct {
		index   int
		name    string
		setCode string
		cardID  string
	}{
		{0, "Ashiok's Descent", "C18", ""},
		{1, "Time / Tide", "LRW", "0042"},
		{2, `"The" Card`, "MYS", "0001"},
		{3, "Spell Pierce", "2XM", ""},
	}

	for _, tt := range tests {
		if result[tt.index].Name != tt.name {
			t.Errorf("Card %d: Expected name %q, got %q", tt.index, tt.name, result[tt.index].Name)
		}
		if result[tt.index].SetCode != tt.setCode {
			t.Errorf("Card %d: Expected SetCode %q, got %q", tt.index, tt.setCode, result[tt.index].SetCode)
		}
		if result[tt.index].CardID != tt.cardID {
			t.Errorf("Card %d: Expected CardID %q, got %q", tt.index, tt.cardID, result[tt.index].CardID)
		}
	}
}

// TestParseTurntideEdgeCases tests edge cases
func TestParseTurntideEdgeCases(t *testing.T) {
	tests := []struct {
		name          string
		input         string
		expectedCount int
	}{
		{
			name:          "Empty string",
			input:         "",
			expectedCount: 0,
		},
		{
			name:          "Only whitespace",
			input:         "   \n  \n  ",
			expectedCount: 0,
		},
		{
			name:          "Single card",
			input:         "Island [LRW]",
			expectedCount: 1,
		},
		{
			name:          "Card without brackets",
			input:         "Island",
			expectedCount: 1,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := ParseTurntide(tt.input)
			if len(result) != tt.expectedCount {
				t.Errorf("Expected %d cards, got %d", tt.expectedCount, len(result))
			}
		})
	}
}

// TestParseLineFunction tests the parseLine helper function
func TestParseLineFunction(t *testing.T) {
	tests := []struct {
		name      string
		line      string
		expName   string
		expSet    string
		expCardID string
	}{
		{
			name:      "Basic format",
			line:      "Island [LRW]",
			expName:   "Island",
			expSet:    "LRW",
			expCardID: "",
		},
		{
			name:      "With card ID",
			line:      "Sokka, Tenacious Tactician [TLA] [0352]",
			expName:   "Sokka, Tenacious Tactician",
			expSet:    "TLA",
			expCardID: "0352",
		},
		{
			name:      "Complex name with card ID",
			line:      "Ashiok's Beautiful Descent [C18] [042]",
			expName:   "Ashiok's Beautiful Descent",
			expSet:    "C18",
			expCardID: "042",
		},
		{
			name:      "Whitespace handling",
			line:      "  Island  [ LRW ]",
			expName:   "Island",
			expSet:    "LRW",
			expCardID: "",
		},
		{
			name:      "No set code",
			line:      "Island",
			expName:   "Island",
			expSet:    "",
			expCardID: "",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := parseLine(tt.line)
			if result == nil {
				t.Fatal("parseLine returned nil")
			}

			if result.Name != tt.expName {
				t.Errorf("Name: Expected %q, got %q", tt.expName, result.Name)
			}
			if result.SetCode != tt.expSet {
				t.Errorf("SetCode: Expected %q, got %q", tt.expSet, result.SetCode)
			}
			if result.CardID != tt.expCardID {
				t.Errorf("CardID: Expected %q, got %q", tt.expCardID, result.CardID)
			}
		})
	}
}

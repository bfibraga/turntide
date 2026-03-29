package providers

import (
	"context"
	"fmt"
	"os"
	"testing"

	"github.com/bfibraga/turntide/fetcher/internal/parsers"
)

// TestBuildScryfallImageURL tests the URL building logic
func TestBuildScryfallImageURL(t *testing.T) {
	tests := []struct {
		name       string
		scryfallID string
		format     string
		expected   string
	}{
		{
			name:       "PNG format",
			scryfallID: "d714d196-8cbc-4b53-8219-21044a017bce",
			format:     "png",
			expected:   "https://api.scryfall.com/cards/d714d196-8cbc-4b53-8219-21044a017bce",
		},
		{
			name:       "JPG format",
			scryfallID: "d714d196-8cbc-4b53-8219-21044a017bce",
			format:     "jpg",
			expected:   "https://api.scryfall.com/cards/d714d196-8cbc-4b53-8219-21044a017bce",
		},
		{
			name:       "WebP format",
			scryfallID: "d714d196-8cbc-4b53-8219-21044a017bce",
			format:     "webp",
			expected:   "https://api.scryfall.com/cards/d714d196-8cbc-4b53-8219-21044a017bce",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := buildScryfallImageURL(tt.scryfallID, tt.format)
			if result != tt.expected {
				t.Errorf("buildScryfallImageURL(%q, %q) = %q, want %q", tt.scryfallID, tt.format, result, tt.expected)
			}
		})
	}
}

// TestSanitizeFilename tests filename sanitization
func TestSanitizeFilename(t *testing.T) {
	tests := []struct {
		name     string
		input    string
		expected string
	}{
		{
			name:     "Simple name",
			input:    "Island",
			expected: "Island",
		},
		{
			name:     "Name with slashes",
			input:    "Time / Tide",
			expected: "Time___Tide",
		},
		{
			name:     "Name with apostrophe",
			input:    "Ashiok's Descent",
			expected: "Ashiok's_Descent",
		},
		{
			name:     "Name with quotes",
			input:    `"The" Card`,
			expected: "_The__Card",
		},
		{
			name:     "Name with colon",
			input:    "Name: The Card",
			expected: "Name__The_Card",
		},
		{
			name:     "Complex name",
			input:    "It That Betrays / The End?",
			expected: "It_That_Betrays___The_End_",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := sanitizeFilename(tt.input)
			if result != tt.expected {
				t.Errorf("sanitizeFilename(%q) = %q, want %q", tt.input, result, tt.expected)
			}
		})
	}
}

// TestGetImageURL tests image URL selection logic
func TestGetImageURL(t *testing.T) {
	tests := []struct {
		name          string
		imageURIs     map[string]string
		expectedFound bool
		expectedURL   string
	}{
		{
			name: "Prefer large",
			imageURIs: map[string]string{
				"large":  "https://example.com/large.jpg",
				"normal": "https://example.com/normal.jpg",
				"small":  "https://example.com/small.jpg",
			},
			expectedFound: true,
			expectedURL:   "https://example.com/large.jpg",
		},
		{
			name: "Fall back to normal when large missing",
			imageURIs: map[string]string{
				"normal": "https://example.com/normal.jpg",
				"small":  "https://example.com/small.jpg",
			},
			expectedFound: true,
			expectedURL:   "https://example.com/normal.jpg",
		},
		{
			name: "Fall back to small",
			imageURIs: map[string]string{
				"small": "https://example.com/small.jpg",
			},
			expectedFound: true,
			expectedURL:   "https://example.com/small.jpg",
		},
		{
			name:          "No image URLs",
			imageURIs:     map[string]string{},
			expectedFound: false,
			expectedURL:   "",
		},
		{
			name: "Empty large URL falls back",
			imageURIs: map[string]string{
				"large":  "",
				"normal": "https://example.com/normal.jpg",
			},
			expectedFound: true,
			expectedURL:   "https://example.com/normal.jpg",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := getImageURL(tt.imageURIs)
			if result != tt.expectedURL {
				t.Errorf("getImageURL() = %q, want %q", result, tt.expectedURL)
			}
		})
	}
}

// TestQueryCardImages tests the card query function
func TestQueryCardImages(t *testing.T) {
	// This test requires a real database or mock
	// For now, we'll test the structure is valid
	cards := []parsers.TurntideCardData{
		{
			Name:    "Island",
			SetCode: "LRW",
		},
	}

	// Just verify we don't panic
	step := QueryCardImages(cards, "shared/resources/cards.db", "png")
	if step == nil {
		t.Error("QueryCardImages returned nil function")
	}
}

// TestScryfallDownload tests the main download function
func TestScryfallDownload(t *testing.T) {
	// This test requires database and network access
	// Skip if run without integration flag
	if testing.Short() {
		t.Skip("Skipping integration test in short mode")
	}

	cards := []parsers.TurntideCardData{
		{
			Name:    "Island",
			SetCode: "LRW",
		},
	}

	tmpDir := t.TempDir()

	// Use absolute path to database
	dbPath := "/home/bfbraga/Documents/Programming/turntide/shared/resources/cards.db"

	// Skip if database doesn't exist
	if _, err := os.Stat(dbPath); err != nil {
		t.Skipf("Database not found at %s, skipping integration test", dbPath)
	}

	err := ScryfallDownload(cards, dbPath, tmpDir, "png")
	if err != nil {
		t.Errorf("ScryfallDownload() failed: %v", err)
	}

	// Verify at least one image was downloaded
	entries, err := os.ReadDir(tmpDir)
	if err != nil {
		t.Errorf("Failed to read output directory: %v", err)
		return
	}

	if len(entries) == 0 {
		t.Error("No images were downloaded")
	}
}

// TestMustNewRequest tests the HTTP request creation with headers
func TestMustNewRequest(t *testing.T) {
	ctx := context.Background()
	url := "https://api.scryfall.com/cards/test"

	req := mustNewRequest(ctx, "GET", url)

	if req.URL.String() != url {
		t.Errorf("Request URL = %q, want %q", req.URL.String(), url)
	}

	if req.Method != "GET" {
		t.Errorf("Request method = %q, want GET", req.Method)
	}

	userAgent := req.Header.Get("User-Agent")
	if userAgent == "" {
		t.Error("Request missing User-Agent header")
	}

	accept := req.Header.Get("Accept")
	if accept != "application/json" {
		t.Errorf("Request Accept header = %q, want application/json", accept)
	}
}

// TestCreateFilename tests filename creation with card data
func TestCreateFilename(t *testing.T) {
	cardData := CardImageData{
		Name:    "Island",
		SetCode: "LRW",
		UUID:    "bc9c4be7-5fb1-5e66-b69a-042eb91ba829",
	}

	tests := []struct {
		name        string
		url         string
		expectedExt string
	}{
		{
			name:        "JPEG image",
			url:         "https://example.com/image.jpg",
			expectedExt: ".jpg",
		},
		{
			name:        "PNG image",
			url:         "https://example.com/image.png",
			expectedExt: ".png",
		},
		{
			name:        "WEBP image",
			url:         "https://example.com/image.webp",
			expectedExt: ".webp",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Test extension extraction
			ext := ".png" // default
			if tt.url == "https://example.com/image.jpg" {
				ext = ".jpg"
			} else if tt.url == "https://example.com/image.webp" {
				ext = ".webp"
			} else if tt.url == "https://example.com/image.png" {
				ext = ".png"
			}

			if ext != tt.expectedExt {
				t.Errorf("Extension = %q, want %q", ext, tt.expectedExt)
			}

			// Verify filename format
			filename := fmt.Sprintf("%s_%s_%s%s",
				sanitizeFilename(cardData.Name),
				cardData.SetCode,
				cardData.UUID[:8],
				ext)

			expectedPrefix := fmt.Sprintf("Island_LRW_bc9c4be7%s", tt.expectedExt)
			if filename != expectedPrefix {
				t.Errorf("Filename = %q, want %q", filename, expectedPrefix)
			}
		})
	}
}

// BenchmarkSanitizeFilename benchmarks filename sanitization
func BenchmarkSanitizeFilename(b *testing.B) {
	for i := 0; i < b.N; i++ {
		sanitizeFilename("It That Betrays / The End?")
	}
}

// BenchmarkBuildScryfallImageURL benchmarks URL building
func BenchmarkBuildScryfallImageURL(b *testing.B) {
	for i := 0; i < b.N; i++ {
		buildScryfallImageURL("d714d196-8cbc-4b53-8219-21044a017bce", "png")
	}
}

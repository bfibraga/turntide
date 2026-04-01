package providers

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/bfibraga/turntide/fetcher/internal/download"
	"github.com/bfibraga/turntide/fetcher/internal/models"
	"github.com/bfibraga/turntide/fetcher/internal/parsers"
	"github.com/bfibraga/turntide/fetcher/internal/repository"
)

const (
	ScryfallAPIBase = "https://api.scryfall.com"
)

// ScryfallCardResponse represents the card data from Scryfall API
type ScryfallCardResponse struct {
	ID          string            `json:"id"`
	Name        string            `json:"name"`
	SetCode     string            `json:"set"`
	CollectorID string            `json:"collector_number"`
	ImageURIs   map[string]string `json:"image_uris"`
}

// CardImageData holds card info for image fetching
type CardImageData struct {
	Name       string
	SetCode    string
	UUID       string
	ScryfallID string
	ImageURL   string
}

var (
	imageCards []CardImageData
)

// ScryfallDownload downloads card images from Scryfall
func ScryfallDownload(cards []parsers.TurntideCardData, cardRepo repository.CardRepository, outputDir string, format string) error {
	return download.NewDownloadProviderBuilder().
		WithSteps(
			QueryCardImages(cards, cardRepo, format),
			DownloadImages(outputDir),
		).
		Download()
}

// QueryCardImages queries the database for Scryfall IDs and builds download list
func QueryCardImages(cards []parsers.TurntideCardData, cardRepo repository.CardRepository, format string) func(ctx context.Context) error {
	return func(ctx context.Context) error {
		imageCards = make([]CardImageData, 0, len(cards))

		for _, card := range cards {
			var cardData *models.CardWithScryfallID
			var err error

			if card.CardID != "" {
				cardData, err = cardRepo.GetByNameSetCodeAndNumber(ctx, card.Name, card.SetCode, card.CardID)
			} else {
				cardData, err = cardRepo.GetByNameAndSetCode(ctx, card.Name, card.SetCode)
			}

			if err != nil {
				return fmt.Errorf("failed to query card %s from set %s: %w", card.Name, card.SetCode, err)
			}

			if cardData == nil {
				fmt.Printf("Warning: Card %s from set %s not found in database\n", card.Name, card.SetCode)
				continue
			}

			imageURL := buildScryfallImageURL(cardData.ScryfallID, format)

			imageCards = append(imageCards, CardImageData{
				Name:       cardData.Name,
				SetCode:    cardData.SetCode,
				UUID:       cardData.UUID,
				ScryfallID: cardData.ScryfallID,
				ImageURL:   imageURL,
			})
		}

		return nil
	}
}

// buildScryfallImageURL constructs the Scryfall API URL for the card
func buildScryfallImageURL(scryfallID string, format string) string {
	// Use the Scryfall card endpoint with the Scryfall ID
	return fmt.Sprintf("%s/cards/%s", ScryfallAPIBase, scryfallID)
}

// DownloadImages downloads the card images from Scryfall
func DownloadImages(outputDir string) func(ctx context.Context) error {
	return func(ctx context.Context) error {
		if err := os.MkdirAll(outputDir, 0755); err != nil {
			return fmt.Errorf("failed to create output directory: %w", err)
		}

		for _, cardData := range imageCards {
			// Fetch card data from Scryfall API
			apiURL := fmt.Sprintf("%s/cards/%s", ScryfallAPIBase, cardData.ScryfallID)
			resp, err := http.DefaultClient.Do(mustNewRequest(ctx, http.MethodGet, apiURL))
			if err != nil {
				fmt.Printf("Warning: Failed to fetch card data for %s: %v\n", cardData.Name, err)
				continue
			}

			if resp.StatusCode != http.StatusOK {
				body, _ := io.ReadAll(resp.Body)
				resp.Body.Close()
				fmt.Printf("Warning: Scryfall API returned status %d for %s (%s): %s\n", resp.StatusCode, cardData.Name, apiURL, string(body))
				continue
			}

			// Parse Scryfall response
			var scryfallCard ScryfallCardResponse
			if err := json.NewDecoder(resp.Body).Decode(&scryfallCard); err != nil {
				resp.Body.Close()
				fmt.Printf("Warning: Failed to parse Scryfall response for %s: %v\n", cardData.Name, err)
				continue
			}
			resp.Body.Close()

			// Get image URL based on format
			imageURL := getImageURL(scryfallCard.ImageURIs)
			if imageURL == "" {
				fmt.Printf("Warning: No image URL found for %s\n", cardData.Name)
				continue
			}

			// Download the actual image
			if err := downloadImageFile(ctx, imageURL, outputDir, cardData); err != nil {
				fmt.Printf("Warning: Failed to download image for %s: %v\n", cardData.Name, err)
				continue
			}

			fmt.Printf("Downloaded: %s [%s]\n", cardData.Name, cardData.SetCode)
		}

		return nil
	}
}

// getImageURL selects the appropriate image URL from Scryfall response
func getImageURL(imageURIs map[string]string) string {
	// Prefer large, then normal, then small
	if url, ok := imageURIs["large"]; ok && url != "" {
		return url
	}
	if url, ok := imageURIs["normal"]; ok && url != "" {
		return url
	}
	if url, ok := imageURIs["small"]; ok && url != "" {
		return url
	}
	return ""
}

// downloadImageFile downloads and saves an image file
func downloadImageFile(ctx context.Context, imageURL string, outputDir string, cardData CardImageData) error {
	resp, err := http.DefaultClient.Do(mustNewRequest(ctx, http.MethodGet, imageURL))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("HTTP %d", resp.StatusCode)
	}

	// Determine file extension from image URL or default to png
	ext := ".png"
	if strings.Contains(imageURL, ".jpg") {
		ext = ".jpg"
	} else if strings.Contains(imageURL, ".webp") {
		ext = ".webp"
	}

	// Create filename: CardName_SetCode_UUID.ext
	filename := fmt.Sprintf("%s_%s_%s%s",
		sanitizeFilename(cardData.Name),
		cardData.SetCode,
		cardData.UUID[:8],
		ext)

	filepath := filepath.Join(outputDir, filename)

	// Save image to file
	out, err := os.Create(filepath)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, resp.Body)
	return err
}

// sanitizeFilename removes invalid filename characters
func sanitizeFilename(name string) string {
	replacer := strings.NewReplacer(
		"/", "_",
		"\\", "_",
		":", "_",
		"*", "_",
		"?", "_",
		"\"", "_",
		"<", "_",
		">", "_",
		"|", "_",
		" ", "_",
	)
	return replacer.Replace(name)
}

// mustNewRequest creates a new HTTP request with required headers
func mustNewRequest(ctx context.Context, method string, url string) *http.Request {
	req, err := http.NewRequestWithContext(ctx, method, url, nil)
	if err != nil {
		panic(err)
	}
	// Scryfall API requires User-Agent and Accept headers
	req.Header.Set("User-Agent", "Turntide/1.0 (github.com/bfibraga/turntide)")
	req.Header.Set("Accept", "application/json")
	return req
}

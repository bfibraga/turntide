/*
Copyright © 2026 Bruno Braga bf.braga@campus.fct.unl.pt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
package service

import (
	"context"
	"fmt"

	"github.com/bfibraga/turntide/fetcher/internal/models"
	"github.com/bfibraga/turntide/fetcher/internal/repository"
)

// CardService provides business logic for card operations
type CardService struct {
	cardRepo repository.CardRepository
}

// NewCardService creates a new CardService instance
func NewCardService(cardRepo repository.CardRepository) *CardService {
	return &CardService{
		cardRepo: cardRepo,
	}
}

// GetAllCards retrieves all cards with optional filtering
func (s *CardService) GetAllCards(ctx context.Context, filter *models.CardFilter) ([]*models.Card, error) {
	if filter != nil {
		return s.cardRepo.Search(ctx, filter)
	}
	// If no filter, return all cards with default limit
	return s.cardRepo.ListAll(ctx, 1000, 0)
}

// GetCardByUuid retrieves a card by its UUID
func (s *CardService) GetCardByUuid(ctx context.Context, uuid string) (*models.Card, error) {
	return s.cardRepo.GetByUuid(ctx, uuid)
}

// GetCardsByName retrieves cards by name
func (s *CardService) GetCardsByName(ctx context.Context, name string) ([]*models.Card, error) {
	return s.cardRepo.GetByName(ctx, name)
}

// GetCardsBySetCode retrieves cards by set code
func (s *CardService) GetCardsBySetCode(ctx context.Context, setCode string) ([]*models.Card, error) {
	return s.cardRepo.GetBySetCode(ctx, setCode)
}

// GetCardsByColor retrieves cards by color
func (s *CardService) GetCardsByColor(ctx context.Context, color string, limit int32, offset int32) ([]*models.Card, error) {
	return s.cardRepo.GetByColor(ctx, color, limit, offset)
}

// GetCardsByRarity retrieves cards by rarity
func (s *CardService) GetCardsByRarity(ctx context.Context, rarity string, limit int32, offset int32) ([]*models.Card, error) {
	return s.cardRepo.GetByRarity(ctx, rarity, limit, offset)
}

// GetCardsByManaValue retrieves cards by mana value
func (s *CardService) GetCardsByManaValue(ctx context.Context, manaValue float64, limit int32, offset int32) ([]*models.Card, error) {
	return s.cardRepo.GetByManaValue(ctx, manaValue, limit, offset)
}

// GetCardStatistics returns statistics about the cards in the database
func (s *CardService) GetCardStatistics(ctx context.Context) (map[string]interface{}, error) {
	count, err := s.cardRepo.Count(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get card count: %w", err)
	}

	stats := map[string]interface{}{
		"total_cards": count,
	}

	return stats, nil
}

// Close closes the underlying repository connection
func (s *CardService) Close() error {
	return s.cardRepo.Close()
}

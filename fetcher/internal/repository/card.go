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
package repository

import (
	"context"

	"github.com/bfibraga/turntide/fetcher/internal/models"
)

// CardRepository defines the interface for card data access
type CardRepository interface {
	// GetByUuid retrieves a card by its UUID
	GetByUuid(ctx context.Context, uuid string) (*models.Card, error)

	// GetByName retrieves cards matching a name
	GetByName(ctx context.Context, name string) ([]*models.Card, error)

	// GetBySetCode retrieves all cards from a specific set
	GetBySetCode(ctx context.Context, setCode string) ([]*models.Card, error)

	// ListAll retrieves cards with pagination
	ListAll(ctx context.Context, limit int32, offset int32) ([]*models.Card, error)

	// Search retrieves cards with dynamic filtering
	Search(ctx context.Context, filter *models.CardFilter) ([]*models.Card, error)

	// Count returns the total number of cards
	Count(ctx context.Context) (int64, error)

	// GetByColor retrieves cards of a specific color
	GetByColor(ctx context.Context, color string, limit int32, offset int32) ([]*models.Card, error)

	// GetByRarity retrieves cards of a specific rarity
	GetByRarity(ctx context.Context, rarity string, limit int32, offset int32) ([]*models.Card, error)

	// GetByManaValue retrieves cards with a specific mana value
	GetByManaValue(ctx context.Context, manaValue float64, limit int32, offset int32) ([]*models.Card, error)

	// GetByNameSetCodeAndNumber retrieves a card by name, set code, and collector number
	GetByNameSetCodeAndNumber(ctx context.Context, name, setCode, number string) (*models.CardWithScryfallID, error)

	// GetByNameAndSetCode retrieves a card by name and set code (first match)
	GetByNameAndSetCode(ctx context.Context, name, setCode string) (*models.CardWithScryfallID, error)

	// Close closes the underlying database connection
	Close() error
}

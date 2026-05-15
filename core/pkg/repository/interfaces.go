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

	"github.com/bfibraga/turntide/core/internal/db/cards"
	"github.com/bfibraga/turntide/core/internal/db/server"
)

// Re-export types used in interfaces for convenience
type (
	Cardidentifier                   = cards.Cardidentifier
	GetCardByNameSetCodeAndNumberRow = cards.GetCardByNameSetCodeAndNumberRow
	GetCardByNameAndSetCodeRow       = cards.GetCardByNameAndSetCodeRow
)

// CardModel re-exports the cards.Card type for convenience
type CardModel = cards.Card

type CardSearchParams = cards.SearchCardsParams

// CardRepository defines the interface for card data access
type CardRepository interface {
	// GetByUuid retrieves a card by its UUID
	GetByUuid(ctx context.Context, uuid string) (*CardModel, error)

	// GetByName retrieves cards matching a name
	GetByName(ctx context.Context, name string) ([]*CardModel, error)

	// GetBySetCode retrieves all cards from a specific set
	GetBySetCode(ctx context.Context, setCode string) ([]*CardModel, error)

	// ListAll retrieves cards with pagination
	ListAll(ctx context.Context, limit, offset int32) ([]*CardModel, error)

	// SearchCards retrieves cards matching a filter
	SearchCards(ctx context.Context, filter *CardSearchParams) ([]*CardModel, error)

	// Count returns the total number of cards
	Count(ctx context.Context) (int64, error)

	// GetByColor retrieves cards of a specific color
	GetByColor(ctx context.Context, color string, limit, offset int32) ([]*CardModel, error)

	// GetByRarity retrieves cards of a specific rarity
	GetByRarity(ctx context.Context, rarity string, limit, offset int32) ([]*CardModel, error)

	// GetByManaValue retrieves cards with a specific mana value
	GetByManaValue(ctx context.Context, manaValue float64, limit, offset int32) ([]*CardModel, error)

	// GetByNameSetCodeAndNumber retrieves a card by name, set code, and collector number
	GetByNameSetCodeAndNumber(ctx context.Context, name, setCode, number string) (*GetCardByNameSetCodeAndNumberRow, error)

	// GetByNameAndSetCode retrieves a card by name and set code (first match)
	GetByNameAndSetCode(ctx context.Context, name, setCode string) (*GetCardByNameAndSetCodeRow, error)

	// Close closes the underlying database connection
	Close() error
}

// SetModel re-exports the cards.Set type for convenience
type SetModel = cards.Set

// SetRepository defines the interface for set data access
type SetRepository interface {
	// GetByCode retrieves a set by its code
	GetByCode(ctx context.Context, code string) (*SetModel, error)

	// GetByName retrieves sets matching a name
	GetByName(ctx context.Context, name string) ([]*SetModel, error)

	// ListAll retrieves all sets with pagination
	ListAll(ctx context.Context, limit, offset int32) ([]*SetModel, error)

	// Count returns the total number of sets
	Count(ctx context.Context) (int64, error)

	// Close closes the underlying database connection
	Close() error
}


// UserModel re-exports the server.User type for convenience
type UserModel = server.User

// UserRepository defines the interface for user data access
type UserRepository interface {
	// Create creates a new user with the given username and password
	// Password should be plain text; it will be hashed before storing
	Create(ctx context.Context, username, passwordHash string) (*UserModel, error)

	// GetByUsername retrieves a user by username
	GetByUsername(ctx context.Context, username string) (*UserModel, error)
}

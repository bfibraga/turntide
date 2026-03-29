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
	"database/sql"
	"fmt"

	"github.com/bfibraga/turntide/fetcher/internal/db"
	"github.com/bfibraga/turntide/fetcher/internal/models"
)

// SQLiteCardRepository implements CardRepository using sqlc
type SQLiteCardRepository struct {
	queries *db.Queries
	conn    *sql.DB
}

// NewSQLiteCardRepository creates a new SQLite card repository
func NewSQLiteCardRepository(conn *sql.DB) *SQLiteCardRepository {
	return &SQLiteCardRepository{
		queries: db.New(conn),
		conn:    conn,
	}
}

// GetByUuid implements CardRepository.GetByUuid
func (r *SQLiteCardRepository) GetByUuid(ctx context.Context, uuid string) (*models.Card, error) {
	nsUuid := sql.NullString{String: uuid, Valid: uuid != ""}
	dbCard, err := r.queries.GetCardByUuid(ctx, nsUuid)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("card not found")
		}
		return nil, fmt.Errorf("failed to get card: %w", err)
	}
	return models.ToCard(dbCard), nil
}

// GetByName implements CardRepository.GetByName
func (r *SQLiteCardRepository) GetByName(ctx context.Context, name string) ([]*models.Card, error) {
	searchPattern := sql.NullString{String: "%" + name + "%", Valid: name != ""}
	dbCards, err := r.queries.GetCardByName(ctx, searchPattern)
	if err != nil {
		return nil, fmt.Errorf("failed to search cards by name: %w", err)
	}
	return models.ToCards(dbCards), nil
}

// GetBySetCode implements CardRepository.GetBySetCode
func (r *SQLiteCardRepository) GetBySetCode(ctx context.Context, setCode string) ([]*models.Card, error) {
	nsSetCode := sql.NullString{String: setCode, Valid: setCode != ""}
	dbCards, err := r.queries.GetCardsBySetCode(ctx, nsSetCode)
	if err != nil {
		return nil, fmt.Errorf("failed to get cards by set code: %w", err)
	}
	return models.ToCards(dbCards), nil
}

// ListAll implements CardRepository.ListAll
func (r *SQLiteCardRepository) ListAll(ctx context.Context, limit int32, offset int32) ([]*models.Card, error) {
	dbCards, err := r.queries.ListAllCards(ctx, db.ListAllCardsParams{
		Limit:  int64(limit),
		Offset: int64(offset),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to list cards: %w", err)
	}
	return models.ToCards(dbCards), nil
}

// Search implements CardRepository.Search
func (r *SQLiteCardRepository) Search(ctx context.Context, filter *models.CardFilter) ([]*models.Card, error) {
	// Build parameters for search
	var namePattern sql.NullString
	if filter.Name != nil && *filter.Name != "" {
		namePattern = sql.NullString{String: "%" + *filter.Name + "%", Valid: true}
	}

	var typePattern sql.NullString
	if filter.Type != nil && *filter.Type != "" {
		typePattern = sql.NullString{String: "%" + *filter.Type + "%", Valid: true}
	}

	var setCode sql.NullString
	if filter.SetCode != nil && *filter.SetCode != "" {
		setCode = sql.NullString{String: *filter.SetCode, Valid: true}
	}

	dbCards, err := r.queries.SearchCards(ctx, db.SearchCardsParams{
		Column1: namePattern,
		Name:    namePattern,
		Column3: setCode,
		Setcode: setCode,
		Column5: typePattern,
		Type:    typePattern,
		Limit:   int64(filter.Limit),
		Offset:  int64(filter.Offset),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to search cards: %w", err)
	}
	return models.ToCards(dbCards), nil
}

// Count implements CardRepository.Count
func (r *SQLiteCardRepository) Count(ctx context.Context) (int64, error) {
	count, err := r.queries.CountCards(ctx)
	if err != nil {
		return 0, fmt.Errorf("failed to count cards: %w", err)
	}
	return count, nil
}

// GetByColor implements CardRepository.GetByColor
func (r *SQLiteCardRepository) GetByColor(ctx context.Context, color string, limit int32, offset int32) ([]*models.Card, error) {
	searchPattern := sql.NullString{String: "%" + color + "%", Valid: color != ""}
	dbCards, err := r.queries.GetCardsByColor(ctx, db.GetCardsByColorParams{
		Colors: searchPattern,
		Limit:  int64(limit),
		Offset: int64(offset),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to get cards by color: %w", err)
	}
	return models.ToCards(dbCards), nil
}

// GetByRarity implements CardRepository.GetByRarity
func (r *SQLiteCardRepository) GetByRarity(ctx context.Context, rarity string, limit int32, offset int32) ([]*models.Card, error) {
	rarityNs := sql.NullString{String: rarity, Valid: rarity != ""}
	dbCards, err := r.queries.GetCardsByRarity(ctx, db.GetCardsByRarityParams{
		Rarity: rarityNs,
		Limit:  int64(limit),
		Offset: int64(offset),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to get cards by rarity: %w", err)
	}
	return models.ToCards(dbCards), nil
}

// GetByManaValue implements CardRepository.GetByManaValue
func (r *SQLiteCardRepository) GetByManaValue(ctx context.Context, manaValue float64, limit int32, offset int32) ([]*models.Card, error) {
	dbCards, err := r.queries.GetCardsByManaValue(ctx, db.GetCardsByManaValueParams{
		Manavalue: sql.NullFloat64{Float64: manaValue, Valid: manaValue > 0},
		Limit:     int64(limit),
		Offset:    int64(offset),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to get cards by mana value: %w", err)
	}
	return models.ToCards(dbCards), nil
}

// Close implements CardRepository.Close
func (r *SQLiteCardRepository) Close() error {
	return r.conn.Close()
}

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

	"github.com/bfibraga/turntide/core/internal/db/cards"
	"github.com/bfibraga/turntide/core/internal/db/server"
)

// cardRepository implements CardRepository using sqlc-generated queries
type cardRepository struct {
	queries *cards.Queries
}

func NewCardRepository(db DBTX) CardRepository {
	return &cardRepository{queries: cards.New(db)}
}

func (r *cardRepository) Close() error {
	// Connection is managed by the factory, nothing to close here
	return nil
}

func (r *cardRepository) GetByUuid(ctx context.Context, uuid string) (*cards.Card, error) {
	result, err := r.queries.GetCardByUuid(ctx, sql.NullString{String: uuid, Valid: true})
	if err != nil {
		return nil, err
	}
	return &result, nil
}

func (r *cardRepository) GetByName(ctx context.Context, name string) ([]*cards.Card, error) {
	results, err := r.queries.GetCardByName(ctx, sql.NullString{String: "%" + name + "%", Valid: true})
	if err != nil {
		return nil, err
	}
	cards := make([]*cards.Card, len(results))
	for i := range results {
		cards[i] = &results[i]
	}
	return cards, nil
}

func (r *cardRepository) GetBySetCode(ctx context.Context, setCode string) ([]*cards.Card, error) {
	results, err := r.queries.GetCardsBySetCode(ctx, sql.NullString{String: setCode, Valid: true})
	if err != nil {
		return nil, err
	}
	cards := make([]*cards.Card, len(results))
	for i := range results {
		cards[i] = &results[i]
	}
	return cards, nil
}

func (r *cardRepository) ListAll(ctx context.Context, limit, offset int32) ([]*cards.Card, error) {
	results, err := r.queries.ListAllCards(ctx, cards.ListAllCardsParams{
		Limit:  int64(limit),
		Offset: int64(offset),
	})
	if err != nil {
		return nil, err
	}
	cards := make([]*cards.Card, len(results))
	for i := range results {
		cards[i] = &results[i]
	}
	return cards, nil
}

func (r *cardRepository) Count(ctx context.Context) (int64, error) {
	return r.queries.CountCards(ctx)
}

func (r *cardRepository) GetByColor(ctx context.Context, color string, limit, offset int32) ([]*cards.Card, error) {
	results, err := r.queries.GetCardsByColor(ctx, cards.GetCardsByColorParams{
		Colors: sql.NullString{String: color, Valid: true},
		Limit:  int64(limit),
		Offset: int64(offset),
	})
	if err != nil {
		return nil, err
	}
	cards := make([]*cards.Card, len(results))
	for i := range results {
		cards[i] = &results[i]
	}
	return cards, nil
}

func (r *cardRepository) GetByRarity(ctx context.Context, rarity string, limit, offset int32) ([]*cards.Card, error) {
	results, err := r.queries.GetCardsByRarity(ctx, cards.GetCardsByRarityParams{
		Rarity: sql.NullString{String: rarity, Valid: true},
		Limit:  int64(limit),
		Offset: int64(offset),
	})
	if err != nil {
		return nil, err
	}
	cards := make([]*cards.Card, len(results))
	for i := range results {
		cards[i] = &results[i]
	}
	return cards, nil
}

func (r *cardRepository) GetByManaValue(ctx context.Context, manaValue float64, limit, offset int32) ([]*cards.Card, error) {
	results, err := r.queries.GetCardsByManaValue(ctx, cards.GetCardsByManaValueParams{
		Manavalue: sql.NullFloat64{Float64: manaValue, Valid: true},
		Limit:     int64(limit),
		Offset:    int64(offset),
	})
	if err != nil {
		return nil, err
	}
	cards := make([]*cards.Card, len(results))
	for i := range results {
		cards[i] = &results[i]
	}
	return cards, nil
}

func (r *cardRepository) GetByNameSetCodeAndNumber(ctx context.Context, name, setCode, number string) (*cards.GetCardByNameSetCodeAndNumberRow, error) {
	result, err := r.queries.GetCardByNameSetCodeAndNumber(ctx, cards.GetCardByNameSetCodeAndNumberParams{
		Name:    sql.NullString{String: name, Valid: true},
		Setcode: sql.NullString{String: setCode, Valid: true},
		Number:  sql.NullString{String: number, Valid: true},
	})
	if err != nil {
		return nil, err
	}
	return &result, nil
}

func (r *cardRepository) GetByNameAndSetCode(ctx context.Context, name, setCode string) (*cards.GetCardByNameAndSetCodeRow, error) {
	result, err := r.queries.GetCardByNameAndSetCode(ctx, cards.GetCardByNameAndSetCodeParams{
		Name:    sql.NullString{String: name, Valid: true},
		Setcode: sql.NullString{String: setCode, Valid: true},
	})
	if err != nil {
		return nil, err
	}
	return &result, nil
}

// setRepository implements SetRepository using sqlc-generated queries
type setRepository struct {
	queries *cards.Queries
}

func NewSetRepository(db DBTX) SetRepository {
	return &setRepository{queries: cards.New(db)}
}

func (r *setRepository) Close() error {
	// Connection is managed by the factory, nothing to close here
	return nil
}

func (r *setRepository) GetByCode(ctx context.Context, code string) (*cards.Set, error) {
	result, err := r.queries.GetSetByCode(ctx, sql.NullString{String: code, Valid: true})
	if err != nil {
		return nil, err
	}
	return &result, nil
}

func (r *setRepository) GetByName(ctx context.Context, name string) ([]*cards.Set, error) {
	results, err := r.queries.GetSetByName(ctx, sql.NullString{String: "%" + name + "%", Valid: true})
	if err != nil {
		return nil, err
	}
	sets := make([]*cards.Set, len(results))
	for i := range results {
		sets[i] = &results[i]
	}
	return sets, nil
}

func (r *setRepository) ListAll(ctx context.Context, limit, offset int32) ([]*cards.Set, error) {
	results, err := r.queries.ListAllSets(ctx, cards.ListAllSetsParams{
		Limit:  int64(limit),
		Offset: int64(offset),
	})
	if err != nil {
		return nil, err
	}
	sets := make([]*cards.Set, len(results))
	for i := range results {
		sets[i] = &results[i]
	}
	return sets, nil
}

func (r *setRepository) Count(ctx context.Context) (int64, error) {
	return r.queries.CountSets(ctx)
}

// userRepository implements UserRepository using sqlc-generated queries
type userRepository struct {
	queries *server.Queries
}

func NewUserRepository(db DBTX) UserRepository {
	return &userRepository{queries: server.New(db)}
}

func (r *userRepository) Create(ctx context.Context, username, passwordHash string) (*server.User, error) {
	result, err := r.queries.CreateUser(ctx, server.CreateUserParams{
		Username:     username,
		PasswordHash: passwordHash,
	})
	if err != nil {
		return nil, err
	}
	return &result, nil
}

func (r *userRepository) GetByUsername(ctx context.Context, username string) (*server.User, error) {
	result, err := r.queries.GetUserByUsername(ctx, username)
	if err != nil {
		return nil, err
	}
	return &result, nil
}

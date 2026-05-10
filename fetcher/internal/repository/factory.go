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
	"log/slog"

	"github.com/bfibraga/turntide/core/pkg/repository"
	"github.com/bfibraga/turntide/fetcher/internal/models"
)

// cardRepositoryAdapter wraps core CardRepository and converts to fetcher models
type cardRepositoryAdapter struct {
	repo repository.CardRepository
	conn *sql.DB
}

func newCardRepositoryAdapter(repo repository.CardRepository, conn *sql.DB) CardRepository {
	return &cardRepositoryAdapter{repo: repo, conn: conn}
}

func (a *cardRepositoryAdapter) GetByUuid(ctx context.Context, uuid string) (*models.Card, error) {
	card, err := a.repo.GetByUuid(ctx, uuid)
	if err != nil {
		return nil, err
	}
	return toFetcherCard(card), nil
}

func (a *cardRepositoryAdapter) GetByName(ctx context.Context, name string) ([]*models.Card, error) {
	cards, err := a.repo.GetByName(ctx, name)
	if err != nil {
		return nil, err
	}
	return toFetcherCards(cards), nil
}

func (a *cardRepositoryAdapter) GetBySetCode(ctx context.Context, setCode string) ([]*models.Card, error) {
	cards, err := a.repo.GetBySetCode(ctx, setCode)
	if err != nil {
		return nil, err
	}
	return toFetcherCards(cards), nil
}

func (a *cardRepositoryAdapter) ListAll(ctx context.Context, limit, offset int32) ([]*models.Card, error) {
	cards, err := a.repo.ListAll(ctx, limit, offset)
	if err != nil {
		return nil, err
	}
	return toFetcherCards(cards), nil
}

func (a *cardRepositoryAdapter) Search(ctx context.Context, filter *models.CardFilter) ([]*models.Card, error) {
	if filter != nil && filter.Name != nil && *filter.Name != "" {
		return a.GetByName(ctx, *filter.Name)
	}
	return a.ListAll(ctx, filter.Limit, filter.Offset)
}

func (a *cardRepositoryAdapter) Count(ctx context.Context) (int64, error) {
	return a.repo.Count(ctx)
}

func (a *cardRepositoryAdapter) GetByColor(ctx context.Context, color string, limit, offset int32) ([]*models.Card, error) {
	cards, err := a.repo.GetByColor(ctx, color, limit, offset)
	if err != nil {
		return nil, err
	}
	return toFetcherCards(cards), nil
}

func (a *cardRepositoryAdapter) GetByRarity(ctx context.Context, rarity string, limit, offset int32) ([]*models.Card, error) {
	cards, err := a.repo.GetByRarity(ctx, rarity, limit, offset)
	if err != nil {
		return nil, err
	}
	return toFetcherCards(cards), nil
}

func (a *cardRepositoryAdapter) GetByManaValue(ctx context.Context, manaValue float64, limit, offset int32) ([]*models.Card, error) {
	cards, err := a.repo.GetByManaValue(ctx, manaValue, limit, offset)
	if err != nil {
		return nil, err
	}
	return toFetcherCards(cards), nil
}

func (a *cardRepositoryAdapter) GetByNameSetCodeAndNumber(ctx context.Context, name, setCode, number string) (*models.CardWithScryfallID, error) {
	row, err := a.repo.GetByNameSetCodeAndNumber(ctx, name, setCode, number)
	if err != nil {
		return nil, err
	}
	return &models.CardWithScryfallID{
		UUID:       row.Uuid.String,
		Name:       row.Name.String,
		SetCode:    row.Setcode.String,
		Number:     row.Number.String,
		ScryfallID: row.Scryfallid.String,
	}, nil
}

func (a *cardRepositoryAdapter) GetByNameAndSetCode(ctx context.Context, name, setCode string) (*models.CardWithScryfallID, error) {
	row, err := a.repo.GetByNameAndSetCode(ctx, name, setCode)
	if err != nil {
		return nil, err
	}
	return &models.CardWithScryfallID{
		UUID:       row.Uuid.String,
		Name:       row.Name.String,
		SetCode:    row.Setcode.String,
		ScryfallID: row.Scryfallid.String,
	}, nil
}

func (a *cardRepositoryAdapter) Close() error {
	return a.conn.Close()
}

// setRepositoryAdapter wraps core SetRepository and converts to fetcher models
type setRepositoryAdapter struct {
	repo repository.SetRepository
	conn *sql.DB
}

func newSetRepositoryAdapter(repo repository.SetRepository, conn *sql.DB) SetRepository {
	return &setRepositoryAdapter{repo: repo, conn: conn}
}

func (a *setRepositoryAdapter) GetByCode(ctx context.Context, code string) (*models.Set, error) {
	set, err := a.repo.GetByCode(ctx, code)
	if err != nil {
		return nil, err
	}
	return toFetcherSet(set), nil
}

func (a *setRepositoryAdapter) GetByName(ctx context.Context, name string) ([]*models.Set, error) {
	sets, err := a.repo.GetByName(ctx, name)
	if err != nil {
		return nil, err
	}
	return toFetcherSets(sets), nil
}

func (a *setRepositoryAdapter) ListAll(ctx context.Context, limit, offset int32) ([]*models.Set, error) {
	sets, err := a.repo.ListAll(ctx, limit, offset)
	if err != nil {
		return nil, err
	}
	return toFetcherSets(sets), nil
}

func (a *setRepositoryAdapter) Count(ctx context.Context) (int64, error) {
	return a.repo.Count(ctx)
}

func (a *setRepositoryAdapter) Close() error {
	return a.conn.Close()
}

// Factory wraps the core CardsFactory to provide fetcher-specific repository interfaces
type Factory struct {
	factory *repository.CardsFactory
	conn    *sql.DB
}

// NewFactory creates a new repository factory using the core CardsFactory
func NewFactory(dbPath string, logger *slog.Logger) (*Factory, error) {
	factory, err := repository.NewCardsFactory(dbPath, logger)
	if err != nil {
		return nil, err
	}
	return &Factory{factory: factory, conn: factory.GetConn()}, nil
}

// NewCardRepository creates a new CardRepository instance
func (f *Factory) NewCardRepository() CardRepository {
	return newCardRepositoryAdapter(f.factory.CreateCardRepository(), f.conn)
}

// NewSetRepository creates a new SetRepository instance
func (f *Factory) NewSetRepository() SetRepository {
	return newSetRepositoryAdapter(f.factory.CreateSetRepository(), f.conn)
}

// Close closes the database connection
func (f *Factory) Close() error {
	return f.factory.Close()
}

// Conversion functions - will use models from core/internal/db/cards
// We'll use reflection to access the fields since we can't import internal
func toFetcherCard(card interface{}) *models.Card {
	// Simplified - return empty card for now
	// In production, use proper reflection or codegen
	return &models.Card{}
}

func toFetcherCards(cards interface{}) []*models.Card {
	return []*models.Card{}
}

func toFetcherSet(set interface{}) *models.Set {
	// Simplified - return empty set for now
	return &models.Set{}
}

func toFetcherSets(sets interface{}) []*models.Set {
	return []*models.Set{}
}

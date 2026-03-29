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

// SQLiteSetRepository implements SetRepository using sqlc
type SQLiteSetRepository struct {
	queries *db.Queries
	conn    *sql.DB
}

// NewSQLiteSetRepository creates a new SQLite set repository
func NewSQLiteSetRepository(conn *sql.DB) *SQLiteSetRepository {
	return &SQLiteSetRepository{
		queries: db.New(conn),
		conn:    conn,
	}
}

// GetByCode implements SetRepository.GetByCode
func (r *SQLiteSetRepository) GetByCode(ctx context.Context, code string) (*models.Set, error) {
	nsCode := sql.NullString{String: code, Valid: code != ""}
	dbSet, err := r.queries.GetSetByCode(ctx, nsCode)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("set not found")
		}
		return nil, fmt.Errorf("failed to get set: %w", err)
	}
	return models.ToSet(dbSet), nil
}

// GetByName implements SetRepository.GetByName
func (r *SQLiteSetRepository) GetByName(ctx context.Context, name string) ([]*models.Set, error) {
	searchPattern := sql.NullString{String: "%" + name + "%", Valid: name != ""}
	dbSets, err := r.queries.GetSetByName(ctx, searchPattern)
	if err != nil {
		return nil, fmt.Errorf("failed to search sets by name: %w", err)
	}
	return models.ToSets(dbSets), nil
}

// ListAll implements SetRepository.ListAll
func (r *SQLiteSetRepository) ListAll(ctx context.Context, limit int32, offset int32) ([]*models.Set, error) {
	dbSets, err := r.queries.ListAllSets(ctx, db.ListAllSetsParams{
		Limit:  int64(limit),
		Offset: int64(offset),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to list sets: %w", err)
	}
	return models.ToSets(dbSets), nil
}

// Count implements SetRepository.Count
func (r *SQLiteSetRepository) Count(ctx context.Context) (int64, error) {
	count, err := r.queries.CountSets(ctx)
	if err != nil {
		return 0, fmt.Errorf("failed to count sets: %w", err)
	}
	return count, nil
}

// Close implements SetRepository.Close
func (r *SQLiteSetRepository) Close() error {
	return r.conn.Close()
}

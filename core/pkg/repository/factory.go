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
	"log/slog"
	"os"
	"path/filepath"

	_ "modernc.org/sqlite"
)

const (
	DefaultCardsDBPath  = "shared/resources/cards.db"
	DefaultServerDBPath = "resources/server.db"
)

// RepositoryFactory is the abstract factory interface for creating repositories
type RepositoryFactory interface {
	// Cards domain
	CreateCardRepository() CardRepository
	CreateSetRepository() SetRepository

	// Server domain
	CreateUserRepository() UserRepository

	// Lifecycle
	Close() error
}

// DBTX is the database interface used by sqlc generated code
type DBTX interface {
	ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error)
	PrepareContext(ctx context.Context, query string) (*sql.Stmt, error)
	QueryContext(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error)
	QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row
}

// Factory provides common factory functionality
type Factory struct {
	conn   *sql.DB
	logger *slog.Logger
}

func NewFactory(dbPath string, logger *slog.Logger) (*Factory, error) {
	if dbPath == "" {
		return nil, fmt.Errorf("database path is required")
	}

	dir := filepath.Dir(dbPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create database directory: %w", err)
	}

	conn, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	if err := conn.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &Factory{conn: conn, logger: logger}, nil
}

func (f *Factory) GetConn() *sql.DB {
	return f.conn
}

func (f *Factory) GetDBTX() DBTX {
	return f.conn
}

func (f *Factory) Close() error {
	return f.conn.Close()
}


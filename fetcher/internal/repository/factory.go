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
	"database/sql"
	"fmt"
	"os"

	_ "github.com/mattn/go-sqlite3"
)

const (
	// DefaultDatabasePath is the default path to the shared database
	DefaultDatabasePath = "/shared/resources/cards.db"
)

// Factory provides a centralized way to create repository instances
type Factory struct {
	conn *sql.DB
}

// NewFactory creates a new repository factory
func NewFactory(dbPath string) (*Factory, error) {
	// Use default path if not provided
	if dbPath == "" {
		dbPath = DefaultDatabasePath
	}

	// Check if the database file exists
	if _, err := os.Stat(dbPath); err != nil {
		if os.IsNotExist(err) {
			return nil, fmt.Errorf("database file not found at %s", dbPath)
		}
		return nil, fmt.Errorf("failed to access database: %w", err)
	}

	// Open database connection
	conn, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Test the connection
	if err := conn.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &Factory{conn: conn}, nil
}

// NewCardRepository creates a new CardRepository instance
func (f *Factory) NewCardRepository() CardRepository {
	return NewSQLiteCardRepository(f.conn)
}

// NewSetRepository creates a new SetRepository instance
func (f *Factory) NewSetRepository() SetRepository {
	return NewSQLiteSetRepository(f.conn)
}

// Close closes the database connection
func (f *Factory) Close() error {
	return f.conn.Close()
}

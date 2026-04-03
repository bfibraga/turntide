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
	_ "embed"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"

	"github.com/bfibraga/turntide/server/internal/server/db/config"
	_ "github.com/mattn/go-sqlite3"
)

const (
	// DefaultDatabasePath is the default path to the server database
	DefaultDatabasePath = "shared/resources/server.db"
)

// Factory provides a centralized way to create repository instances
type Factory struct {
	conn   *sql.DB
	logger *slog.Logger
}

// createDatabaseWithSchema creates a new SQLite database file and applies the schema
func createDatabaseWithSchema(dbPath string) error {
	// Create parent directories if they don't exist
	dir := filepath.Dir(dbPath)

	fmt.Print("Creating database directory: " + dir + "\n")

	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create database directory: %w", err)
	}

	conn, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return fmt.Errorf("failed to create database: %w", err)
	}
	defer conn.Close()

	// Execute the embedded schema
	if _, err := conn.Exec(config.SchemaSQL); err != nil {
		return fmt.Errorf("failed to create schema: %w", err)
	}

	return nil
}

// NewFactory creates a new repository factory
func NewFactory(dbPath string, logger *slog.Logger) (*Factory, error) {
	// Use default path if not provided
	if dbPath == "" {
		dbPath = DefaultDatabasePath
	}

	var err error

	logger.Debug("Creating database directory", "path", dbPath)

	// Create database with schema if it doesn't exist
	if err := createDatabaseWithSchema(dbPath); err != nil {
		return nil, fmt.Errorf("failed to initialize database: %w", err)
	}

	// Check if the database file exists
	if _, err := os.Stat(dbPath); err != nil {
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

	return &Factory{conn: conn, logger: logger}, nil
}

// NewUserRepository creates a new UserRepository instance
func (f *Factory) NewUserRepository() UserRepository {
	return NewSQLiteUserRepository(f.conn)
}

// Close closes the database connection
func (f *Factory) Close() error {
	return f.conn.Close()
}

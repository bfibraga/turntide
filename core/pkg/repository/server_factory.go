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
	"log/slog"
	"os"
	"path/filepath"

	config "github.com/bfibraga/turntide/core/internal/db/config/schemas"
	_ "modernc.org/sqlite"
)

// ServerFactory creates repositories for the server domain
type ServerFactory struct {
	*Factory
}

func NewServerFactory(dbPath string, logger *slog.Logger) (*ServerFactory, error) {
	if dbPath == "" {
		dbPath = DefaultServerDBPath
	}

	dir := filepath.Dir(dbPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create database directory: %w", err)
	}

	dbExists := true
	if _, err := os.Stat(dbPath); os.IsNotExist(err) {
		dbExists = false
	}

	if !dbExists {
		if err := createServerDatabase(dbPath); err != nil {
			return nil, fmt.Errorf("failed to create database: %w", err)
		}
	}

	conn, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	if err := conn.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &ServerFactory{
		Factory: &Factory{conn: conn, logger: logger},
	}, nil
}

func createServerDatabase(dbPath string) error {
	conn, err := sql.Open("sqlite", dbPath)
	if err != nil {
		return fmt.Errorf("failed to create database: %w", err)
	}
	defer conn.Close()

	if _, err := conn.Exec(config.ServerSchemaSQL); err != nil {
		return fmt.Errorf("failed to create schema: %w", err)
	}

	return nil
}

func (f *ServerFactory) CreateUserRepository() UserRepository {
	return NewUserRepository(f.Factory.GetDBTX())
}

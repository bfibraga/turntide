# Refactor Common Code - Abstract Factory Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Consolidate duplicated repository code between server and fetcher using Abstract Factory pattern in core/

**Architecture:** Create abstract factory interface in core/pkg/repository/ with concrete implementations for Cards (fetcher uses) and Server (server uses). Both modules will import from core instead of maintaining duplicate code.

**Tech Stack:** Go 1.26, sqlite3, sqlc

---

## File Structure

```
core/pkg/repository/
├── interfaces.go      # NEW: CardRepository, SetRepository, UserRepository interfaces
├── factory.go         # MODIFY: Add abstract RepositoryFactory interface
├── cards_factory.go   # NEW: CardsFactory implementation
└── server_factory.go  # NEW: ServerFactory implementation
```

---

## Task 1: Create Repository Interfaces in Core

**Files:**
- Create: `core/pkg/repository/interfaces.go`

- [ ] **Step 1: Create interfaces.go with all repository interfaces**

```go
package repository

import (
    "context"

    "github.com/bfibraga/turntide/core/internal/db/cards"
    "github.com/bfibraga/turntide/core/internal/db/server"
)

// CardRepository defines the interface for card data access
type CardRepository interface {
    GetByUuid(ctx context.Context, uuid string) (*cards.Card, error)
    GetByName(ctx context.Context, name string) ([]*cards.Card, error)
    GetBySetCode(ctx context.Context, setCode string) ([]*cards.Card, error)
    ListAll(ctx context.Context, limit, offset int32) ([]*cards.Card, error)
    Count(ctx context.Context) (int64, error)
    Close() error
}

// SetRepository defines the interface for set data access
type SetRepository interface {
    GetByCode(ctx context.Context, code string) (*cards.Set, error)
    GetByName(ctx context.Context, name string) ([]*cards.Set, error)
    ListAll(ctx context.Context, limit, offset int32) ([]*cards.Set, error)
    Count(ctx context.Context) (int64, error)
    Close() error
}

// UserRepository defines the interface for user data access
type UserRepository interface {
    Create(ctx context.Context, username, password string) (*server.User, error)
    GetByUsername(ctx context.Context, username string) (*server.User, error)
    VerifyPassword(ctx context.Context, username, password string) (bool, error)
    Close() error
}
```

- [ ] **Step 2: Commit**

```bash
git add core/pkg/repository/interfaces.go
git commit -m "feat(core): add repository interfaces for Card, Set, User"
```

---

## Task 2: Create Abstract Factory Interface

**Files:**
- Modify: `core/pkg/repository/factory.go`

- [ ] **Step 1: Read current factory.go**

```bash
cat core/pkg/repository/factory.go
```

- [ ] **Step 2: Replace with abstract factory interface**

```go
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
    "log/slog"
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
        return nil, ErrDBPathRequired
    }

    conn, err := sql.Open("sqlite3", dbPath)
    if err != nil {
        return nil, err
    }

    if err := conn.Ping(); err != nil {
        return nil, err
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
```

- [ ] **Step 3: Commit**

```bash
git add core/pkg/repository/factory.go
git commit -m "feat(core): convert Factory to abstract RepositoryFactory interface"
```

---

## Task 3: Create CardsFactory Implementation

**Files:**
- Create: `core/pkg/repository/cards_factory.go`

- [ ] **Step 1: Create cards_factory.go**

```go
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

    "github.com/bfibraga/turntide/core/internal/db/cards"
    "github.com/bfibraga/turntide/core/internal/db/config/schemas"

    _ "github.com/mattn/go-sqlite3"
)

type CardsFactory struct {
    *Factory
}

func NewCardsFactory(dbPath string, logger *slog.Logger) (*CardsFactory, error) {
    if dbPath == "" {
        dbPath = DefaultCardsDBPath
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
        if err := createCardsDatabase(dbPath); err != nil {
            return nil, fmt.Errorf("failed to create database: %w", err)
        }
    }

    conn, err := sql.Open("sqlite3", dbPath)
    if err != nil {
        return nil, fmt.Errorf("failed to open database: %w", err)
    }

    if err := conn.Ping(); err != nil {
        return nil, fmt.Errorf("failed to ping database: %w", err)
    }

    return &CardsFactory{
        Factory: &Factory{conn: conn, logger: logger},
    }, nil
}

func createCardsDatabase(dbPath string) error {
    conn, err := sql.Open("sqlite3", dbPath)
    if err != nil {
        return fmt.Errorf("failed to create database: %w", err)
    }
    defer conn.Close()

    if _, err := conn.Exec(schemas.CardsSchemaSQL); err != nil {
        return fmt.Errorf("failed to create schema: %w", err)
    }

    return nil
}

func (f *CardsFactory) CreateCardRepository() CardRepository {
    return cards.New(f.Factory.GetDBTX())
}

func (f *CardsFactory) CreateSetRepository() SetRepository {
    return cards.New(f.Factory.GetDBTX())
}
```

- [ ] **Step 2: Commit**

```bash
git add core/pkg/repository/cards_factory.go
git commit -m "feat(core): add CardsFactory implementation"
```

---

## Task 4: Create ServerFactory Implementation

**Files:**
- Create: `core/pkg/repository/server_factory.go`

- [ ] **Step 1: Create server_factory.go**

```go
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

    "github.com/bfibraga/turntide/core/internal/db/config/schemas"
    "github.com/bfibraga/turntide/core/internal/db/server"

    _ "github.com/mattn/go-sqlite3"
)

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

    conn, err := sql.Open("sqlite3", dbPath)
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
    conn, err := sql.Open("sqlite3", dbPath)
    if err != nil {
        return fmt.Errorf("failed to create database: %w", err)
    }
    defer conn.Close()

    if _, err := conn.Exec(schemas.ServerSchemaSQL); err != nil {
        return fmt.Errorf("failed to create schema: %w", err)
    }

    return nil
}

func (f *ServerFactory) CreateUserRepository() UserRepository {
    return server.New(f.Factory.GetDBTX())
}
```

- [ ] **Step 2: Commit**

```bash
git add core/pkg/repository/server_factory.go
git commit -m "feat(core): add ServerFactory implementation"
```

---

## Task 5: Update Fetcher to Use Core Factory

**Files:**
- Modify: `fetcher/internal/repository/factory.go`
- Modify: `fetcher/cmd/db.go`
- Modify: `fetcher/internal/service/card.go` (check imports)
- Modify: `fetcher/internal/service/set.go` (check imports)

- [ ] **Step 1: Update fetcher repository factory to use core**

Replace `fetcher/internal/repository/factory.go` with:

```go
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
    "log/slog"

    "github.com/bfibraga/turntide/core/pkg/repository"
)

type CardsFactory struct {
    factory *repository.CardsFactory
}

func NewCardsFactory(dbPath string, logger *slog.Logger) (*CardsFactory, error) {
    factory, err := repository.NewCardsFactory(dbPath, logger)
    if err != nil {
        return nil, err
    }
    return &CardsFactory{factory: factory}, nil
}

func (f *CardsFactory) NewCardRepository() CardRepository {
    return f.factory.CreateCardRepository()
}

func (f *CardsFactory) NewSetRepository() SetRepository {
    return f.factory.CreateSetRepository()
}

func (f *CardsFactory) Close() error {
    return f.factory.Close()
}
```

- [ ] **Step 2: Update fetcher/cmd/db.go to use core factory**

Read and update the db.go command to use the new factory pattern.

- [ ] **Step 3: Run tests**

```bash
cd fetcher && go build ./... && go test ./...
```

- [ ] **Step 4: Commit**

```bash
git add fetcher/internal/repository/factory.go fetcher/cmd/db.go
git commit -m "refactor(fetcher): use core repository factory"
```

---

## Task 6: Update Server to Use Core Factory

**Files:**
- Modify: `server/internal/server/repository/factory.go`
- Modify: `server/main.go`

- [ ] **Step 1: Update server repository factory to use core**

Replace `server/internal/server/repository/factory.go` with:

```go
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
    "log/slog"

    "github.com/bfibraga/turntide/core/pkg/repository"
)

type Factory struct {
    factory *repository.ServerFactory
}

func NewFactory(dbPath string, logger *slog.Logger) (*Factory, error) {
    factory, err := repository.NewServerFactory(dbPath, logger)
    if err != nil {
        return nil, err
    }
    return &Factory{factory: factory}, nil
}

func (f *Factory) NewUserRepository() UserRepository {
    return f.factory.CreateUserRepository()
}

func (f *Factory) Close() error {
    return f.factory.Close()
}
```

- [ ] **Step 2: Update server/main.go if needed**

Check and update main.go to use new factory pattern.

- [ ] **Step 3: Run tests**

```bash
cd server && go build ./... && go test ./...
```

- [ ] **Step 4: Commit**

```bash
git add server/internal/server/repository/factory.go server/main.go
git commit -m "refactor(server): use core repository factory"
```

---

## Task 7: Remove Duplicate Code

**Files to remove:**
- `fetcher/internal/db/` (entire directory)
- `server/internal/server/db/` (entire directory)

- [ ] **Step 1: Remove fetcher duplicate db code**

```bash
rm -rf fetcher/internal/db
```

- [ ] **Step 2: Remove server duplicate db code**

```bash
rm -rf server/internal/server/db
```

- [ ] **Step 3: Run full test suite**

```bash
go build ./... && go test ./...
```

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "refactor: remove duplicate db code, use core"
```

---

## Task 8: Verify Final Build

- [ ] **Step 1: Run full build and test**

```bash
make all && make test
```

- [ ] **Step 2: Verify go workspace compiles**

```bash
go build ./fetcher && go build ./server && go build ./core
```

---

**Plan complete.**

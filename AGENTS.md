# AGENTS.md - Turntide Development Guide

## Project Overview

Turntide is a multiplayer card game with a Godot 4.6 client, Go backend server, and fetcher service for card data.

**Tech Stack:**
- **Client:** Godot 4.6, GDScript, godobuf (protobuf for Godot)
- **Server:** Go 1.26, SQLite, WebSockets, JWT
- **Fetcher:** Go CLI (Cobra) for downloading card data from Scryfall API

---

## Build Commands

### Go Backend

```bash
# Build all components
make all

# Build individual components
make fetcher   # Build fetcher binary
make server    # Build server binary

# Run tests
make test      # Run all tests
go test ./...  # Same as above

# Run a single test
go test -run TestFunctionName ./fetcher/test
go test -v -run TestFunctionName ./fetcher/test

# Run tests in short mode (skip integration tests)
go test -short ./...

# Run with coverage
go test -cover ./...
```

### Code Generation

```bash
# Generate SQLC bindings
make sql

# Generate protobuf Go bindings
make proto

# Full regeneration
make setup proto sql fetcher server
```

### Godot Client

The Godot client is built via the Godot editor (4.6). Build from editor or use:

```bash
# Requires godot in PATH
godot --headless --export-release "Linux/X11" export/
```

---

## Code Style Guidelines

### Go (Backend)

**Imports:**
```go
import (
    "context"
    "fmt"

    "github.com/spf13/cobra"
    "github.com/spf13/viper"

    "github.com/bfibraga/turntide/fetcher/internal/models"
    "github.com/bfibraga/turntide/fetcher/internal/repository"
)
```
- Standard library first, then third-party, then internal
- Group imports with blank line between groups

**Naming:**
- `PascalCase` for exported functions/types
- `camelCase` for unexported functions/variables
- Interfaces: `Repository`, `Service`, `Handler`
- Implementations: `cardRepository`, `cardService`

**Types:**
- Use explicit types, avoid `var x` without type
- Context as first parameter: `func(ctx context.Context, ...)`
- Return errors as last value: `func(...) (Result, error)`

**Error Handling:**
```go
// Always handle errors explicitly
if err != nil {
    return nil, fmt.Errorf("failed to get cards: %w", err)
}

// Use wrapped errors with %w
fmt.Errorf("operation failed: %w", err)
```

**Project Structure:**
```
fetcher/
  cmd/           # Cobra commands
  internal/
    db/          # Generated SQLC code
    models/      # Domain models
    repository/  # Repository pattern (interface + impl)
    service/     # Business logic
    parsers/     # Data parsing
    download/    # Download logic
  test/          # Test files

server/
  internal/
    server/      # HTTP/WebSocket server
    relay/       # Relay logic
  pkg/           # Public packages (protobuf)

shared/
  *.proto        # Protocol buffer definitions
```

**Repository Pattern:**
```go
// Interface in internal/repository/card.go
type CardRepository interface {
    ListAll(ctx context.Context, limit, offset int) ([]*models.Card, error)
    Search(ctx context.Context, filter *models.CardFilter) ([]*models.Card, error)
}

// Implementation in internal/repository/card_impl.go
type cardRepository struct {
    db *sql.DB
}

func NewCardRepository(db *sql.DB) CardRepository {
    return &cardRepository{db: db}
}
```

**License Header:**
Every Go file should have MIT license header:
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
```

### GDScript (Godot Client)

**Typing (Required):**
```gdscript
extends Node

var _card_cache: Dictionary = {}
var _is_loading: bool = false

func load_card(card_id: String) -> CardData:
    pass

func _process(delta: float) -> void:
    pass
```

**Signal Usage:**
```gdscript
signal card_loaded(card_data: CardData)

func _on_card_loaded(card: CardData) -> void:
    pass
```

**Node Naming:**
- PascalCase for nodes/scenes
- Prefix internal nodes with underscore for private

---

## Testing Guidelines

### Go Tests

```go
func TestCardService_GetAllCards(t *testing.T) {
    tests := []struct {
        name     string
        filter   *models.CardFilter
        wantLen  int
        wantErr  bool
    }{
        {
            name:    "default filter",
            filter:  nil,
            wantLen: 1000,
            wantErr: false,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Test logic here
        })
    }
}
```

**Test Locations:**
- Tests go in `*_test.go` files in same package or `test/` subdirectory
- Integration tests use `testing.Short()` to skip in CI

---

## Database

- SQLite for both fetcher and server
- SQLC for type-safe SQL queries
- Generated files in `internal/db/` - do not edit manually

---

## Proto Files

- Define in `shared/` directory
- Generate Go with: `make proto`
- Generate Godot with: Godot editor + godobuf addon

---

## Key Files

| Path | Purpose |
|------|---------|
| `Makefile` | Build automation |
| `go.mod` | Go dependencies |
| `fetcher/` | Card data fetcher CLI |
| `server/` | Game server (WebSocket) |
| `client/` | Godot 4.6 game client |
| `shared/` | Proto definitions, resources |
| `shared/resources/bin/` | Built binaries output |

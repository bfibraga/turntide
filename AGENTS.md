# AGENTS.md

## Branch Convention

GitHub Flow: `main` is the production/tested branch. Create feature branches off `main`, merge back via PR.

## Testing

Unit tests must be placed in a `test/` folder (not alongside source files, not in `test/`).

- Run all Go tests: `make test` (runs `go test ./...`)
- Fetcher has additional integration tests: `bash fetcher/test/run_tests.sh`

## Build & Code Generation

```bash
make              # setup + proto + fetcher + server
make test         # run all tests
make sql          # regenerate sqlc bindings (runs on schema changes)
make proto        # regenerate protobuf bindings (runs after editing shared/*.proto)
```

sqlc config: `fetcher/internal/db/config/sqlc.yaml` and `server/internal/server/db/config/sqlc.yaml`
Protobuf definitions: `shared/*.proto`

## Project Structure

| Directory  | Purpose                                                               |
| ---------- | --------------------------------------------------------------------- |
| `client/`  | Godot game client (GDScript, uses godot-sqlite and godobuf addons)    |
| `server/`  | Go WebSocket server                                                   |
| `fetcher/` | Go CLI tool for fetching MTG card data (MTGJSON, Scryfall images)     |
| `shared/`  | Protobuf definitions, SQLite databases, binaries, printed card images |

## Artifacts & Ignored Paths

- Build binaries: `shared/resources/bin/` (gitignored, use `make fetcher` / `make server`)
- Printed card images: `shared/resources/printings/` (gitignored)
- Databases: `shared/resources/*.db` (gitignored)

## Key Tools

- **sqlc** for type-safe SQLite queries
- **protoc** + godobuf for client-server protocol
- **Cobra** for fetcher CLI commands

# Server Test Improvements Design

## Goal

Improve `server/test/` by consolidating mocks, introducing table-driven tests, and adding missing edge case coverage.

## 1. Consolidate Mocks

Replace three separate mock types (`MockInLobbyClient`, `mockClient`, `mockLobbyClient`) with a single `fakeClient` in a shared test util file.

`fakeClient` satisfies `components.ClientInterfacer` and tracks:
- `sentMsgs []packets.Msg` — all packets sent via `SocketSend`
- `state components.ClientStateHandler` — last state set via `SetState`
- `closed bool` — whether `Close()` was called
- `peerMsgs []peerMsg` — messages sent via `PassToPeer` (for broadcast verification)

Add assertion helpers:
- `SentPacketOfType(t, type) packets.Msg` — returns first sent packet of given type, fails test if not found
- `SentPacketCount() int` — returns number of sent packets
- `StateName() string` — delegates to state handler if set

**Files affected:**
- `server/test/internal/server/states/util.go` — define `fakeClient`, remove `MockInLobbyClient`
- `server/test/internal/server/components/registry_test.go` — use `fakeClient` instead of `mockClient`
- `server/test/internal/server/components/broker_test.go` — use `fakeClient` instead of `mockClient`
- `server/test/internal/server/components/lobby_registry_test.go` — use `fakeClient` instead of `mockLobbyClient`
- `server/test/internal/server/states/in_lobby_test.go` — use `fakeClient` instead of `MockInLobbyClient`
- `server/test/internal/server/states/authenticated_test.go` — use `fakeClient` instead of `MockInLobbyClient`
- `server/test/internal/server/states/in_game_test.go` — use `fakeClient` instead of `MockInLobbyClient`

## 2. Table-Driven Tests

Refactor repeated test patterns in `lobby_registry_test.go` into table-driven tests:

| Current tests | Table name |
|--------------|------------|
| `TestJoinPrivateLobbyNoPassword`, `TestJoinPrivateLobbyWrongPassword`, `TestJoinPrivateLobbyCorrectPassword` | `TestJoinLobbyPassword` |
| `TestStartGameNotHost`, `TestStartGameNotAllReady`, `TestStartGameSuccess` | `TestStartGame` |

Add `TestLeaveLobby` table to cover: normal leave, leave-when-not-in-lobby, leave-last-player (TTL).

For state tests, use subtests with `t.Run` for clearer failure output.

## 3. Missing Edge Case Tests

### `in_lobby_test.go`

| Test | What it covers |
|------|---------------|
| `TestInLobbyOnEnterLobbyNotFound` | `OnEnter` when `FindLobby` fails (line 51 error path) |
| `TestInLobbyLeaveError` | `handleLeave` when `LeaveLobby` returns error (e.g., player not in lobby) |
| `TestInLobbyReadyError` | `handleReady` when `SetReady` fails (invalid player ID) |
| `TestInLobbyStartErrorNotHost` | `handleStart` when sender is not host |
| `TestInLobbyStartErrorNotAllReady` | `handleStart` when not all players are ready |
| `TestInLobbyOnExitNilClient` | `OnExit` when `client` is nil |
| `TestInLobbyOnExitNilLobbyReg` | `OnExit` when `lobbyReg` is nil |
| `TestInLobbyOnExitLeavesLobby` | `OnExit` actually calls `LeaveLobby` for the client |

### `authenticated_test.go`

| Test | What it covers |
|------|---------------|
| `TestAuthenticatedHandleUnknownMessage` | `HandleMessage` with unrecognized packet type |
| `TestAuthenticatedCreateLobbyInvalid` | Creating lobby with invalid params (e.g., empty name, maxPlayers < 1) |

### `broker_test.go`

| Test | What it covers |
|------|---------------|
| `TestBroadcastPacketContent` | Verify full packet content, not just `SenderId` |
| `TestBroadcastMultiplePackets` | Send multiple packets, verify all arrive on `BroadcastChan` |

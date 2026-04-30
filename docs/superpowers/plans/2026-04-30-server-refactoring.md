# Server Refactoring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor server code organization by moving objects package, extracting interfaces, and breaking Hub into focused components.

**Architecture:** Component-based reorganization. Move `internal/objects/` into `server/objects/`, extract interfaces to `interfaces.go`, create `ClientRegistry` and `MessageBroker` components, slim down Hub to orchestrator role.

**Tech Stack:** Go, gorilla/websocket, protobuf, SQLite

---

### Task 1: Create interfaces.go

**Files:**
- Create: `server/internal/server/interfaces.go`
- Reference: `server/internal/server/hub.go:12-44` (existing interfaces)

- [ ] **Step 1: Create interfaces.go with extracted interfaces**

```go
package server

import (
	"github.com/bfibraga/turntide/server/internal/objects"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

// ClientInterfacer defines the interface for clients in the hub
type ClientInterfacer interface {
	// Id returns the client's unique identifier
	Id() uint64
	// ProcessPacket processes a packet from the hub
	ProcessPacket(senderId uint64, message packets.Msg)

	Initialize(id uint64)
	SocketSend(message packets.Msg)
	SocketSendAs(senderId uint64, message packets.Msg)

	PassToPeer(message packets.Msg, peerId uint64)
	Broadcast(message packets.Msg)
	ReadPump()
	WritePump()

	SetState(state ClientStateHandler)

	Close()
}

// ClientStateHandler defines the interface for a state machine to process client messages
type ClientStateHandler interface {
	Name() string

	// Inject the client into the state handler
	SetClient(client ClientInterfacer)

	OnEnter()
	HandleMessage(senderId uint64, message packets.Msg)

	// Cleanup the state handler and perform any last actions
	OnExit()
}
```

- [ ] **Step 2: Verify file compiles**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go build ./server/...`
Expected: Clean build with no errors

- [ ] **Step 3: Commit**

```bash
git add server/internal/server/interfaces.go
git commit -m "refactor: extract interfaces to dedicated file"
```

---

### Task 2: Create ClientRegistry component

**Files:**
- Create: `server/internal/server/components/registry.go`
- Modify: `server/internal/server/hub.go` (will update in Task 4)
- Test: `server/internal/server/components/registry_test.go`

- [ ] **Step 1: Write the failing test**

```go
package components

import (
	"testing"

	"github.com/bfibraga/turntide/server/internal/server"
)

type mockClient struct {
	id uint64
}

func (m *mockClient) Id() uint64 { return m.id }
func (m *mockClient) ProcessPacket(senderId uint64, message interface{}) {}
func (m *mockClient) Initialize(id uint64)                             {}
func (m *mockClient) SocketSend(message interface{})                    {}
func (m *mockClient) SocketSendAs(senderId uint64, message interface{}) {}
func (m *mockClient) PassToPeer(message interface{}, peerId uint64)     {}
func (m *mockClient) Broadcast(message interface{})                    {}
func (m *mockClient) ReadPump()                                        {}
func (m *mockClient) WritePump()                                       {}
func (m *mockClient) SetState(state server.ClientStateHandler)          {}
func (m *mockClient) Close()                                           {}

func TestAddClient(t *testing.T) {
	registry := NewClientRegistry()
	client := &mockClient{}

	id := registry.Add(client)

	if id == 0 {
		t.Error("expected non-zero ID")
	}

	retrieved, ok := registry.Get(id)
	if !ok {
		t.Error("expected to retrieve client")
	}
	if retrieved != client {
		t.Error("retrieved client should match added client")
	}
}

func TestDeleteClient(t *testing.T) {
	registry := NewClientRegistry()
	client := &mockClient{}

	id := registry.Add(client)
	registry.Delete(id)

	_, ok := registry.Get(id)
	if ok {
		t.Error("expected client to be deleted")
	}
}

func TestForEach(t *testing.T) {
	registry := NewClientRegistry()
	client1 := &mockClient{}
	client2 := &mockClient{}

	registry.Add(client1)
	registry.Add(client2)

	count := 0
	registry.ForEach(func(id uint64, c server.ClientInterfacer) {
		count++
	})

	if count != 2 {
		t.Errorf("expected 2 clients, got %d", count)
	}
}

func TestSize(t *testing.T) {
	registry := NewClientRegistry()

	if registry.Size() != 0 {
		t.Error("expected empty registry")
	}

	registry.Add(&mockClient{})
	registry.Add(&mockClient{})

	if registry.Size() != 2 {
		t.Errorf("expected 2 clients, got %d", registry.Size())
	}
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/internal/server/components/ -v`
Expected: FAIL - `NewClientRegistry` not defined

- [ ] **Step 3: Write minimal implementation**

```go
package components

import (
	"github.com/bfibraga/turntide/server/internal/objects"
	"github.com/bfibraga/turntide/server/internal/server"
)

type ClientRegistry struct {
	clients *objects.SharedCollection[server.ClientInterfacer]
}

func NewClientRegistry() *ClientRegistry {
	return &ClientRegistry{
		clients: objects.NewSharedCollection[server.ClientInterfacer](),
	}
}

func (r *ClientRegistry) Add(client server.ClientInterfacer) uint64 {
	return r.clients.Add(client)
}

func (r *ClientRegistry) Get(id uint64) (server.ClientInterfacer, bool) {
	return r.clients.Get(id)
}

func (r *ClientRegistry) Delete(id uint64) {
	r.clients.Delete(id)
}

func (r *ClientRegistry) ForEach(f func(id uint64, client server.ClientInterfacer)) {
	r.clients.ForEach(f)
}

func (r *ClientRegistry) Size() int {
	return r.clients.Size()
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/internal/server/components/ -v`
Expected: PASS - all tests green

- [ ] **Step 5: Commit**

```bash
git add server/internal/server/components/registry.go server/internal/server/components/registry_test.go
git commit -m "feat: add ClientRegistry component"
```

---

### Task 3: Create MessageBroker component

**Files:**
- Create: `server/internal/server/components/broker.go`
- Modify: `server/internal/server/hub.go` (will update in Task 4)
- Test: `server/internal/server/components/broker_test.go`

- [ ] **Step 1: Write the failing test**

```go
package components

import (
	"testing"

	"github.com/bfibraga/turntide/server/pkg/packets"
)

func TestBroadcast(t *testing.T) {
	broker := NewMessageBroker()

	received := make(chan *packets.Packet, 1)
	go func() {
		packet := <-broker.BroadcastChan
		received <- packet
	}()

	broker.Broadcast(1, packets.NewId(1))
	packet := <-received

	if packet.SenderId != 1 {
		t.Errorf("expected SenderId 1, got %d", packet.SenderId)
	}
}

func TestRegister(t *testing.T) {
	broker := NewMessageBroker()

	// Create a mock client that satisfies ClientInterfacer
	client := &mockClient{id: 1}

	broker.Register(client)

	select {
	case c := <-broker.RegisterChan:
		if c.Id() != 1 {
			t.Errorf("expected client id 1, got %d", c.Id())
		}
	default:
		t.Error("expected client on RegisterChan")
	}
}

func TestUnregister(t *testing.T) {
	broker := NewMessageBroker()

	client := &mockClient{id: 1}

	broker.Unregister(client)

	select {
	case c := <-broker.UnregisterChan:
		if c.Id() != 1 {
			t.Errorf("expected client id 1, got %d", c.Id())
		}
	default:
		t.Error("expected client on UnregisterChan")
	}
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/internal/server/components/ -v`
Expected: FAIL - `NewMessageBroker` not defined

- [ ] **Step 3: Write minimal implementation**

```go
package components

import (
	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type MessageBroker struct {
	BroadcastChan  chan *packets.Packet
	RegisterChan   chan server.ClientInterfacer
	UnregisterChan chan server.ClientInterfacer
}

func NewMessageBroker() *MessageBroker {
	return &MessageBroker{
		BroadcastChan:  make(chan *packets.Packet),
		RegisterChan:   make(chan server.ClientInterfacer),
		UnregisterChan: make(chan server.ClientInterfacer),
	}
}

func (b *MessageBroker) Broadcast(senderId uint64, msg packets.Msg) {
	b.BroadcastChan <- packets.NewPacket(senderId, msg)
}

func (b *MessageBroker) Register(client server.ClientInterfacer) {
	b.RegisterChan <- client
}

func (b *MessageBroker) Unregister(client server.ClientInterfacer) {
	b.UnregisterChan <- client
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/internal/server/components/ -v`
Expected: PASS - all tests green

- [ ] **Step 5: Commit**

```bash
git add server/internal/server/components/broker.go server/internal/server/components/broker_test.go
git commit -m "feat: add MessageBroker component"
```

---

### Task 4: Update Hub to use new components

**Files:**
- Modify: `server/internal/server/hub.go`
- Reference: `server/internal/server/hub.go:46-100` (current Hub implementation)

- [ ] **Step 1: Write updated Hub implementation**

```go
package server

import (
	"log/slog"
	"net/http"

	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/internal/server/user"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type Hub struct {
	Logger      *slog.Logger
	UserService *user.Service
	Registry    *components.ClientRegistry
	Broker      *components.MessageBroker
}

func NewHub(logger *slog.Logger, userService *user.Service) *Hub {
	return &Hub{
		Logger:      logger,
		UserService: userService,
		Registry:    components.NewClientRegistry(),
		Broker:      components.NewMessageBroker(),
	}
}

func (h *Hub) Run() {
	h.Logger.Info("Waiting for connections...")
	for {
		select {
		case client := <-h.Broker.RegisterChan:
			id := h.Registry.Add(client)
			client.Initialize(id)
		case client := <-h.Broker.UnregisterChan:
			h.Registry.Delete(client.Id())
		case packet := <-h.Broker.BroadcastChan:
			h.Registry.ForEach(func(id uint64, client ClientInterfacer) {
				if id != packet.SenderId {
					client.ProcessPacket(packet.SenderId, packet.Msg)
				}
			})
		}
	}
}

func (h *Hub) Serve(getNewClient func(*Hub, http.ResponseWriter, *http.Request) (ClientInterfacer, error), writer http.ResponseWriter, request *http.Request) {
	client, err := getNewClient(h, writer, request)

	if err != nil {
		h.Logger.Error("Failed to create client", "error", err)
		return
	}

	h.Broker.Register(client)

	h.Logger.Info("New client connected", "address", request.RemoteAddr)
	go client.WritePump()
	go client.ReadPump()
}
```

- [ ] **Step 2: Remove old interfaces from hub.go**

The interfaces are now in `interfaces.go`, so remove the interface definitions from `hub.go` (lines 12-44 from original).

- [ ] **Step 3: Run tests to verify build still works**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go build ./server/...`
Expected: Clean build

- [ ] **Step 4: Run existing tests**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/... -v`
Expected: All tests pass

- [ ] **Step 5: Commit**

```bash
git add server/internal/server/hub.go
git commit -m "refactor: slim down Hub with components"
```

---

### Task 5: Move objects package into server/

**Files:**
- Move: `server/internal/objects/` → `server/internal/server/objects/`
- Modify: All import paths referencing `github.com/bfibraga/turntide/server/internal/objects`

- [ ] **Step 1: Find all files importing objects package**

Run: `cd /home/bfbraga/Documents/Programming/turntide && grep -r "internal/objects" server/ --include="*.go"`
Expected: List of files with import paths to update

- [ ] **Step 2: Move the objects directory**

```bash
cd /home/bfbraga/Documents/Programming/turntide
git mv server/internal/objects server/internal/server/objects
```

- [ ] **Step 3: Update import paths in all affected files**

Update imports from:
```go
"github.com/bfibraga/turntide/server/internal/objects"
```
To:
```go
"github.com/bfibraga/turntide/server/internal/server/objects"
```

Files to update:
- `server/internal/server/hub.go`
- `server/internal/server/clients/websocket.go`
- Any other files found in Step 1

- [ ] **Step 4: Run build to verify changes**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go build ./server/...`
Expected: Clean build

- [ ] **Step 5: Run all tests**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/... -v`
Expected: All tests pass

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "refactor: move objects package into server/"
```

---

### Task 6: Update main.go to use new paths

**Files:**
- Modify: `server/main.go`

- [ ] **Step 1: Update import paths in main.go**

```go
package main

import (
	"database/sql"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"runtime/debug"

	_ "github.com/mattn/go-sqlite3"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/clients"
	"github.com/bfibraga/turntide/server/internal/server/user"
)
```

Note: `main.go` already imports from `internal/server/`, so only need to verify nothing else needs updating.

- [ ] **Step 2: Run build to verify**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go build ./server/...`
Expected: Clean build

- [ ] **Step 3: Run all tests**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./server/... -v`
Expected: All tests pass

- [ ] **Step 4: Commit (if any changes were needed)**

```bash
git add server/main.go
git commit -m "refactor: update main.go imports after restructure"
```

---

### Task 7: Clean up and verify

**Files:**
- All files in `server/`

- [ ] **Step 1: Remove old interfaces from hub.go if not already done**

Verify `hub.go` no longer contains the `ClientInterfacer` and `ClientStateHandler` interface definitions.

- [ ] **Step 2: Run full test suite**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go test ./... -v`
Expected: All tests pass

- [ ] **Step 3: Verify build is clean**

Run: `cd /home/bfbraga/Documents/Programming/turntide && go build ./...`
Expected: Clean build, no errors

- [ ] **Step 4: Check for any remaining references to old paths**

Run: `cd /home/bfbraga/Documents/Programming/turntide && grep -r "internal/objects" . --include="*.go"`
Expected: No results (all references updated)

- [ ] **Step 5: Final commit (if any cleanup needed)**

```bash
git add -A
git commit -m "refactor: final cleanup after server code reorganization"
```

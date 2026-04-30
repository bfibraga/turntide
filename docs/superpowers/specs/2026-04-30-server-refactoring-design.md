# Server Code Refactoring Design

**Date:** 2026-04-30
**Status:** Approved

## Goal

Improve code organization in the `server/` directory by reorganizing packages, clarifying interfaces, and breaking up the Hub into focused, testable components.

## Current State

The server codebase has grown with some organizational issues:
- `internal/objects/` sits outside `server/` but is imported by it
- `Hub` struct mixes interface definitions with orchestration logic
- Unclear boundaries between components

### Current Structure
```
server/
├── main.go
├── internal/
│   ├── server/
│   │   ├── hub.go             # Hub + interfaces
│   │   ├── clients/
│   │   ├── states/
│   │   ├── user/
│   │   ├── db/
│   │   └── validation/
│   └── objects/              # Should be inside server/
│       ├── gameObjects.go
│       └── sharedCollections.go
├── pkg/packets/
└── test/
```

## Design

### 1. Package Structure

Move `internal/objects/` into `internal/server/objects/` and extract interfaces into a dedicated file. Create new `components/` directory for extracted Hub components.

```
server/
├── main.go                    # Entry point (unchanged)
├── internal/
│   └── server/
│       ├── hub.go             # Hub orchestrator (slimmed down)
│       ├── interfaces.go      # Extracted interfaces (new)
│       ├── objects/          # Moved from internal/objects/
│       │   ├── gameObjects.go
│       │   └── sharedCollections.go
│       ├── clients/          # WebSocket client (unchanged)
│       │   └── websocket.go
│       ├── states/           # State machine (unchanged)
│       │   ├── connected.go
│       │   └── authenticated.go
│       ├── user/             # User auth (unchanged)
│       │   ├── service.go
│       │   └── repository.go
│       ├── db/               # Database (unchanged)
│       ├── validation/       # Validation (unchanged)
│       └── components/       # New: extracted Hub components
│           ├── registry.go   # ClientRegistry
│           └── broker.go     # MessageBroker
├── pkg/
│   └── packets/              # Protobuf (unchanged)
└── test/
```

### 2. Interfaces (interfaces.go)

Extract `ClientInterfacer` and `ClientStateHandler` interfaces from `hub.go` into a dedicated `interfaces.go` file.

```go
// ClientInterfacer defines the interface for clients in the hub
type ClientInterfacer interface {
    Id() uint64
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

// ClientStateHandler defines the state machine interface
type ClientStateHandler interface {
    Name() string
    SetClient(client ClientInterfacer)
    OnEnter()
    HandleMessage(senderId uint64, message packets.Msg)
    OnExit()
}
```

### 3. Extracted Components

#### ClientRegistry (components/registry.go)

Manages the collection of connected clients, replacing direct use of `SharedCollection` in Hub.

```go
type ClientRegistry struct {
    clients *objects.SharedCollection[ClientInterfacer]
}

func NewClientRegistry() *ClientRegistry
func (r *ClientRegistry) Add(client ClientInterfacer) uint64
func (r *ClientRegistry) Get(id uint64) (ClientInterfacer, bool)
func (r *ClientRegistry) Delete(id uint64)
func (r *ClientRegistry) ForEach(f func(id uint64, client ClientInterfacer))
func (r *ClientRegistry) Size() int
```

#### MessageBroker (components/broker.go)

Handles the channels for broadcast, register, and unregister operations.

```go
type MessageBroker struct {
    BroadcastChan  chan *packets.Packet
    RegisterChan   chan ClientInterfacer
    UnregisterChan chan ClientInterfacer
}

func NewMessageBroker() *MessageBroker
func (b *MessageBroker) Broadcast(senderId uint64, msg packets.Msg)
func (b *MessageBroker) Register(client ClientInterfacer)
func (b *MessageBroker) Unregister(client ClientInterfacer)
```

### 4. Slimmed-Down Hub

The Hub becomes a thin orchestrator that delegates to `ClientRegistry` and `MessageBroker`.

```go
type Hub struct {
    Logger      *slog.Logger
    UserService *user.Service
    Registry    *ClientRegistry
    Broker      *MessageBroker
}

func NewHub(logger *slog.Logger, userService *user.Service) *Hub {
    return &Hub{
        Logger:      logger,
        UserService:  userService,
        Registry:     NewClientRegistry(),
        Broker:       NewMessageBroker(),
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

func (h *Hub) Serve(getNewClient func(*Hub, http.ResponseWriter, *http.Request) (ClientInterfacer, error), w http.ResponseWriter, r *http.Request) {
    client, err := getNewClient(h, w, r)
    if err != nil {
        h.Logger.Error("Failed to create client", "error", err)
        return
    }
    h.Broker.Register(client)
    h.Logger.Info("New client connected", "address", r.RemoteAddr)
    go client.WritePump()
    go client.ReadPump()
}
```

## Benefits

1. **Clear boundaries:** Each component has a single responsibility
2. **Testable:** `ClientRegistry` and `MessageBroker` can be unit tested independently
3. **Discoverable:** Interfaces in one file, implementations clearly separated
4. **Maintainable:** Hub shrinks from ~50 lines to ~30 lines of core logic

## Migration Steps

1. Create new directory structure
2. Move `objects/` into `server/objects/`
3. Create `interfaces.go` with extracted interfaces
4. Create `components/registry.go` and `components/broker.go`
5. Update `hub.go` to use new components
6. Update all import paths
7. Run tests to verify nothing breaks

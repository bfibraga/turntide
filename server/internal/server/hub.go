package server

import (
	"log/slog"
	"net/http"

	"github.com/bfibraga/turntide/core/pkg/packets"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/internal/server/user"
)

type Hub struct {
	Logger      *slog.Logger
	UserService *user.Service
	Registry    *components.ClientRegistry
	Broker      *components.MessageBroker
	Lobbies     *components.LobbyRegistry
}

func NewHub(logger *slog.Logger, userService *user.Service) *Hub {
	lobbyReg := components.NewLobbyRegistry(components.DefaultLobbyConfig())

	// Placeholder lobby for testing
	lobbyReg.CreateLobby(
		uint64(99),
		"Test User",
		"Placeholder Lobby",
		"Casual",
		10,
		false,
		"",
	)

	return &Hub{
		Logger:      logger,
		UserService: userService,
		Registry:    components.NewClientRegistry(),
		Broker:      components.NewMessageBroker(),
		Lobbies:     lobbyReg,
	}
}

// Initialize registers runtime callbacks for components that need hub access.
// Call once after creating the hub.
func (h *Hub) Initialize() {
	if h.Lobbies != nil {
		// Register onChange to broadcast lobby lists when they change
		h.Lobbies.SetOnChange(func() { h.BroadcastLobbyList() })
	}
}

// BroadcastLobbyList broadcasts current public lobbies to all authenticated clients.
// It is intended to be registered as a callback with the LobbyRegistry.
func (h *Hub) BroadcastLobbyList() {
	lobbies := h.Lobbies.ListPublicLobbies()

	var lobbyInfos []*packets.LobbyInfo
	for _, l := range lobbies {
		lobbyInfos = append(lobbyInfos, &packets.LobbyInfo{
			Id:             l.ID,
			Name:           l.Name,
			Format:         l.Format,
			CurrentPlayers: int32(l.CurrentPlayers),
			MaxPlayers:     int32(l.MaxPlayers),
			HostUsername:   l.HostUsername,
			IsPrivate:      l.IsPrivate,
		})
	}

	msg := packets.NewLobbyListResponse(lobbyInfos)

	// Broadcast only to authenticated clients so unauthenticated sockets ignore it.
	h.Registry.ForEach(func(id uint64, client ClientInterfacer) {
		// Only send to clients that are in the Authenticated state
		if client.StateName() == "Authenticated" {
			client.ProcessPacket(0, msg)
		}
	})
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

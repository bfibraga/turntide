package server

import (
	"log/slog"
	"net/http"

	"github.com/bfibraga/turntide/server/internal/objects"
	"github.com/bfibraga/turntide/server/internal/server/user"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type Hub struct {
	Logger         *slog.Logger
	UserService    *user.Service
	Clients        *objects.SharedCollection[ClientInterfacer]
	BroadcastChan  chan *packets.Packet
	RegisterChan   chan ClientInterfacer
	UnregisterChan chan ClientInterfacer
}

func NewHub(logger *slog.Logger, userService *user.Service) *Hub {
	return &Hub{
		Logger:         logger,
		UserService:    userService,
		Clients:        objects.NewSharedCollection[ClientInterfacer](),
		BroadcastChan:  make(chan *packets.Packet),
		RegisterChan:   make(chan ClientInterfacer),
		UnregisterChan: make(chan ClientInterfacer),
	}
}

func (h *Hub) Run() {
	h.Logger.Info("Initializing database")

	h.Logger.Info("Waiting for connections...")
	for {
		select {
		case client := <-h.RegisterChan:
			client.Initialize(h.Clients.Add(client))
		case client := <-h.UnregisterChan:
			h.Clients.Delete(client.Id())
		case packet := <-h.BroadcastChan:
			h.Clients.ForEach(func(id uint64, client ClientInterfacer) {
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

	h.RegisterChan <- client

	h.Logger.Info("New client connected", "address", request.RemoteAddr)

	go client.WritePump()
	go client.ReadPump()
}

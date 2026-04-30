package server

import (
	"log/slog"
	"net/http"

	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/internal/server/user"
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

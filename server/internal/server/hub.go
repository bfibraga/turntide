package server

import (
	"log/slog"
	"net/http"

	"github.com/bfibraga/turntide/server/internal/objects"
	"github.com/bfibraga/turntide/server/internal/server/repository"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type ClientInterfacer interface {
	// Id returns the client's unique identifier.
	Id() uint64
	// ProcessPacket processes a packet from the hub.
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

// A structure for a state machine to process the client's messages
type ClientStateHandler interface {
	Name() string

	// Inject the client into the state handler
	SetClient(client ClientInterfacer)

	OnEnter()
	HandleMessage(senderId uint64, message packets.Msg)

	// Cleanup the state handler and perform any last actions
	OnExit()
}

type Hub struct {
	Logger         *slog.Logger
	UserRepository repository.UserRepository
	Clients        *objects.SharedCollection[ClientInterfacer]
	BroadcastChan  chan *packets.Packet
	RegisterChan   chan ClientInterfacer
	UnregisterChan chan ClientInterfacer
}

func NewHub(logger *slog.Logger, userRepo repository.UserRepository) *Hub {
	return &Hub{
		Logger:         logger,
		UserRepository: userRepo,
		Clients:        objects.NewSharedCollection[ClientInterfacer](),
		BroadcastChan:  make(chan *packets.Packet),
		RegisterChan:   make(chan ClientInterfacer),
		UnregisterChan: make(chan ClientInterfacer),
	}
}

func (h *Hub) Run() {
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

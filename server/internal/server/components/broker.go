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

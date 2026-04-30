package components

import (
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type MessageBroker struct {
	BroadcastChan  chan *packets.Packet
	RegisterChan   chan ClientInterfacer
	UnregisterChan chan ClientInterfacer
}

func NewMessageBroker() *MessageBroker {
	return &MessageBroker{
		BroadcastChan:  make(chan *packets.Packet),
		RegisterChan:   make(chan ClientInterfacer),
		UnregisterChan: make(chan ClientInterfacer),
	}
}

func (b *MessageBroker) Broadcast(senderId uint64, msg packets.Msg) {
	b.BroadcastChan <- packets.NewPacket(senderId, msg)
}

func (b *MessageBroker) Register(client ClientInterfacer) {
	b.RegisterChan <- client
}

func (b *MessageBroker) Unregister(client ClientInterfacer) {
	b.UnregisterChan <- client
}

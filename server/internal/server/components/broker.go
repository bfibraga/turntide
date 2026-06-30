package components

import (
	"github.com/bfibraga/turntide/core/pkg/packets"
)

type LobbyBroadcast struct {
	LobbyID uint64
	Packet  *packets.Packet
}

type MessageBroker struct {
	LobbyBroadcastChan chan LobbyBroadcast
	BroadcastChan      chan *packets.Packet
	RegisterChan       chan ClientInterfacer
	UnregisterChan     chan ClientInterfacer
}

func NewMessageBroker() *MessageBroker {
	return &MessageBroker{
		BroadcastChan:      make(chan *packets.Packet),
		LobbyBroadcastChan: make(chan LobbyBroadcast),
		RegisterChan:       make(chan ClientInterfacer),
		UnregisterChan:     make(chan ClientInterfacer),
	}
}

func (b *MessageBroker) Broadcast(senderId uint64, msg packets.Msg) {
	b.BroadcastChan <- packets.NewPacket(senderId, msg)
}

func (b *MessageBroker) BroadcastToLobby(senderID uint64, msg packets.Msg, lobbyID uint64) {
	b.LobbyBroadcastChan <- LobbyBroadcast{LobbyID: lobbyID, Packet: packets.NewPacket(senderID, msg)}
}

func (b *MessageBroker) Register(client ClientInterfacer) {
	b.RegisterChan <- client
}

func (b *MessageBroker) Unregister(client ClientInterfacer) {
	b.UnregisterChan <- client
}

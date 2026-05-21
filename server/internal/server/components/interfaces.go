package components

import (
	"github.com/bfibraga/turntide/core/pkg/packets"
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

	// StateName returns the current state's Name(). Used for routing decisions
	// at the hub level without depending on concrete client types.
	StateName() string

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

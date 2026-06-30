package states

import (
	"github.com/bfibraga/turntide/core/pkg/packets"
	"github.com/bfibraga/turntide/server/internal/server/components"
)

func HandleMessage(client components.ClientInterfacer, senderId uint64, message packets.Msg) {
	switch message := message.(type) {
	case *packets.Packet_Chat:
		HandleChat(client, senderId, message)
	case *packets.Packet_Ping:
		HandlePing(client)
	default:
		// Not defined, ignored
	}
}

func HandleChat(client components.ClientInterfacer, senderId uint64, message *packets.Packet_Chat) {
	if senderId == client.Id() {
		client.Broadcast(message)
	} else {
		client.SocketSendAs(senderId, message)
	}
}

func HandlePing(client components.ClientInterfacer) {
	client.SocketSend(packets.NewPingNow())
}

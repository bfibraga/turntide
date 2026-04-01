package states

import (
	"log/slog"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type Connected struct {
	client server.ClientInterfacer
	logger *slog.Logger
}

func NewConnected(logger *slog.Logger) *Connected {
	return &Connected{
		logger: logger,
	}
}

func (c *Connected) Name() string {
	return "Connected"
}

func (c *Connected) SetClient(client server.ClientInterfacer) {
	c.client = client
	c.logger = c.logger.With(
		"client_id", c.client.Id(),
	)
}

func (c *Connected) OnEnter() {
	c.client.SocketSend(packets.NewId(c.client.Id()))
}

func (c *Connected) HandleMessage(senderId uint64, message packets.Msg) {
	c.logger.Debug("received message", "sender_id", senderId, "message", message)
	if senderId == c.client.Id() {
		c.client.Broadcast(message)
	} else {
		c.client.SocketSendAs(senderId, message)
	}
}

func (c *Connected) OnExit() {
	c.logger.Debug("client disconnected", "client_id", c.client.Id())
}

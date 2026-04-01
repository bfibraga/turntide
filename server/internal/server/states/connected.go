package states

import (
	"context"
	"log/slog"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/repository"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type Connected struct {
	client         server.ClientInterfacer
	userRepository repository.UserRepository
	logger         *slog.Logger
}

func NewConnected(logger *slog.Logger, userRepository repository.UserRepository) *Connected {
	return &Connected{
		logger:         logger,
		userRepository: userRepository,
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
	c.logger.Debug("received message", "sender_id", senderId, "message_type", message)

	switch msg := message.(type) {
	case *packets.Packet_LoginRequest:
		c.handleLogin(msg.LoginRequest)
	case *packets.Packet_RegisterRequest:
		c.handleRegister(msg.RegisterRequest)
	default:
		// Non-auth message in Connected state
		if senderId == c.client.Id() {
			c.client.Broadcast(message)
		} else {
			c.client.SocketSendAs(senderId, message)
		}
	}
}

func (c *Connected) handleLogin(loginReq *packets.LoginRequestMessage) {
	if loginReq == nil {
		c.client.SocketSend(packets.NewDenyResponse("invalid login request"))
		return
	}

	ctx := context.Background()

	// Verify password
	verified, err := c.userRepository.VerifyPassword(ctx, loginReq.Username, loginReq.Password)
	if err != nil {
		c.logger.Error("failed to verify password", "username", loginReq.Username, "error", err)
		c.client.SocketSend(packets.NewDenyResponse("authentication failed"))
		return
	}

	if !verified {
		c.logger.Warn("invalid password attempt", "username", loginReq.Username)
		c.client.SocketSend(packets.NewDenyResponse("invalid credentials"))
		return
	}

	// Authentication successful
	c.logger.Info("user logged in", "username", loginReq.Username)
	c.client.SocketSend(packets.NewOkResponse())
	c.client.SetState(NewAuthenticated(c.logger, loginReq.Username))
}

func (c *Connected) handleRegister(registerReq *packets.RegisterRequestMessage) {
	if registerReq == nil {
		c.client.SocketSend(packets.NewDenyResponse("invalid register request"))
		return
	}

	ctx := context.Background()

	// Create user
	user, err := c.userRepository.Create(ctx, registerReq.Username, registerReq.Password)
	if err != nil {
		c.logger.Error("failed to create user", "username", registerReq.Username, "error", err)
		c.client.SocketSend(packets.NewDenyResponse("registration failed"))
		return
	}

	// Registration successful
	c.logger.Info("user registered", "username", registerReq.Username, "user_id", user.ID)
	c.client.SocketSend(packets.NewOkResponse())
	c.client.SetState(NewAuthenticated(c.logger, registerReq.Username))
}

func (c *Connected) OnExit() {
	c.logger.Debug("exiting Connected state", "client_id", c.client.Id())
}

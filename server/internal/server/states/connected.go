package states

import (
	"context"
	"log/slog"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/repository"
	"github.com/bfibraga/turntide/server/internal/server/validation"
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
		c.handleLogin(senderId, msg)
	case *packets.Packet_RegisterRequest:
		c.handleRegister(senderId, msg)
	}
}

func (c *Connected) handleLogin(senderId uint64, packet *packets.Packet_LoginRequest) {
	if senderId != c.client.Id() {
		c.logger.Debug("Received login message from another client.", "sender_id", senderId)
	}

	ctx := context.Background()
	username := packet.LoginRequest.Username
	password := packet.LoginRequest.Password

	// Verify password
	verified, err := c.userRepository.VerifyPassword(ctx, username, password)
	if err != nil {
		c.logger.Error("failed to verify password", "username", username, "error", err)
		c.client.SocketSend(packets.NewDenyResponse("authentication failed"))
		return
	}

	if !verified {
		c.logger.Warn("invalid password attempt", "username", username)
		c.client.SocketSend(packets.NewDenyResponse("invalid credentials"))
		return
	}

	// Authentication successful
	c.logger.Info("user logged in", "username", username)
	c.client.SocketSend(packets.NewOkResponse())
	c.client.SetState(NewAuthenticated(c.logger, username))
}

func (c *Connected) handleRegister(senderId uint64, packet *packets.Packet_RegisterRequest) {
	if senderId != c.client.Id() {
		c.logger.Debug("Received login message from another client.", "sender_id", senderId)
	}

	ctx := context.Background()
	username := packet.RegisterRequest.Username
	password := packet.RegisterRequest.Password

	// Validate user data
	validator := validation.AllOf(
		validation.NewDefaultUsernameValidator(username),
		validation.NewDefaultPasswordValidator(password),
	)
	if err := validator.Validate(); err != nil {
		c.logger.Warn("validation failed", "error", err)
		c.client.SocketSend(packets.NewDenyResponse("invalid credentials"))
		return
	}

	// Create user
	user, err := c.userRepository.Create(ctx, username, password)
	if err != nil {
		c.logger.Error("failed to create user", "username", username, "error", err)
		c.client.SocketSend(packets.NewDenyResponse("registration failed"))
		return
	}

	// Registration successful
	c.logger.Info("user registered", "username", username, "user_id", user.ID)
	c.client.SocketSend(packets.NewOkResponse())
	c.client.SetState(NewAuthenticated(c.logger, username))
}

func (c *Connected) OnExit() {
	c.logger.Debug("exiting Connected state", "client_id", c.client.Id())
}

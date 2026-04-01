/*
Copyright © 2026 Bruno Braga bf.braga@campus.fct.unl.pt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
package states

import (
	"log/slog"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

// Authenticated represents a client that has been authenticated
type Authenticated struct {
	client   server.ClientInterfacer
	username string
	logger   *slog.Logger
}

// NewAuthenticated creates a new Authenticated state
func NewAuthenticated(logger *slog.Logger, username string) *Authenticated {
	return &Authenticated{
		logger:   logger,
		username: username,
	}
}

func (a *Authenticated) Name() string {
	return "Authenticated"
}

func (a *Authenticated) SetClient(client server.ClientInterfacer) {
	a.client = client
	a.logger = a.logger.With(
		"client_id", a.client.Id(),
		"username", a.username,
	)
}

func (a *Authenticated) OnEnter() {
	a.logger.Info("client authenticated", "username", a.username)
}

func (a *Authenticated) HandleMessage(senderId uint64, message packets.Msg) {
	a.logger.Debug("received message from authenticated client", "sender_id", senderId, "message_type", message)

	// Allow all game messages in authenticated state
	if senderId == a.client.Id() {
		a.client.Broadcast(message)
	} else {
		a.client.SocketSendAs(senderId, message)
	}
}

func (a *Authenticated) OnExit() {
	a.logger.Info("client disconnected", "username", a.username)
}

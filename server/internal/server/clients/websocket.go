package clients

import (
	"log/slog"
	"net/http"

	"github.com/bfibraga/turntide/core/pkg/packets"
	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/states"
	"github.com/gorilla/websocket"
	"google.golang.org/protobuf/proto"
)

type WebSocketClient struct {
	id       uint64
	conn     *websocket.Conn
	hub      *server.Hub
	sendChan chan *packets.Packet
	state    server.ClientStateHandler
	logger   *slog.Logger
}

func NewWebSocketClient(hub *server.Hub, writer http.ResponseWriter, request *http.Request) (server.ClientInterfacer, error) {
	upgrader := websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
		CheckOrigin:     func(_ *http.Request) bool { return true },
	}

	conn, err := upgrader.Upgrade(writer, request, nil)

	if err != nil {
		return nil, err
	}

	c := &WebSocketClient{
		hub:      hub,
		conn:     conn,
		sendChan: make(chan *packets.Packet, 256),
		logger:   slog.Default(),
	}

	return c, nil
}

func (c *WebSocketClient) Id() uint64 {
	return c.id
}

func (c *WebSocketClient) Initialize(id uint64) {
	c.id = id
	c.logger = c.hub.Logger.With("client_id", id)
	c.SetState(states.NewConnected(c.logger, c.hub.UserService, c.hub.Lobbies))
	c.logger.Debug("Sent ID to client")

	// Register lobby change callback once hub is available
	/*if c.hub != nil && c.hub.Lobbies != nil {
	// set the onChange callback on the registry to broadcast updated lists
	c.hub.Lobbies.SetOnChange(func() { c.hub.BroadcastLobbyList() })
	}*/
}

func (c *WebSocketClient) ProcessPacket(senderId uint64, message packets.Msg) {
	c.logger.Info("received packet", "message", message, "sender_id", senderId)
	c.state.HandleMessage(senderId, message)
}

func (c *WebSocketClient) SocketSend(msg packets.Msg) {
	c.SocketSendAs(c.id, msg)
}

func (c *WebSocketClient) SocketSendAs(senderId uint64, msg packets.Msg) {
	select {
	case c.sendChan <- packets.NewPacket(c.id, msg):

	default:
		c.logger.Warn("send channel full, dropping packet", "sender_id", senderId, "message", msg)
	}
}

func (c *WebSocketClient) PassToPeer(message packets.Msg, senderId uint64) {
	if peer, exists := c.hub.Registry.Get(senderId); exists {
		peer.ProcessPacket(c.id, message)
	}
}

func (c *WebSocketClient) Broadcast(message packets.Msg) {
	c.hub.Broker.Broadcast(c.id, message)
}

func (c *WebSocketClient) BroadcastToLobby(lobbyID uint64, msg packets.Msg) {
	if lobby, ok := c.hub.Lobbies.FindLobby(lobbyID); ok {
		for clientID := range lobby.Players {
			if clientID == c.id {
				continue // don't send to self
			}
			if peer, exists := c.hub.Registry.Get(clientID); exists {
				peer.ProcessPacket(c.id, msg)
			}
		}
	}
}

func (c *WebSocketClient) ReadPump() {
	defer func() {
		c.logger.Info("read pump exited")
		c.Close()
	}()

	for {
		_, data, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				c.logger.Error("read error", "error", err)
			}
			break
		}

		packet := &packets.Packet{}
		if err := proto.Unmarshal(data, packet); err != nil {
			c.logger.Error("unmarshal error", "error", err)
			continue
		}

		c.ProcessPacket(packet.SenderId, packet.Msg)
	}
}

func (c *WebSocketClient) WritePump() {
	defer func() {
		c.logger.Info("Closing write pump")
		c.Close()
	}()

	for packet := range c.sendChan {
		writer, err := c.conn.NextWriter(websocket.BinaryMessage)
		if err != nil {
			c.logger.Info("error getting writer for the packet, closing client", "message", packet.Msg, "error", err)
			return
		}

		data, err := proto.Marshal(packet)
		if err != nil {
			c.logger.Info("error marshalling the packet, dropping", "message", packet.Msg, "error", err)
			continue
		}

		_, writeErr := writer.Write(data)

		if writeErr != nil {
			c.logger.Info("error writing the packet", "message", packet.Msg, "error", writeErr)
			continue
		}

		writer.Write([]byte{'\n'})

		if closeErr := writer.Close(); closeErr != nil {
			c.logger.Info("error closing writer, dropping the packet", "error", closeErr)
			continue
		}
	}
}

func (c *WebSocketClient) SetState(state server.ClientStateHandler) {
	prevStateName := "None"
	if c.state != nil {
		prevStateName = c.state.Name()
		c.state.OnExit()
	}

	newStateName := "None"
	if state != nil {
		newStateName = state.Name()
	}

	c.logger.Info("Switching states", "previous", prevStateName, "new", newStateName)

	c.state = state

	if c.state != nil {
		c.state.SetClient(c)
		c.state.OnEnter()
	}
}

// StateName exposes the current underlying state's name for hub-level routing.
func (c *WebSocketClient) StateName() string {
	if c.state == nil {
		return "None"
	}
	return c.state.Name()
}

func (c *WebSocketClient) Close() {
	c.logger.Info("Closing client connection")
	// Ensure state exit handlers run (which remove the client from any lobby)
	// before unregistering from the broker.
	c.SetState(nil)
	c.hub.Broker.Unregister(c)
	c.conn.Close()
	if _, closed := <-c.sendChan; !closed {
		close(c.sendChan)
	}
}

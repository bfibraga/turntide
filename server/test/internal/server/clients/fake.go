package clients

import (
	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type fakeClient struct {
	id       uint64
	SentMsgs []packets.Msg
	State    server.ClientStateHandler
	closed   bool
	peerMsgs []peerMsg
}

func NewFakeClient(id uint64) *fakeClient {
	return &fakeClient{
		id: id,
	}
}

type peerMsg struct {
	msg    packets.Msg
	peerId uint64
}

func (f *fakeClient) Id() uint64 { return f.id }

func (f *fakeClient) ProcessPacket(senderId uint64, message packets.Msg) {}

func (f *fakeClient) Initialize(id uint64) {}

func (f *fakeClient) SocketSend(message packets.Msg) {
	f.SentMsgs = append(f.SentMsgs, message)
}

func (f *fakeClient) SocketSendAs(senderId uint64, message packets.Msg) {}

func (f *fakeClient) PassToPeer(message packets.Msg, peerId uint64) {
	f.peerMsgs = append(f.peerMsgs, peerMsg{msg: message, peerId: peerId})
}

func (f *fakeClient) Broadcast(message packets.Msg) {}

func (f *fakeClient) ReadPump() {}

func (f *fakeClient) WritePump() {}

func (f *fakeClient) SetState(state server.ClientStateHandler) {
	f.State = state
}

func (f *fakeClient) Close() { f.closed = true }

func (f *fakeClient) StateName() string {
	if f.State == nil {
		return "None"
	}
	return f.State.Name()
}

// SentPacketCount returns the number of packets sent via SocketSend.
func (f *fakeClient) SentPacketCount() int {
	return len(f.SentMsgs)
}

// PeerMessages returns all messages sent via PassToPeer.
func (f *fakeClient) PeerMessages() []peerMsg {
	return f.peerMsgs
}

// IsClosed returns whether Close was called.
func (f *fakeClient) IsClosed() bool {
	return f.closed
}

// GetState returns the current state set via SetState.
func (f *fakeClient) GetState() server.ClientStateHandler {
	return f.State
}

// Ensure fakeClient satisfies components.ClientInterfacer at compile time.
var _ components.ClientInterfacer = (*fakeClient)(nil)

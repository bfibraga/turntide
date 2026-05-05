package components

import (
	"testing"

	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type fakeClient struct {
	id       uint64
	sentMsgs []packets.Msg
	state    components.ClientStateHandler
	closed   bool
	peerMsgs []peerMsg
}

type peerMsg struct {
	msg    packets.Msg
	peerId uint64
}

func (f *fakeClient) Id() uint64 { return f.id }
func (f *fakeClient) ProcessPacket(senderId uint64, message packets.Msg) {}
func (f *fakeClient) Initialize(id uint64)                               {}
func (f *fakeClient) SocketSend(message packets.Msg) {
	f.sentMsgs = append(f.sentMsgs, message)
}
func (f *fakeClient) SocketSendAs(senderId uint64, message packets.Msg) {}
func (f *fakeClient) PassToPeer(message packets.Msg, peerId uint64) {
	f.peerMsgs = append(f.peerMsgs, peerMsg{msg: message, peerId: peerId})
}
func (f *fakeClient) Broadcast(message packets.Msg)                     {}
func (f *fakeClient) ReadPump()                                        {}
func (f *fakeClient) WritePump()                                       {}
func (f *fakeClient) SetState(state components.ClientStateHandler)       { f.state = state }
func (f *fakeClient) Close()                                            { f.closed = true }
func (f *fakeClient) StateName() string {
	if f.state == nil {
		return "None"
	}
	return f.state.Name()
}
func (f *fakeClient) SentPacketCount() int                { return len(f.sentMsgs) }
func (f *fakeClient) PeerMessages() []peerMsg            { return f.peerMsgs }
func (f *fakeClient) IsClosed() bool                     { return f.closed }
func (f *fakeClient) GetState() components.ClientStateHandler { return f.state }

func TestAddClient(t *testing.T) {
	registry := components.NewClientRegistry()
	client := &fakeClient{id: 1}

	id := registry.Add(client)

	if id == 0 {
		t.Error("expected non-zero ID")
	}

	retrieved, ok := registry.Get(id)
	if !ok {
		t.Error("expected to retrieve client")
	}
	if retrieved.Id() != client.Id() {
		t.Error("retrieved client should match added client")
	}
}

func TestDeleteClient(t *testing.T) {
	registry := components.NewClientRegistry()
	client := &fakeClient{id: 1}

	id := registry.Add(client)
	registry.Delete(id)

	_, ok := registry.Get(id)
	if ok {
		t.Error("expected client to be deleted")
	}
}

func TestForEach(t *testing.T) {
	registry := components.NewClientRegistry()
	client1 := &fakeClient{id: 1}
	client2 := &fakeClient{id: 2}

	registry.Add(client1)
	registry.Add(client2)

	count := 0
	registry.ForEach(func(id uint64, c components.ClientInterfacer) {
		count++
	})

	if count != 2 {
		t.Errorf("expected 2 clients, got %d", count)
	}
}

func TestSize(t *testing.T) {
	registry := components.NewClientRegistry()

	if registry.Size() != 0 {
		t.Error("expected empty registry")
	}

	registry.Add(&fakeClient{id: 1})
	registry.Add(&fakeClient{id: 2})

	if registry.Size() != 2 {
		t.Errorf("expected 2 clients, got %d", registry.Size())
	}
}

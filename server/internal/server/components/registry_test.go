package components

import (
	"testing"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

type mockClient struct {
	id uint64
}

func (m *mockClient) Id() uint64 { return m.id }
func (m *mockClient) ProcessPacket(senderId uint64, message packets.Msg) {}
func (m *mockClient) Initialize(id uint64)                             {}
func (m *mockClient) SocketSend(message packets.Msg)                    {}
func (m *mockClient) SocketSendAs(senderId uint64, message packets.Msg) {}
func (m *mockClient) PassToPeer(message packets.Msg, peerId uint64)     {}
func (m *mockClient) Broadcast(message packets.Msg)                    {}
func (m *mockClient) ReadPump()                                        {}
func (m *mockClient) WritePump()                                       {}
func (m *mockClient) SetState(state server.ClientStateHandler)          {}
func (m *mockClient) Close()                                           {}

func TestAddClient(t *testing.T) {
	registry := NewClientRegistry()
	client := &mockClient{}

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
	registry := NewClientRegistry()
	client := &mockClient{}

	id := registry.Add(client)
	registry.Delete(id)

	_, ok := registry.Get(id)
	if ok {
		t.Error("expected client to be deleted")
	}
}

func TestForEach(t *testing.T) {
	registry := NewClientRegistry()
	client1 := &mockClient{}
	client2 := &mockClient{}

	registry.Add(client1)
	registry.Add(client2)

	count := 0
	registry.ForEach(func(id uint64, c server.ClientInterfacer) {
		count++
	})

	if count != 2 {
		t.Errorf("expected 2 clients, got %d", count)
	}
}

func TestSize(t *testing.T) {
	registry := NewClientRegistry()

	if registry.Size() != 0 {
		t.Error("expected empty registry")
	}

	registry.Add(&mockClient{})
	registry.Add(&mockClient{})

	if registry.Size() != 2 {
		t.Errorf("expected 2 clients, got %d", registry.Size())
	}
}

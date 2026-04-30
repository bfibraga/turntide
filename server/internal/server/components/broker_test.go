package components

import (
	"testing"
	"time"

	"github.com/bfibraga/turntide/server/pkg/packets"
)

func TestBroadcast(t *testing.T) {
	broker := NewMessageBroker()

	received := make(chan *packets.Packet, 1)
	go func() {
		packet := <-broker.BroadcastChan
		received <- packet
	}()

	broker.Broadcast(1, packets.NewId(1))
	packet := <-received

	if packet.SenderId != 1 {
		t.Errorf("expected SenderId 1, got %d", packet.SenderId)
	}
}

func TestRegister(t *testing.T) {
	broker := NewMessageBroker()

	// Create a mock client that satisfies ClientInterfacer
	client := &mockClient{id: 1}

	go broker.Register(client)

	select {
	case c := <-broker.RegisterChan:
		if c.Id() != 1 {
			t.Errorf("expected client id 1, got %d", c.Id())
		}
	case <-time.After(time.Second):
		t.Error("timeout waiting for client on RegisterChan")
	}
}

func TestUnregister(t *testing.T) {
	broker := NewMessageBroker()

	client := &mockClient{id: 1}

	go broker.Unregister(client)

	select {
	case c := <-broker.UnregisterChan:
		if c.Id() != 1 {
			t.Errorf("expected client id 1, got %d", c.Id())
		}
	case <-time.After(time.Second):
		t.Error("timeout waiting for client on UnregisterChan")
	}
}

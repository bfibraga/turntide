package components

import (
	"testing"
	"time"

	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/pkg/packets"
)

func TestBroadcast(t *testing.T) {
	broker := components.NewMessageBroker()

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
	if packet.GetId() == nil {
		t.Error("expected Id packet, got nil")
	}
}

func TestBroadcastMultiplePackets(t *testing.T) {
	broker := components.NewMessageBroker()

	go func() {
		broker.Broadcast(1, packets.NewId(1))
		broker.Broadcast(2, packets.NewPing(time.Now()))
		broker.Broadcast(3, packets.NewId(3))
	}()

	received := []uint64{}
	for i := 0; i < 3; i++ {
		select {
		case packet := <-broker.BroadcastChan:
			received = append(received, packet.SenderId)
		case <-time.After(time.Second):
			t.Fatalf("timeout waiting for packet %d", i+1)
		}
	}

	if len(received) != 3 {
		t.Fatalf("expected 3 packets, got %d", len(received))
	}
}

func TestRegister(t *testing.T) {
	broker := components.NewMessageBroker()

	client := &fakeClient{id: 1}

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
	broker := components.NewMessageBroker()

	client := &fakeClient{id: 1}

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

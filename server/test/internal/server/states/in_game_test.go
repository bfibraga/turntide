package states

import (
	"log/slog"
	"testing"
	"time"

	"github.com/bfibraga/turntide/server/internal/server/states"
	"github.com/bfibraga/turntide/server/pkg/packets"
	"github.com/bfibraga/turntide/server/test/internal/server/clients"
)

func TestInGameOnEnter(t *testing.T) {
	logger := slog.Default()
	client := clients.NewFakeClient(1)
	inGame := states.NewInGame(logger, 123)
	inGame.SetClient(client)

	inGame.OnEnter()

	if client.SentPacketCount() != 0 {
		t.Fatalf("expected 0 messages on enter (stub), got %d", client.SentPacketCount())
	}
}

func TestInGameName(t *testing.T) {
	logger := slog.Default()
	inGame := states.NewInGame(logger, 123)
	if inGame.Name() != "InGame" {
		t.Errorf("expected InGame, got %s", inGame.Name())
	}
}

func TestInGameHandleMessage(t *testing.T) {
	logger := slog.Default()
	client := clients.NewFakeClient(1)
	inGame := states.NewInGame(logger, 123)
	inGame.SetClient(client)
	// Should not panic, just log
	inGame.HandleMessage(1, packets.NewPing(time.Now()))
}

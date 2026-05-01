package states

import (
	"log/slog"
	"testing"
	"time"

	"github.com/bfibraga/turntide/server/pkg/packets"
)

func TestInGameOnEnter(t *testing.T) {
	logger := slog.Default()
	client := &mockInLobbyClient{id: 1, sentMsgs: []packets.Msg{}}
	inGame := NewInGame(logger, 123)
	inGame.SetClient(client)

	inGame.OnEnter()

	if len(client.sentMsgs) != 0 {
		t.Fatalf("expected 0 messages on enter (stub), got %d", len(client.sentMsgs))
	}
}

func TestInGameName(t *testing.T) {
	logger := slog.Default()
	inGame := NewInGame(logger, 123)
	if inGame.Name() != "InGame" {
		t.Errorf("expected InGame, got %s", inGame.Name())
	}
}

func TestInGameHandleMessage(t *testing.T) {
	logger := slog.Default()
	inGame := NewInGame(logger, 123)
	// Should not panic, just log
	inGame.HandleMessage(1, packets.NewPing(time.Now()))
}

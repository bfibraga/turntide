package repository_test

import (
	"context"
	"sync"
	"testing"
	"time"

	"github.com/bfibraga/turntide/core/pkg/repository"
)

func ctx() context.Context {
	return context.Background()
}

func newLobby() *repository.Lobby {
	return &repository.Lobby{
		Name:         "test-lobby",
		Format:       "standard",
		MaxPlayers:   4,
		IsPrivate:    false,
		HostID:       100,
		HostUsername: "host-user",
		Players: map[uint64]*repository.LobbyPlayer{
			100: {ClientID: 100, Username: "host-user", Ready: false},
		},
		State: repository.LobbyWaiting,
	}
}

func TestCreateAndGetByID(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	lobby, err := repo.Create(ctx(), newLobby())
	if err != nil {
		t.Fatalf("Create failed: %v", err)
	}

	if lobby.ID == 0 {
		t.Fatal("expected non-zero ID")
	}

	if lobby.Name != "test-lobby" {
		t.Errorf("expected name 'test-lobby', got %q", lobby.Name)
	}

	got, err := repo.GetByID(ctx(), lobby.ID)
	if err != nil {
		t.Fatalf("GetByID failed: %v", err)
	}
	if got == nil {
		t.Fatal("expected lobby, got nil")
	}
	if got.ID != lobby.ID {
		t.Errorf("expected ID %d, got %d", lobby.ID, got.ID)
	}
}

func TestCreateUniqueIDs(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	l1, _ := repo.Create(ctx(), newLobby())
	l2, _ := repo.Create(ctx(), newLobby())

	if l1.ID == l2.ID {
		t.Fatal("expected unique IDs for different lobbies")
	}
}

func TestGetByIDNotFound(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	lobby, err := repo.GetByID(ctx(), 999)
	if err != nil {
		t.Fatalf("GetByID failed: %v", err)
	}
	if lobby != nil {
		t.Fatal("expected nil for non-existent lobby")
	}
}

func TestCreateAndGetByClientID(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	created, err := repo.Create(ctx(), newLobby())
	if err != nil {
		t.Fatalf("Create failed: %v", err)
	}

	lobby, err := repo.GetByClientID(ctx(), 100)
	if err != nil {
		t.Fatalf("GetByClientID failed: %v", err)
	}
	if lobby == nil {
		t.Fatal("expected lobby, got nil")
	}
	if lobby.ID != created.ID {
		t.Errorf("expected ID %d, got %d", created.ID, lobby.ID)
	}
}

func TestGetByClientIDNotFound(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	lobby, err := repo.GetByClientID(ctx(), 999)
	if err != nil {
		t.Fatalf("GetByClientID failed: %v", err)
	}
	if lobby != nil {
		t.Fatal("expected nil for non-existent client")
	}
}

func TestCreateNilPlayers(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	lobby := &repository.Lobby{
		Name:       "nil-players",
		HostID:     1,
		Players:    nil,
	}

	created, err := repo.Create(ctx(), lobby)
	if err != nil {
		t.Fatalf("Create failed: %v", err)
	}
	if created.Players == nil {
		t.Fatal("expected non-nil Players map after Create")
	}
}

func TestUpdateLobbyFields(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	created, _ := repo.Create(ctx(), newLobby())

	created.Name = "updated-lobby"
	created.State = repository.LobbyReady
	err := repo.Update(ctx(), created)
	if err != nil {
		t.Fatalf("Update failed: %v", err)
	}

	got, _ := repo.GetByID(ctx(), created.ID)
	if got.Name != "updated-lobby" {
		t.Errorf("expected name 'updated-lobby', got %q", got.Name)
	}
	if got.State != repository.LobbyReady {
		t.Errorf("expected state LobbyReady, got %v", got.State)
	}
}

func TestUpdatePreservesClientMappings(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	created, _ := repo.Create(ctx(), newLobby())

	// Add a second player
	created.Players[200] = &repository.LobbyPlayer{
		ClientID: 200, Username: "player-2", Ready: true,
	}
	repo.Update(ctx(), created)

	// Both clients should find the lobby
	lobby, _ := repo.GetByClientID(ctx(), 100)
	if lobby == nil {
		t.Fatal("expected client 100 to find lobby")
	}
	lobby, _ = repo.GetByClientID(ctx(), 200)
	if lobby == nil {
		t.Fatal("expected client 200 to find lobby")
	}
}

func TestUpdateRemovesStaleClientMappings(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	created, _ := repo.Create(ctx(), newLobby())

	// Remove host from players
	delete(created.Players, 100)
	repo.Update(ctx(), created)

	// Host should no longer find lobby
	lobby, _ := repo.GetByClientID(ctx(), 100)
	if lobby != nil {
		t.Fatal("expected client 100 to NOT find lobby after removal")
	}
}

func TestUpdateNonExistent(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	err := repo.Update(ctx(), &repository.Lobby{ID: 999})
	if err != nil {
		t.Fatalf("Update on non-existent should not error: %v", err)
	}
}

func TestDeleteRemovesLobby(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	created, _ := repo.Create(ctx(), newLobby())

	err := repo.Delete(ctx(), created.ID)
	if err != nil {
		t.Fatalf("Delete failed: %v", err)
	}

	lobby, _ := repo.GetByID(ctx(), created.ID)
	if lobby != nil {
		t.Fatal("expected lobby to be deleted")
	}
}

func TestDeleteRemovesClientMappings(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	created, _ := repo.Create(ctx(), newLobby())
	repo.Delete(ctx(), created.ID)

	lobby, _ := repo.GetByClientID(ctx(), 100)
	if lobby != nil {
		t.Fatal("expected client mapping to be removed after delete")
	}
}

func TestDeleteNonExistent(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	err := repo.Delete(ctx(), 999)
	if err != nil {
		t.Fatalf("Delete on non-existent should not error: %v", err)
	}
}

func TestListEmpty(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	result, err := repo.List(ctx(), &repository.ListLobbiesOptions{
		Page:     1,
		PageSize: 10,
	})
	if err != nil {
		t.Fatalf("List failed: %v", err)
	}
	if result.Count != 0 {
		t.Errorf("expected count 0, got %d", result.Count)
	}
	if len(result.Lobbies) != 0 {
		t.Errorf("expected 0 lobbies, got %d", len(result.Lobbies))
	}
}

func TestListExcludesPrivateLobbies(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	pub := newLobby()
	pub.Name = "public"
	repo.Create(ctx(), pub)

	priv := newLobby()
	priv.Name = "private"
	priv.IsPrivate = true
	repo.Create(ctx(), priv)

	result, _ := repo.List(ctx(), &repository.ListLobbiesOptions{
		Page: 1, PageSize: 10,
	})

	if result.Count != 1 {
		t.Errorf("expected 1 public lobby, got %d", result.Count)
	}
	if len(result.Lobbies) > 0 && result.Lobbies[0].Name == "private" {
		t.Error("private lobby should not appear in list")
	}
}

func TestListFiltersByName(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	repo.Create(ctx(), newLobby()) // "test-lobby"
	l2 := newLobby()
	l2.Name = "other-room"
	repo.Create(ctx(), l2)

	name := "test"
	result, _ := repo.List(ctx(), &repository.ListLobbiesOptions{
		Page: 1, PageSize: 10, Name: &name,
	})

	if result.Count != 1 {
		t.Errorf("expected 1 lobby matching 'test', got %d", result.Count)
	}
}

func TestListFiltersByFormat(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	l1 := newLobby()
	l1.Format = "standard"
	repo.Create(ctx(), l1)

	l2 := newLobby()
	l2.Name = "modern-room"
	l2.Format = "modern"
	repo.Create(ctx(), l2)

	format := "modern"
	result, _ := repo.List(ctx(), &repository.ListLobbiesOptions{
		Page: 1, PageSize: 10, Format: &format,
	})

	if result.Count != 1 {
		t.Errorf("expected 1 lobby with format 'modern', got %d", result.Count)
	}
}

func TestListFiltersByState(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	repo.Create(ctx(), newLobby()) // LobbyWaiting

	l2 := newLobby()
	l2.Name = "ready-room"
	l2.State = repository.LobbyReady
	repo.Create(ctx(), l2)

	state := repository.LobbyReady
	result, _ := repo.List(ctx(), &repository.ListLobbiesOptions{
		Page: 1, PageSize: 10, State: &state,
	})

	if result.Count != 1 {
		t.Errorf("expected 1 lobby with state LobbyReady, got %d", result.Count)
	}
}

func TestListPagination(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	for range 5 {
		l := newLobby()
		l.Name = "lobby"
		repo.Create(ctx(), l)
	}

	// Page 1: items 0-1
	r1, _ := repo.List(ctx(), &repository.ListLobbiesOptions{
		Page: 1, PageSize: 2,
	})
	if len(r1.Lobbies) != 2 {
		t.Errorf("expected 2 lobbies on page 1, got %d", len(r1.Lobbies))
	}

	// Page 3: items 4-4 (last item)
	r3, _ := repo.List(ctx(), &repository.ListLobbiesOptions{
		Page: 3, PageSize: 2,
	})
	if len(r3.Lobbies) != 1 {
		t.Errorf("expected 1 lobby on page 3, got %d", len(r3.Lobbies))
	}

	// Page 4: beyond total
	r4, _ := repo.List(ctx(), &repository.ListLobbiesOptions{
		Page: 4, PageSize: 2,
	})
	if r4.Count != 0 {
		t.Errorf("expected 0 lobbies beyond total pages, got %d", r4.Count)
	}
}

func TestListCombinedFilters(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	// Create various lobbies
	l := newLobby()
	l.Name = "standard-room"
	l.Format = "standard"
	l.State = repository.LobbyWaiting
	repo.Create(ctx(), l)

	format := "standard"
	state := repository.LobbyWaiting
	result, _ := repo.List(ctx(), &repository.ListLobbiesOptions{
		Page: 1, PageSize: 10, Format: &format, State: &state,
	})

	if result.Count == 0 {
		t.Error("expected at least one lobby matching combined filters")
	}
	for _, lobby := range result.Lobbies {
		if lobby.Format != "standard" {
			t.Errorf("expected format 'standard', got %q", lobby.Format)
		}
		if lobby.State != repository.LobbyWaiting {
			t.Errorf("expected state LobbyWaiting, got %v", lobby.State)
		}
	}
}

func TestSetTTL(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	// SetTTL should not panic
	repo.SetTTL(5 * time.Second)
}

func TestConcurrentCreate(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()
	var wg sync.WaitGroup

	for range 20 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, err := repo.Create(ctx(), newLobby())
			if err != nil {
				t.Errorf("concurrent create failed: %v", err)
			}
		}()
	}

	wg.Wait()

	result, _ := repo.List(ctx(), &repository.ListLobbiesOptions{
		Page: 1, PageSize: 50,
	})
	if result.Count != 20 {
		t.Errorf("expected 20 lobbies after concurrent creates, got %d", result.Count)
	}
}

func TestConcurrentReadWrite(t *testing.T) {
	repo := repository.NewInMemoryLobbyRepository()

	created, _ := repo.Create(ctx(), newLobby())

	var wg sync.WaitGroup
	for range 10 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			repo.GetByID(ctx(), created.ID)
		}()
	}

	wg.Add(1)
	go func() {
		defer wg.Done()
		created.HostUsername = "new-host"
		repo.Update(ctx(), created)
	}()

	wg.Wait()

	lobby, _ := repo.GetByID(ctx(), created.ID)
	if lobby == nil {
		t.Fatal("lobby should still exist after concurrent read/write")
	}
}

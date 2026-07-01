package repository

import (
	"context"
	"math"
	"strings"
	"sync"
	"time"

	"github.com/bfibraga/turntide/core/pkg/objects"
)

type inMemoryLobbyRepository struct {
	mu            sync.RWMutex
	lobbies       *objects.SharedCollection[*Lobby]
	clientToLobby map[uint64]uint64
	ttl           time.Duration
}

func NewInMemoryLobbyRepository() LobbyRepository {
	return &inMemoryLobbyRepository{
		lobbies:       objects.NewSharedCollection[*Lobby](),
		clientToLobby: make(map[uint64]uint64),
	}
}

func (r *inMemoryLobbyRepository) Create(_ context.Context, lobby *Lobby) (*Lobby, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	clone := cloneLobby(lobby)
	if clone.Players == nil {
		clone.Players = make(map[uint64]*LobbyPlayer)
	}

	id := r.lobbies.Add(clone)
	clone.ID = id

	for cid := range clone.Players {
		r.clientToLobby[cid] = id
	}

	return cloneLobby(clone), nil
}

func (r *inMemoryLobbyRepository) GetByID(_ context.Context, id uint64) (*Lobby, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	lobby, ok := r.lobbies.Get(id)
	if !ok {
		return nil, nil
	}

	return cloneLobby(lobby), nil
}

func (r *inMemoryLobbyRepository) GetByClientID(_ context.Context, clientID uint64) (*Lobby, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	lobbyID, ok := r.clientToLobby[clientID]
	if !ok {
		return nil, nil
	}

	lobby, ok := r.lobbies.Get(lobbyID)
	if !ok {
		return nil, nil
	}

	return cloneLobby(lobby), nil
}

func (r *inMemoryLobbyRepository) Update(_ context.Context, lobby *Lobby) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	existing, ok := r.lobbies.Get(lobby.ID)
	if !ok {
		return nil
	}

	// Remove stale client mappings
	for cid := range existing.Players {
		if _, stillPresent := lobby.Players[cid]; !stillPresent {
			delete(r.clientToLobby, cid)
		}
	}

	// Add new client mappings
	for cid := range lobby.Players {
		r.clientToLobby[cid] = lobby.ID
	}

	r.lobbies.Set(lobby.ID, cloneLobby(lobby))

	return nil
}

func (r *inMemoryLobbyRepository) Delete(_ context.Context, id uint64) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	lobby, ok := r.lobbies.Get(id)
	if !ok {
		return nil
	}

	for cid := range lobby.Players {
		delete(r.clientToLobby, cid)
	}

	r.lobbies.Delete(id)

	return nil
}

func (r *inMemoryLobbyRepository) List(_ context.Context, options *ListLobbiesOptions) (*ListLobbiesResult, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	page := max(1, options.Page)
	pageSize := max(1, min(50, options.PageSize))
	offset := (page - 1) * pageSize

	var filtered []*Lobby
	for _, lobby := range r.lobbies.Items() {
		if lobby.IsPrivate {
			continue
		}

		if options.Name != nil && !strings.Contains(lobby.Name, *options.Name) {
			continue
		}

		if options.Format != nil && *options.Format != "" && lobby.Format != *options.Format {
			continue
		}

		if options.State != nil && *options.State != lobby.State {
			continue
		}

		filtered = append(filtered, cloneLobby(lobby))
	}

	total := len(filtered)
	if offset >= total {
		return &ListLobbiesResult{
			Count:   0,
			Lobbies: make([]*Lobby, 0),
		}, nil
	}

	end := int(math.Min(float64(offset+pageSize), float64(total)))
	result := filtered[offset:end]

	return &ListLobbiesResult{
		Count:   len(result),
		Lobbies: result,
	}, nil
}

func (r *inMemoryLobbyRepository) SetTTL(d time.Duration) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.ttl = d
}

func (r *inMemoryLobbyRepository) getTTL() time.Duration {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.ttl
}

func cloneLobby(l *Lobby) *Lobby {
	if l == nil {
		return nil
	}

	clone := &Lobby{
		ID:           l.ID,
		Name:         l.Name,
		Format:       l.Format,
		MaxPlayers:   l.MaxPlayers,
		IsPrivate:    l.IsPrivate,
		PasswordHash: l.PasswordHash,
		HostID:       l.HostID,
		HostUsername: l.HostUsername,
		State:        l.State,
		Players:      make(map[uint64]*LobbyPlayer, len(l.Players)),
	}

	for k, v := range l.Players {
		clone.Players[k] = &LobbyPlayer{
			ClientID: v.ClientID,
			Username: v.Username,
			Ready:    v.Ready,
		}
	}

	return clone
}

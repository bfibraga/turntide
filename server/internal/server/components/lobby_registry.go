package components

import (
	"crypto/sha256"
	"fmt"
	"sync"

	"github.com/bfibraga/turntide/server/internal/server/objects"
)

type LobbyState int

const (
	LobbyWaiting LobbyState = iota
	LobbyReady
	LobbyInGame
)

type LobbyPlayer struct {
	ClientID uint64
	Username string
	Ready    bool
}

type Lobby struct {
	ID           uint64
	Name         string
	Format       string
	MaxPlayers   int
	IsPrivate    bool
	PasswordHash string
	HostID       uint64
	HostUsername string
	Players      map[uint64]*LobbyPlayer
	State        LobbyState
}

type LobbyRegistry struct {
	lobbies      *objects.SharedCollection[*Lobby]
	clientToLobby sync.Map // map[uint64]uint64  (clientID → lobbyID)
	mu            sync.RWMutex
}

func NewLobbyRegistry() *LobbyRegistry {
	return &LobbyRegistry{
		lobbies: objects.NewSharedCollection[*Lobby](),
	}
}

func hashPassword(password string) string {
	h := sha256.Sum256([]byte(password))
	return fmt.Sprintf("%x", h)
}

func (r *LobbyRegistry) CreateLobby(hostID uint64, hostUsername, name, format string, maxPlayers int, isPrivate bool, password string) *Lobby {
	r.mu.Lock()
	defer r.mu.Unlock()

	lobby := &Lobby{
		Name:         name,
		Format:       format,
		MaxPlayers:   maxPlayers,
		IsPrivate:    isPrivate,
		HostID:       hostID,
		HostUsername: hostUsername,
		Players:      make(map[uint64]*LobbyPlayer),
		State:        LobbyWaiting,
	}

	if password != "" {
		lobby.PasswordHash = hashPassword(password)
	}

	id := r.lobbies.Add(lobby)
	lobby.ID = id

	// Add host as first player
	lobby.Players[hostID] = &LobbyPlayer{
		ClientID: hostID,
		Username: hostUsername,
		Ready:    false,
	}
	r.clientToLobby.Store(hostID, id)

	return lobby
}

type LobbyInfo struct {
	ID            uint64
	Name          string
	Format        string
	CurrentPlayers int
	MaxPlayers    int
	HostUsername  string
	IsPrivate     bool
}

func (r *LobbyRegistry) ListPublicLobbies() []LobbyInfo {
	r.mu.RLock()
	defer r.mu.RUnlock()

	var result []LobbyInfo
	r.lobbies.ForEach(func(_ uint64, lobby *Lobby) {
		if !lobby.IsPrivate {
			result = append(result, LobbyInfo{
				ID:            lobby.ID,
				Name:          lobby.Name,
				Format:        lobby.Format,
				CurrentPlayers: len(lobby.Players),
				MaxPlayers:    lobby.MaxPlayers,
				HostUsername:  lobby.HostUsername,
				IsPrivate:     lobby.IsPrivate,
			})
		}
	})
	return result
}

func (r *LobbyRegistry) FindLobby(id uint64) (*Lobby, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.lobbies.Get(id)
}

func (r *LobbyRegistry) JoinLobby(lobbyID uint64, clientID uint64, username string, password string) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	lobby, ok := r.lobbies.Get(lobbyID)
	if !ok {
		return fmt.Errorf("lobby not found")
	}

	if len(lobby.Players) >= lobby.MaxPlayers {
		return fmt.Errorf("lobby is full")
	}

	if lobby.PasswordHash != "" {
		if password == "" {
			return fmt.Errorf("password required")
		}
		if hashPassword(password) != lobby.PasswordHash {
			return fmt.Errorf("invalid password")
		}
	}

	lobby.Players[clientID] = &LobbyPlayer{
		ClientID: clientID,
		Username: username,
		Ready:    false,
	}
	r.clientToLobby.Store(clientID, lobbyID)
	return nil
}

func (r *LobbyRegistry) LeaveLobby(clientID uint64) (*Lobby, error) {
	r.mu.Lock()
	defer r.mu.Unlock()

	val, ok := r.clientToLobby.Load(clientID)
	if !ok {
		return nil, fmt.Errorf("client not in any lobby")
	}
	lobbyID := val.(uint64)

	lobby, ok := r.lobbies.Get(lobbyID)
	if !ok {
		r.clientToLobby.Delete(clientID)
		return nil, fmt.Errorf("lobby not found")
	}

	delete(lobby.Players, clientID)
	r.clientToLobby.Delete(clientID)

	// If lobby is empty, remove it
	if len(lobby.Players) == 0 {
		r.lobbies.Delete(lobbyID)
		return nil, nil
	}

	// If host left, assign new host
	if lobby.HostID == clientID {
		for cid := range lobby.Players {
			lobby.HostID = cid
			break
		}
	}

	return lobby, nil
}

func (r *LobbyRegistry) SetReady(clientID uint64, ready bool) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	val, ok := r.clientToLobby.Load(clientID)
	if !ok {
		return fmt.Errorf("client not in any lobby")
	}
	lobbyID := val.(uint64)

	lobby, ok := r.lobbies.Get(lobbyID)
	if !ok {
		return fmt.Errorf("lobby not found")
	}

	player, ok := lobby.Players[clientID]
	if !ok {
		return fmt.Errorf("player not found in lobby")
	}
	player.Ready = ready
	return nil
}

func (r *LobbyRegistry) StartGame(lobbyID uint64, requestedBy uint64) error {
	r.mu.Lock()
	defer r.mu.Unlock()

	lobby, ok := r.lobbies.Get(lobbyID)
	if !ok {
		return fmt.Errorf("lobby not found")
	}

	// Only host can start
	if lobby.HostID != requestedBy {
		return fmt.Errorf("only host can start the game")
	}

	// Check all players are ready
	for _, p := range lobby.Players {
		if !p.Ready {
			return fmt.Errorf("not all players are ready")
		}
	}

	lobby.State = LobbyInGame
	return nil
}

func (r *LobbyRegistry) GetLobbyByClient(clientID uint64) (*Lobby, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()

	val, ok := r.clientToLobby.Load(clientID)
	if !ok {
		return nil, false
	}
	lobbyID := val.(uint64)
	return r.lobbies.Get(lobbyID)
}

func (r *LobbyRegistry) RemoveLobby(id uint64) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.lobbies.Delete(id)
}

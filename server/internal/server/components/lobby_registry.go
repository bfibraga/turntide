package components

import (
	"crypto/sha256"
	"fmt"
	"strings"
	"sync"
	"time"

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

func NewLobbyPlayer(clientID uint64, username string, ready bool) *LobbyPlayer {
	return &LobbyPlayer{
		ClientID: clientID,
		Username: username,
		Ready:    ready,
	}
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

type LobbyBuilder struct {
	id           uint64
	name         string
	format       string
	maxPlayers   int
	isPrivate    bool
	passwordHash string
	hostID       uint64
	hostUsername string
	players      map[uint64]*LobbyPlayer
	state        LobbyState
}

func NewLobbyBuilder() *LobbyBuilder {
	return &LobbyBuilder{
		players: make(map[uint64]*LobbyPlayer),
		state:   LobbyWaiting,
	}
}

func (lb *LobbyBuilder) WithID(id uint64) *LobbyBuilder {
	lb.id = id
	return lb
}

func (lb *LobbyBuilder) WithName(name string) *LobbyBuilder {
	lb.name = name
	return lb
}

func (lb *LobbyBuilder) WithFormat(format string) *LobbyBuilder {
	lb.format = format
	return lb
}

func (lb *LobbyBuilder) WithMaxPlayers(maxPlayers int) *LobbyBuilder {
	lb.maxPlayers = maxPlayers
	return lb
}

func (lb *LobbyBuilder) WithIsPrivate(isPrivate bool) *LobbyBuilder {
	lb.isPrivate = isPrivate
	return lb
}

func (lb *LobbyBuilder) WithPasswordHash(passwordHash string) *LobbyBuilder {
	lb.passwordHash = passwordHash
	return lb
}

func (lb *LobbyBuilder) WithHostID(hostID uint64) *LobbyBuilder {
	lb.hostID = hostID
	return lb
}

func (lb *LobbyBuilder) WithHostUsername(hostUsername string) *LobbyBuilder {
	lb.hostUsername = hostUsername
	return lb
}

func (lb *LobbyBuilder) WithPlayers(players map[uint64]*LobbyPlayer) *LobbyBuilder {
	lb.players = players
	return lb
}

func (lb *LobbyBuilder) WithState(state LobbyState) *LobbyBuilder {
	lb.state = state
	return lb
}

func (lb *LobbyBuilder) Build() *Lobby {
	return &Lobby{
		ID:           lb.id,
		Name:         lb.name,
		Format:       lb.format,
		MaxPlayers:   lb.maxPlayers,
		IsPrivate:    lb.isPrivate,
		PasswordHash: lb.passwordHash,
		HostID:       lb.hostID,
		HostUsername: lb.hostUsername,
		Players:      lb.players,
		State:        lb.state,
	}
}

type LobbyRegistry struct {
	lobbies       *objects.SharedCollection[*Lobby]
	clientToLobby sync.Map // map[uint64]uint64  (clientID → lobbyID)
	mu            sync.RWMutex
	// timers for scheduled lobby removals (grace period when empty)
	timers map[uint64]*time.Timer
	// ttl to keep empty lobbies around before deletion
	ttl time.Duration
	// onChange callback is invoked when the public lobby set changes
	onChange func()
}

type LobbyConfig struct {
	ttl time.Duration
}

// NewLobbyConfig creates a new LobbyConfig with the specified TTL.
func NewLobbyConfig(ttl time.Duration) *LobbyConfig {
	return &LobbyConfig{ttl: ttl}
}

// DefaultLobbyConfig returns the default lobby configuration with a TTL of 1 minute.
func DefaultLobbyConfig() *LobbyConfig {
	return NewLobbyConfig(time.Minute) // default TTL is 1 minute
}

func NewLobbyRegistry(config *LobbyConfig) *LobbyRegistry {
	return &LobbyRegistry{
		lobbies: objects.NewSharedCollection[*Lobby](),
		timers:  make(map[uint64]*time.Timer),
		ttl:     config.ttl,
	}
}

func hashPassword(password string) string {
	h := sha256.Sum256([]byte(password))
	return fmt.Sprintf("%x", h)
}

// SetTTL sets the duration empty lobbies are kept before being removed.
// Useful for tests to shorten the TTL.
func (r *LobbyRegistry) SetTTL(d time.Duration) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.ttl = d
}

// SetOnChange registers a callback to be invoked whenever public lobbies change
// (created/removed or otherwise updated).
func (r *LobbyRegistry) SetOnChange(cb func()) {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.onChange = cb
}

func (r *LobbyRegistry) CreateLobby(hostID uint64, hostUsername, name, format string, maxPlayers int, isPrivate bool, password string) *Lobby {
	r.mu.Lock()
	defer r.mu.Unlock()

	lobby := NewLobbyBuilder().
		WithHostID(hostID).
		WithHostUsername(hostUsername).
		WithName(name).
		WithFormat(format).
		WithMaxPlayers(maxPlayers).
		WithIsPrivate(isPrivate).
		Build()

	if password != "" {
		lobby.PasswordHash = hashPassword(password)
	}

	id := r.lobbies.Add(lobby)
	lobby.ID = id

	// Add host as first player
	lobby.Players[hostID] = NewLobbyPlayer(hostID, hostUsername, false)
	r.clientToLobby.Store(hostID, id)

	// If there was a scheduled removal for this id, cancel it
	if t, ok := r.timers[id]; ok {
		t.Stop()
		delete(r.timers, id)
	}

	if r.onChange != nil {
		go r.onChange()
	}

	return lobby
}

type LobbyInfo struct {
	ID             uint64
	Name           string
	Format         string
	CurrentPlayers int
	MaxPlayers     int
	HostUsername   string
	IsPrivate      bool
}

type ListLobbyFilter func(lobby *Lobby) bool

type ListLobbiesOptions struct {
	Page     int
	PageSize int

	Name   *string
	Format *string
	State  *LobbyState
}

func NewListLobbiesOptions(page, page_size int, name, format *string, state *LobbyState) *ListLobbiesOptions {
	return &ListLobbiesOptions{
		Page:     page,
		PageSize: page_size,

		Name:   name,
		Format: format,
		State:  state,
	}
}

type ListLobbiesResult struct {
	Count   int
	Lobbies []*Lobby
}

func (r *LobbyRegistry) ListLobbies(options *ListLobbiesOptions) *ListLobbiesResult {
	r.mu.RLock()
	defer r.mu.RUnlock()

	page := max(1, options.Page) // 1-indexed
	pageSize := max(1, min(50, options.PageSize))
	offset := (page - 1) * pageSize

	all := r.lobbies.Filter(func(_ uint64, lobby *Lobby) bool {

		if lobby.IsPrivate {
			return false
		}

		if options.Name != nil && !strings.Contains(lobby.Name, *options.Name) {
			return false
		}

		if options.Format != nil && lobby.Format != *options.Format {
			return false
		}

		if options.State != nil && *options.State != lobby.State {
			return false
		}

		return true
	}).Items()

	total := len(all)
	if offset >= total {
		return &ListLobbiesResult{
			Count:   0,
			Lobbies: make([]*Lobby, 0),
		}
	}

	end := min(offset+pageSize, total)

	result := make([]*Lobby, 0, end-offset)
	for _, info := range all[offset:end] {
		result = append(result, info)
	}

	return &ListLobbiesResult{
		Count:   len(result),
		Lobbies: result,
	}
}

func (r *LobbyRegistry) ListPublicLobbies() []LobbyInfo {
	r.mu.RLock()
	defer r.mu.RUnlock()

	publicLobbies := r.lobbies.Filter(func(_ uint64, lobby *Lobby) bool {
		return !lobby.IsPrivate
	})

	result := objects.Map(publicLobbies, func(_ uint64, lobby *Lobby) LobbyInfo {
		return LobbyInfo{
			ID:             lobby.ID,
			Name:           lobby.Name,
			Format:         lobby.Format,
			CurrentPlayers: len(lobby.Players),
			MaxPlayers:     lobby.MaxPlayers,
			HostUsername:   lobby.HostUsername,
			IsPrivate:      lobby.IsPrivate,
		}
	}).Items()

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

	// If a removal timer was scheduled because the lobby became empty, cancel it
	if t, ok := r.timers[lobbyID]; ok {
		if t.Stop() {
			delete(r.timers, lobbyID)
		}
	}

	if r.onChange != nil {
		go r.onChange()
	}

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

	// If lobby is empty, schedule removal after TTL
	if len(lobby.Players) == 0 {
		// schedule removal
		if r.ttl == 0 {
			r.lobbies.Delete(lobbyID)
			if r.onChange != nil {
				go r.onChange()
			}
			return nil, nil
		}

		// If a timer already exists, stop it first
		if t, ok := r.timers[lobbyID]; ok {
			t.Stop()
			delete(r.timers, lobbyID)
		}

		// Capture lobbyID for closure
		id := lobbyID
		timer := time.AfterFunc(r.ttl, func() {
			r.mu.Lock()
			defer r.mu.Unlock()

			// verify the lobby still exists and is empty
			l, ok := r.lobbies.Get(id)
			if !ok {
				delete(r.timers, id)
				return
			}
			if len(l.Players) == 0 {
				r.lobbies.Delete(id)
				delete(r.timers, id)
				if r.onChange != nil {
					// Call in a goroutine to avoid blocking the timer goroutine
					go r.onChange()
				}
			}
		})
		r.timers[lobbyID] = timer

		// Treat as removed for caller semantics
		return nil, nil
	}

	// If host left, assign new host
	if lobby.HostID == clientID {
		for cid := range lobby.Players {
			lobby.HostID = cid
			break
		}
	}

	if r.onChange != nil {
		go r.onChange()
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

	// Stop any pending timer
	if t, ok := r.timers[id]; ok {
		t.Stop()
		delete(r.timers, id)
	}

	r.lobbies.Delete(id)

	if r.onChange != nil {
		go r.onChange()
	}
}

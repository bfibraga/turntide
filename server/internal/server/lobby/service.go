package lobby

import (
	"context"
	"crypto/sha256"
	"fmt"
	"sync"
	"time"

	"github.com/bfibraga/turntide/core/pkg/repository"
)

type Config struct {
	ttl time.Duration
}

func NewConfig(ttl time.Duration) *Config {
	return &Config{ttl: ttl}
}

func DefaultConfig() *Config {
	return NewConfig(time.Minute)
}

type Service struct {
	repo     repository.LobbyRepository
	ttl      time.Duration
	timers   map[uint64]*time.Timer
	mu       sync.Mutex
	onChange func()
}

func NewService(repo repository.LobbyRepository, config *Config) *Service {
	return &Service{
		repo:   repo,
		ttl:    config.ttl,
		timers: make(map[uint64]*time.Timer),
	}
}

func hashPassword(password string) string {
	h := sha256.Sum256([]byte(password))
	return fmt.Sprintf("%x", h)
}

func (s *Service) SetTTL(d time.Duration) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.ttl = d
	s.repo.SetTTL(d)
}

func (s *Service) SetOnChange(cb func()) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.onChange = cb
}

func (s *Service) triggerOnChange() {
	s.mu.Lock()
	cb := s.onChange
	s.mu.Unlock()
	if cb != nil {
		go cb()
	}
}

func (s *Service) CreateLobby(ctx context.Context, hostID uint64, hostUsername, name, format string, maxPlayers int, isPrivate bool, password *string) (*repository.Lobby, error) {
	lobby := &repository.Lobby{
		HostID:       hostID,
		HostUsername: hostUsername,
		Name:         name,
		Format:       format,
		MaxPlayers:   maxPlayers,
		IsPrivate:    isPrivate,
		Players:      make(map[uint64]*repository.LobbyPlayer),
		State:        repository.LobbyWaiting,
	}

	return s.AddLobby(ctx, lobby, password)
}

func (s *Service) AddLobby(ctx context.Context, lobby *repository.Lobby, password *string) (*repository.Lobby, error) {
	if password != nil {
		lobby.PasswordHash = hashPassword(*password)
	}

	// Add host as first player
	lobby.Players[lobby.HostID] = &repository.LobbyPlayer{
		ClientID: lobby.HostID,
		Username: lobby.HostUsername,
		Ready:    false,
	}

	created, err := s.repo.Create(ctx, lobby)
	if err != nil {
		return nil, err
	}

	s.cancelTimer(created.ID)
	s.triggerOnChange()

	return created, nil
}

func (s *Service) JoinLobby(ctx context.Context, lobbyID uint64, clientID uint64, username string, password *string) error {
	lobby, err := s.repo.GetByID(ctx, lobbyID)
	if err != nil {
		return err
	}
	if lobby == nil {
		return fmt.Errorf("lobby not found")
	}

	if len(lobby.Players) >= lobby.MaxPlayers {
		return fmt.Errorf("lobby is full")
	}

	if lobby.PasswordHash != "" {
		if password == nil {
			return fmt.Errorf("password required")
		} else if hashPassword(*password) != lobby.PasswordHash {
			return fmt.Errorf("invalid password")
		}
	}

	lobby.Players[clientID] = &repository.LobbyPlayer{
		ClientID: clientID,
		Username: username,
		Ready:    false,
	}

	if err := s.repo.Update(ctx, lobby); err != nil {
		return err
	}

	s.cancelTimer(lobbyID)
	s.triggerOnChange()

	return nil
}

func (s *Service) LeaveLobby(ctx context.Context, clientID uint64) (*repository.Lobby, error) {
	lobby, err := s.repo.GetByClientID(ctx, clientID)
	if err != nil {
		return nil, err
	}
	if lobby == nil {
		return nil, fmt.Errorf("client not in any lobby")
	}

	delete(lobby.Players, clientID)

	if len(lobby.Players) == 0 {
		if err := s.repo.Update(ctx, lobby); err != nil {
			return nil, err
		}

		if s.ttl == 0 {
			if err := s.repo.Delete(ctx, lobby.ID); err != nil {
				return nil, err
			}
			s.triggerOnChange()
			return nil, nil
		}

		s.scheduleRemoval(ctx, lobby.ID)
		return nil, nil
	}

	// If host left, assign new host
	if lobby.HostID == clientID {
		for cid := range lobby.Players {
			lobby.HostID = cid
			break
		}
	}

	if err := s.repo.Update(ctx, lobby); err != nil {
		return nil, err
	}

	s.triggerOnChange()

	return lobby, nil
}

func (s *Service) scheduleRemoval(ctx context.Context, lobbyID uint64) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// If a timer already exists, stop it first
	if t, ok := s.timers[lobbyID]; ok {
		t.Stop()
		delete(s.timers, lobbyID)
	}

	id := lobbyID
	timer := time.AfterFunc(s.ttl, func() {
		l, err := s.repo.GetByID(ctx, id)
		if err != nil || l == nil {
			s.mu.Lock()
			delete(s.timers, id)
			s.mu.Unlock()
			return
		}
		if len(l.Players) == 0 {
			s.repo.Delete(ctx, id)
			s.mu.Lock()
			delete(s.timers, id)
			s.mu.Unlock()
			s.triggerOnChange()
		}
	})
	s.timers[lobbyID] = timer
}

func (s *Service) cancelTimer(lobbyID uint64) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if t, ok := s.timers[lobbyID]; ok {
		if t.Stop() {
			delete(s.timers, lobbyID)
		}
	}
}

func (s *Service) SetReady(ctx context.Context, clientID uint64, ready bool) (*repository.LobbyPlayer, error) {
	lobby, err := s.repo.GetByClientID(ctx, clientID)
	if err != nil {
		return nil, err
	}
	if lobby == nil {
		return nil, fmt.Errorf("client not in any lobby")
	}

	player, ok := lobby.Players[clientID]
	if !ok {
		return nil, fmt.Errorf("player not found in lobby")
	}
	player.Ready = ready

	if err := s.repo.Update(ctx, lobby); err != nil {
		return nil, err
	}

	return player, nil
}

func (s *Service) StartGame(ctx context.Context, lobbyID uint64, requestedBy uint64) error {
	lobby, err := s.repo.GetByID(ctx, lobbyID)
	if err != nil {
		return err
	}
	if lobby == nil {
		return fmt.Errorf("lobby not found")
	}

	if lobby.HostID != requestedBy {
		return fmt.Errorf("only host can start the game")
	}

	for _, p := range lobby.Players {
		if !p.Ready {
			return fmt.Errorf("not all players are ready")
		}
	}

	lobby.State = repository.LobbyInGame

	return s.repo.Update(ctx, lobby)
}

func (s *Service) FindLobby(ctx context.Context, id uint64) (*repository.Lobby, bool) {
	lobby, err := s.repo.GetByID(ctx, id)
	return lobby, lobby != nil && err == nil
}

func (s *Service) GetLobbyByClient(ctx context.Context, clientID uint64) (*repository.Lobby, bool) {
	lobby, err := s.repo.GetByClientID(ctx, clientID)
	return lobby, lobby != nil && err == nil
}

func (s *Service) ListLobbies(ctx context.Context, options *repository.ListLobbiesOptions) *repository.ListLobbiesResult {
	result, err := s.repo.List(ctx, options)
	if err != nil || result == nil {
		return &repository.ListLobbiesResult{
			Count:   0,
			Lobbies: make([]*repository.Lobby, 0),
		}
	}
	return result
}

func (s *Service) RemoveLobby(ctx context.Context, id uint64) {
	s.cancelTimer(id)
	s.repo.Delete(ctx, id)
	s.triggerOnChange()
}

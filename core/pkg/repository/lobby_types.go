package repository

type LobbyState int

const (
	LobbyWaiting LobbyState = iota
	LobbyReady
	LobbyInGame
)

func ConvertToLobbyState(rawState int) *LobbyState {
	var state LobbyState
	if rawState != 0 {
		state = LobbyState(rawState)
	}
	return &state
}

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

type LobbyInfo struct {
	ID             uint64
	Name           string
	Format         string
	CurrentPlayers int
	MaxPlayers     int
	HostUsername   string
	IsPrivate      bool
}

type ListLobbiesOptions struct {
	Page     int
	PageSize int
	Name     *string
	Format   *string
	State    *LobbyState
}

type ListLobbiesResult struct {
	Count   int
	Lobbies []*Lobby
}

package packets

import (
	"time"
)

type Msg = isPacket_Msg

func NewPacket(senderId uint64, msg Msg) *Packet {
	return &Packet{
		SenderId: senderId,
		Msg:      msg,
	}
}

func NewPing(time time.Time) Msg {
	return &Packet_Ping{
		Ping: &PingMessage{
			Timestamp: uint64(time.UnixNano()),
		},
	}
}

func NewPingNow() Msg {
	return NewPing(time.Now())
}

func NewChat(msg string) Msg {
	return &Packet_Chat{
		Chat: &ChatMessage{
			Msg: msg,
		},
	}
}

func NewId(id uint64) Msg {
	return &Packet_Id{
		Id: &IdMessage{
			Id: id,
		},
	}
}

func NewLoginRequest(username, password string) Msg {
	return &Packet_LoginRequest{
		LoginRequest: &LoginRequestMessage{
			Username: username,
			Password: password,
		},
	}
}

func NewRegisterRequest(username, password string) Msg {
	return &Packet_RegisterRequest{
		RegisterRequest: &RegisterRequestMessage{
			Username: username,
			Password: password,
		},
	}
}

func NewOkResponse() Msg {
	return &Packet_OkResponse{
		OkResponse: &OkResponseMessage{},
	}
}

func NewDenyResponse(reason string) Msg {
	return &Packet_DenyResponse{
		DenyResponse: &DenyResponseMessage{
			Reason: reason,
		},
	}
}

// Lobby packets

func NewLobbyListRequest() Msg {
	return &Packet_LobbyListRequest{
		LobbyListRequest: &LobbyListRequest{},
	}
}

func NewLobbyListResponse(lobbies []*LobbyInfo) Msg {
	return &Packet_LobbyListResponse{
		LobbyListResponse: &LobbyListResponse{Lobbies: lobbies},
	}
}

func NewLobbyInfo(lobbyId uint64, lobbyName, hostUsername string, maxPlayers int32, format string, currentPlayers int32) *LobbyInfo {
	return &LobbyInfo{
		Id:             lobbyId,
		Name:           lobbyName,
		HostUsername:   hostUsername,
		MaxPlayers:     maxPlayers,
		Format:         format,
		CurrentPlayers: currentPlayers,
	}
}

func NewLobbyCreateRequest(name, format string, maxPlayers int32, isPrivate bool, password *string) Msg {
	return &Packet_LobbyCreateRequest{
		LobbyCreateRequest: &LobbyCreateRequest{
			Name:       name,
			Format:     format,
			MaxPlayers: maxPlayers,
			IsPrivate:  isPrivate,
			Password:   password,
		},
	}
}

func NewLobbyJoinRequest(lobbyId uint64) Msg {
	return &Packet_LobbyJoinRequest{
		LobbyJoinRequest: &LobbyJoinRequest{
			LobbyId: lobbyId,
		},
	}
}

func NewLobbyJoinedResponse(lobbyId uint64, lobbyName, hostUsername string, players []*LobbyPlayer) Msg {
	return &Packet_LobbyJoinedResponse{
		LobbyJoinedResponse: &LobbyJoinedResponse{
			LobbyId:      lobbyId,
			LobbyName:    lobbyName,
			HostUsername: hostUsername,
			Players:      players,
		},
	}
}

func NewLobbyPlayer(username string, clientId uint64, ready bool) *LobbyPlayer {
	return &LobbyPlayer{
		Username: username,
		ClientId: clientId,
		Ready:    ready,
	}
}

func NewLobbyPlayerJoined(player *LobbyPlayer) Msg {
	return &Packet_LobbyPlayerJoined{
		LobbyPlayerJoined: &LobbyPlayerJoined{
			Player: player,
		},
	}
}

func NewLobbyPlayerLeft(clientId uint64) Msg {
	return &Packet_LobbyPlayerLeft{
		LobbyPlayerLeft: &LobbyPlayerLeft{
			ClientId: clientId,
		},
	}
}

func NewLobbyPlayerReady(clientId uint64, ready bool) Msg {
	return &Packet_LobbyPlayerReady{
		LobbyPlayerReady: &LobbyPlayerReady{
			ClientId: clientId,
			Ready:    ready,
		},
	}
}

func NewLobbyStartRequest() Msg {
	return &Packet_LobbyStartRequest{
		LobbyStartRequest: &LobbyStartRequest{},
	}
}

func NewLobbyLeaveRequest() Msg {
	return &Packet_LobbyLeaveRequest{
		LobbyLeaveRequest: &LobbyLeaveRequest{},
	}
}

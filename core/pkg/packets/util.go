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

func NewLobbyPlayer(client_id uint64, username string, is_ready bool) *LobbyPlayerData {
	return &LobbyPlayerData{
		ClientId: client_id,
		Username: username,
		IsReady:  is_ready,
	}
}

// List

func NewListLobbiesRequest() Msg {
	return &Packet_ListLobbiesRequest{}
}

func NewListLobbiesResponse(count int32, lobbies ...*LobbyData) Msg {
	return &Packet_ListLobbiesResponse{
		ListLobbiesResponse: &ListLobbiesResponse{
			Count:   count,
			Lobbies: lobbies,
		},
	}
}

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

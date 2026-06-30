package packets

type LobbyDataBuilder struct {
	data *LobbyData
}

func NewLobbyDataBuilder() *LobbyDataBuilder {
	return &LobbyDataBuilder{
		data: &LobbyData{},
	}
}

func (b *LobbyDataBuilder) WithID(id uint64) *LobbyDataBuilder {
	b.data.Id = id
	return b
}

func (b *LobbyDataBuilder) WithName(name string) *LobbyDataBuilder {
	b.data.Name = name
	return b
}

func (b *LobbyDataBuilder) WithCurrentPlayers(n int32) *LobbyDataBuilder {
	b.data.CurrentPlayers = n
	return b
}

func (b *LobbyDataBuilder) WithMaxPlayers(n int32) *LobbyDataBuilder {
	b.data.MaxPlayers = n
	return b
}

func (b *LobbyDataBuilder) Build() *LobbyData {
	return b.data
}

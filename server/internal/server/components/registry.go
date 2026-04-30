package components

import (
	"github.com/bfibraga/turntide/server/internal/objects"
	"github.com/bfibraga/turntide/server/internal/server"
)

type ClientRegistry struct {
	clients *objects.SharedCollection[server.ClientInterfacer]
}

func NewClientRegistry() *ClientRegistry {
	return &ClientRegistry{
		clients: objects.NewSharedCollection[server.ClientInterfacer](),
	}
}

func (r *ClientRegistry) Add(client server.ClientInterfacer) uint64 {
	return r.clients.Add(client)
}

func (r *ClientRegistry) Get(id uint64) (server.ClientInterfacer, bool) {
	return r.clients.Get(id)
}

func (r *ClientRegistry) Delete(id uint64) {
	r.clients.Delete(id)
}

func (r *ClientRegistry) ForEach(f func(id uint64, client server.ClientInterfacer)) {
	r.clients.ForEach(f)
}

func (r *ClientRegistry) Size() int {
	return r.clients.Size()
}

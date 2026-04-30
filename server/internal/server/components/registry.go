package components

import (
	"github.com/bfibraga/turntide/server/internal/objects"
)

type ClientRegistry struct {
	clients *objects.SharedCollection[ClientInterfacer]
}

func NewClientRegistry() *ClientRegistry {
	return &ClientRegistry{
		clients: objects.NewSharedCollection[ClientInterfacer](),
	}
}

func (r *ClientRegistry) Add(client ClientInterfacer) uint64 {
	return r.clients.Add(client)
}

func (r *ClientRegistry) Get(id uint64) (ClientInterfacer, bool) {
	return r.clients.Get(id)
}

func (r *ClientRegistry) Delete(id uint64) {
	r.clients.Delete(id)
}

func (r *ClientRegistry) ForEach(f func(id uint64, client ClientInterfacer)) {
	r.clients.ForEach(f)
}

func (r *ClientRegistry) Size() int {
	return r.clients.Size()
}

package objects

import (
	"maps"
	"sync"
)

type SharedCollection[T any] struct {
	items  map[uint64]T
	mu     sync.RWMutex
	nextId uint64
}

func NewSharedCollection[T any](capacity ...int) *SharedCollection[T] {
	cap := 0
	if len(capacity) > 0 {
		cap = capacity[0]
	}
	return &SharedCollection[T]{
		items: make(map[uint64]T, cap),
	}
}

func (s *SharedCollection[T]) Add(value T) uint64 {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.nextId++
	s.items[s.nextId] = value
	return s.nextId
}

func (s *SharedCollection[T]) Get(key uint64) (T, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	v, ok := s.items[key]
	return v, ok
}

func (s *SharedCollection[T]) Delete(key uint64) {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.items, key)
}

func (s *SharedCollection[T]) Size() int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return len(s.items)
}

func (s *SharedCollection[T]) ForEach(f func(key uint64, value T)) {
	s.mu.Lock()
	copy := maps.Clone(s.items)
	s.mu.Unlock()

	for k, v := range copy {
		f(k, v)
	}
}

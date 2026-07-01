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

func (s *SharedCollection[T]) Set(key uint64, value T) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.items[key] = value
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

func (s *SharedCollection[T]) Items() []T {
	s.mu.RLock()
	defer s.mu.RUnlock()
	items := make([]T, 0, len(s.items))
	for _, v := range s.items {
		items = append(items, v)
	}
	return items
}

func (s *SharedCollection[T]) ForEach(f func(key uint64, value T)) {
	s.mu.Lock()
	copy := maps.Clone(s.items)
	s.mu.Unlock()

	for k, v := range copy {
		f(k, v)
	}
}

func (s *SharedCollection[T]) Filter(f func(key uint64, value T) bool) *SharedCollection[T] {
	s.mu.RLock()
	defer s.mu.RUnlock()

	result := NewSharedCollection[T]()
	for k, v := range s.items {
		if f(k, v) {
			result.Add(v)
		}
	}
	return result
}

func Map[T any, U any](s *SharedCollection[T], f func(key uint64, value T) U) *SharedCollection[U] {
	result := NewSharedCollection[U]()
	s.mu.RLock()
	for k, v := range s.items {
		result.Add(f(k, v))
	}
	s.mu.RUnlock()
	return result
}

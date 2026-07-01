package objects

import (
	"slices"
	"sort"
	"sync"
)

type SharedSlice[T any] struct {
	items []T
	mu    sync.RWMutex
}

func NewSharedSlice[T any](capacity ...int) *SharedSlice[T] {
	cap := 0
	if len(capacity) > 0 {
		cap = capacity[0]
	}

	return &SharedSlice[T]{
		items: make([]T, 0, cap),
	}
}

func FromArrayToSharedSlice[T any](array []T) *SharedSlice[T] {
	slice := NewSharedSlice[T](len(array))
	slice.items = slices.Clone(array)

	return slice
}

func FromMapToSharedSlice[K comparable, T any](items map[K]T) *SharedSlice[T] {
	slice := NewSharedSlice[T](len(items))

	for _, value := range items {
		slice.Add(value)
	}

	return slice
}

func (s *SharedSlice[T]) Add(value T) int {
	s.mu.Lock()
	defer s.mu.Unlock()

	s.items = append(s.items, value)

	return len(s.items) - 1
}

func (s *SharedSlice[T]) Get(index int) (T, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if index < 0 || index >= len(s.items) {
		var zero T
		return zero, false
	}

	return s.items[index], true
}

func (s *SharedSlice[T]) Set(index int, value T) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	if index < 0 || index >= len(s.items) {
		return false
	}
	s.items[index] = value
	return true
}

func (s *SharedSlice[T]) Remove(index int) bool {
	s.mu.Lock()
	defer s.mu.Unlock()

	if index < 0 || index >= len(s.items) {
		return false
	}
	s.items = append(s.items[:index], s.items[index+1:]...)
	return true
}

func (s *SharedSlice[T]) Size() int {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return len(s.items)
}

func (s *SharedSlice[T]) Items() []T {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return slices.Clone(s.items)
}

func (s *SharedSlice[T]) First() (T, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if len(s.items) == 0 {
		var zero T
		return zero, false
	}
	return s.items[0], true
}

func (s *SharedSlice[T]) Last() (T, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	if len(s.items) == 0 {
		var zero T
		return zero, false
	}
	return s.items[len(s.items)-1], true
}

func (s *SharedSlice[T]) ForEach(f func(int, T)) {
	s.mu.Lock()
	copy := slices.Clone(s.items)
	s.mu.Unlock()

	for i, v := range copy {
		f(i, v)
	}
}

func (s *SharedSlice[T]) Filter(f func(int, T) bool) *SharedSlice[T] {
	s.mu.RLock()
	defer s.mu.RUnlock()

	result := NewSharedSlice[T]()
	for i, v := range s.items {
		if f(i, v) {
			result.items = append(result.items, v)
		}
	}
	return result
}

func (s *SharedSlice[T]) Find(f func(int, T) bool) (T, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for i, v := range s.items {
		if f(i, v) {
			return v, true
		}
	}
	var zero T
	return zero, false
}

func (s *SharedSlice[T]) Some(f func(int, T) bool) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for i, v := range s.items {
		if f(i, v) {
			return true
		}
	}

	return false
}

func (s *SharedSlice[T]) Every(f func(int, T) bool) bool {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for i, v := range s.items {
		if !f(i, v) {
			return false
		}
	}

	return true
}

func (s *SharedSlice[T]) Sort(less func(a, b T) int) *SharedSlice[T] {
	s.mu.Lock()
	defer s.mu.Unlock()

	sort.Slice(s.items, func(i, j int) bool {
		return less(s.items[i], s.items[j]) < 0
	})

	return s
}

func MapSlice[T any, U any](s *SharedSlice[T], f func(int, T) U) *SharedSlice[U] {
	result := NewSharedSlice[U]()
	s.mu.RLock()

	for i, v := range s.items {
		result.items = append(result.items, f(i, v))
	}

	s.mu.RUnlock()
	return result
}

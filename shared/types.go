package shared

type Box[T any] struct {
	value *T
}

func NewBox[T any](value T) *Box[T] {
	return &Box[T]{value: &value}
}

func (b *Box[T]) Unwrap() T { return *b.value }

func (b *Box[T]) Deref() *T { return b.value }

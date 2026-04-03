package validation

type ValidationCallback[T any] func(value T) error

type Validator[T any] interface {
	With(callback ValidationCallback[T]) Validator[T]
	Validate() error
}

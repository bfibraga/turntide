/*
Copyright © 2026 Bruno Braga bf.braga@campus.fct.unl.pt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

package validation

import (
	"errors"
	"strings"
)

type baseValidator[T any] struct {
	value      T
	validators []ValidationCallback[T]
}

func newBaseValidator[T any](value T) *baseValidator[T] {
	return &baseValidator[T]{value: value}
}

func (v *baseValidator[T]) With(callback ValidationCallback[T]) Validator[T] {
	v.validators = append(v.validators, callback)
	return v
}

func (v *baseValidator[T]) Validate() error {
	for _, fn := range v.validators {
		err := fn(v.value)
		if err != nil {
			return err
		}
	}
	return nil
}

func NewPasswordValidator(password string) Validator[string] {
	return newBaseValidator(password)
}

func NewDefaultPasswordValidator(password string) Validator[string] {
	return NewPasswordValidator(password).
		With(func(value string) error {
			if len(value) <= 0 {
				return errors.New("empty string")
			}
			return nil
		}).
		With(func(value string) error {
			if value != strings.TrimSpace(value) {
				return errors.New("leading or trailing whitespace")
			}
			return nil
		})
}

func NewUsernameValidator(username string) Validator[string] {
	return newBaseValidator(username)
}

func NewDefaultUsernameValidator(username string) Validator[string] {
	return NewUsernameValidator(username).
		With(func(value string) error {
			if len(value) <= 0 {
				return errors.New("empty string")
			}
			return nil
		}).
		With(func(value string) error {
			if len(value) >= 20 {
				return errors.New("too long")
			}
			return nil
		}).
		With(func(value string) error {
			if value != strings.TrimSpace(value) {
				return errors.New("leading or trailing whitespace")
			}
			return nil
		})
}

type allOfValidator[T any] struct {
	validators []Validator[T]
}

func AllOf[T any](validators ...Validator[T]) Validator[T] {
	return &allOfValidator[T]{validators: validators}
}

func (v *allOfValidator[T]) With(callback ValidationCallback[T]) Validator[T] {
	return &allOfAndCallbackValidator[T]{
		validators: v.validators,
		callback:   callback,
	}
}

func (v *allOfValidator[T]) Validate() error {
	for _, validator := range v.validators {
		if err := validator.Validate(); err != nil {
			return err
		}
	}
	return nil
}

type allOfAndCallbackValidator[T any] struct {
	validators []Validator[T]
	callback   ValidationCallback[T]
}

func (v *allOfAndCallbackValidator[T]) With(cb ValidationCallback[T]) Validator[T] {
	v.callback = func(value T) error {
		if err := v.callback(value); err != nil {
			return err
		}
		return cb(value)
	}
	return v
}

func (v *allOfAndCallbackValidator[T]) Validate() error {
	for _, validator := range v.validators {
		if err := validator.Validate(); err != nil {
			return err
		}
	}
	var zero T
	return v.callback(zero)
}

type anyOfValidator[T any] struct {
	validators []Validator[T]
}

func AnyOf[T any](validators ...Validator[T]) Validator[T] {
	return &anyOfValidator[T]{validators: validators}
}

func (v *anyOfValidator[T]) With(callback ValidationCallback[T]) Validator[T] {
	return &anyOfAndCallbackValidator[T]{
		validators: v.validators,
		callback:   callback,
	}
}

func (v *anyOfValidator[T]) Validate() error {
	for _, validator := range v.validators {
		if err := validator.Validate(); err == nil {
			return nil
		}
	}
	return errors.New("no validator passed")
}

type anyOfAndCallbackValidator[T any] struct {
	validators []Validator[T]
	callback   ValidationCallback[T]
}

func (v *anyOfAndCallbackValidator[T]) With(cb ValidationCallback[T]) Validator[T] {
	v.callback = func(value T) error {
		if err := v.callback(value); err == nil {
			return nil
		}
		return cb(value)
	}
	return v
}

func (v *anyOfAndCallbackValidator[T]) Validate() error {
	for _, validator := range v.validators {
		if err := validator.Validate(); err == nil {
			var zero T
			return v.callback(zero)
		}
	}
	return errors.New("no validator passed")
}

type notValidator[T any] struct {
	validator Validator[T]
}

func Not[T any](validator Validator[T]) Validator[T] {
	return &notValidator[T]{validator: validator}
}

func (v *notValidator[T]) With(callback ValidationCallback[T]) Validator[T] {
	return &notAndCallbackValidator[T]{
		validator: v.validator,
		callback:  callback,
	}
}

func (v *notValidator[T]) Validate() error {
	err := v.validator.Validate()
	if err == nil {
		return errors.New("validation passed (should have failed)")
	}
	return nil
}

type notAndCallbackValidator[T any] struct {
	validator Validator[T]
	callback  ValidationCallback[T]
}

func (v *notAndCallbackValidator[T]) With(cb ValidationCallback[T]) Validator[T] {
	v.callback = func(value T) error {
		if err := v.callback(value); err != nil {
			return err
		}
		return cb(value)
	}
	return v
}

func (v *notAndCallbackValidator[T]) Validate() error {
	err := v.validator.Validate()
	if err == nil {
		return errors.New("validation passed (should have failed)")
	}
	var zero T
	return v.callback(zero)
}

type optionalValidator[T any] struct {
	validator Validator[T]
	emptyFn   func(T) bool
}

func Optional[T any](validator Validator[T], emptyFn func(T) bool) Validator[T] {
	return &optionalValidator[T]{validator: validator, emptyFn: emptyFn}
}

func (v *optionalValidator[T]) With(callback ValidationCallback[T]) Validator[T] {
	return &optionalAndCallbackValidator[T]{
		validator: v.validator,
		emptyFn:   v.emptyFn,
		callback:  callback,
	}
}

func (v *optionalValidator[T]) Validate() error {
	var zero T
	if v.emptyFn(zero) {
		return nil
	}
	return v.validator.Validate()
}

type optionalAndCallbackValidator[T any] struct {
	validator Validator[T]
	emptyFn   func(T) bool
	callback  ValidationCallback[T]
}

func (v *optionalAndCallbackValidator[T]) With(cb ValidationCallback[T]) Validator[T] {
	v.callback = func(value T) error {
		if err := v.callback(value); err != nil {
			return err
		}
		return cb(value)
	}
	return v
}

func (v *optionalAndCallbackValidator[T]) Validate() error {
	var zero T
	if v.emptyFn(zero) {
		return nil
	}
	if err := v.validator.Validate(); err != nil {
		return err
	}
	return v.callback(zero)
}

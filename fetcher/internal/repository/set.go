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
package repository

import (
	"context"

	"github.com/bfibraga/turntide/fetcher/internal/models"
)

// SetRepository defines the interface for set data access
type SetRepository interface {
	// GetByCode retrieves a set by its code
	GetByCode(ctx context.Context, code string) (*models.Set, error)

	// GetByName retrieves sets matching a name
	GetByName(ctx context.Context, name string) ([]*models.Set, error)

	// ListAll retrieves all sets with pagination
	ListAll(ctx context.Context, limit int32, offset int32) ([]*models.Set, error)

	// Count returns the total number of sets
	Count(ctx context.Context) (int64, error)

	// Close closes the underlying database connection
	Close() error
}

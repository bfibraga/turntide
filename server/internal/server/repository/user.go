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

	"github.com/bfibraga/turntide/server/internal/server/db"
)

// UserRepository defines the interface for user data access
type UserRepository interface {
	// Create creates a new user with the given username and password
	// Password should be plain text; it will be hashed before storing
	Create(ctx context.Context, username, password string) (*db.User, error)

	// GetByUsername retrieves a user by username
	GetByUsername(ctx context.Context, username string) (*db.User, error)

	// VerifyPassword verifies if the given password matches the user's stored hash
	VerifyPassword(ctx context.Context, username, password string) (bool, error)

	// Close closes the underlying database connection
	Close() error
}

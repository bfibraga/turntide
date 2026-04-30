package user

import (
	"context"
	"database/sql"
	"fmt"

	"github.com/bfibraga/turntide/server/internal/server/db"
)

// Repository defines the interface for user data access
type Repository interface {
	// Create creates a new user with the given username and password
	// Password should be plain text; it will be hashed before storing
	Create(ctx context.Context, username, password string) (*db.User, error)

	// GetByUsername retrieves a user by username
	GetByUsername(ctx context.Context, username string) (*db.User, error)

	// Close closes the underlying database connection
	Close() error
}

// SQLiteUserRepository implements UserRepository using sqlc
type SQLiteUserRepository struct {
	queries *db.Queries
	conn    *sql.DB
}

// NewSQLiteUserRepository creates a new SQLite user repository
func NewSQLiteUserRepository(conn *sql.DB) *SQLiteUserRepository {
	return &SQLiteUserRepository{
		queries: db.New(conn),
		conn:    conn,
	}
}

// Create implements UserRepository.Create
func (r *SQLiteUserRepository) Create(ctx context.Context, username, password string) (*db.User, error) {
	user, err := r.queries.CreateUser(ctx, db.CreateUserParams{
		Username:     username,
		PasswordHash: password,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return &user, nil
}

// GetByUsername implements UserRepository.GetByUsername
func (r *SQLiteUserRepository) GetByUsername(ctx context.Context, username string) (*db.User, error) {
	user, err := r.queries.GetUserByUsername(ctx, username)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("user not found")
		}
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return &user, nil
}

// Close implements UserRepository.Close
func (r *SQLiteUserRepository) Close() error {
	return r.conn.Close()
}

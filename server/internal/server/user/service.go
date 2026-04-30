package user

import (
	"context"
	"fmt"

	"github.com/bfibraga/turntide/server/internal/server/db"
	"golang.org/x/crypto/bcrypt"
)

type Service struct {
	repo Repository
}

func NewService(repo Repository) *Service {
	return &Service{
		repo: repo,
	}
}

func (s *Service) CreateUser(ctx context.Context, username, password string) error {
	// Hash the password using bcrypt
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to hash password: %w", err)
	}

	_, err = s.repo.Create(ctx, username, string(hashedPassword))

	return err
}

func (s *Service) GetUser(ctx context.Context, username string) (*db.User, error) {
	user, err := s.repo.GetByUsername(ctx, username)
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	return user, nil
}

func (s *Service) VerifyPassword(ctx context.Context, username, password string) (bool, error) {
	user, err := s.repo.GetByUsername(ctx, username)
	if err != nil {
		return false, fmt.Errorf("failed to get user: %w", err)
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password))
	if err != nil {
		return false, fmt.Errorf("invalid password: %w", err)
	}

	return true, nil
}

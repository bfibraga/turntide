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
package service

import (
	"context"
	"fmt"
	"github.com/bfibraga/turntide/core/pkg/repository"
)

// SetService provides business logic for set operations
type SetService struct {
	setRepo repository.SetRepository
}

// NewSetService creates a new SetService instance
func NewSetService(setRepo repository.SetRepository) *SetService {
	return &SetService{
		setRepo: setRepo,
	}
}

// GetSetByCode retrieves a set by its code
func (s *SetService) GetSetByCode(ctx context.Context, code string) (*repository.SetModel, error) {
	return s.setRepo.GetByCode(ctx, code)
}

// GetSetsByName retrieves sets by name
func (s *SetService) GetSetsByName(ctx context.Context, name string) ([]*repository.SetModel, error) {
	return s.setRepo.GetByName(ctx, name)
}

// ListAllSets retrieves all sets with pagination
func (s *SetService) ListAllSets(ctx context.Context, limit int32, offset int32) ([]* repository.SetModel, error) {
	return s.setRepo.ListAll(ctx, limit, offset)
}

// GetSetStatistics returns statistics about the sets in the database
func (s *SetService) GetSetStatistics(ctx context.Context) (map[string]interface{}, error) {
	count, err := s.setRepo.Count(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get set count: %w", err)
	}

	stats := map[string]interface{}{
		"total_sets": count,
	}

	return stats, nil
}

// Close closes the underlying repository connection
func (s *SetService) Close() error {
	return s.setRepo.Close()
}

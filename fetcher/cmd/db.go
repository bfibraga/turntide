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
package cmd

import (
	"context"
	"fmt"

	"github.com/spf13/cobra"

	"github.com/bfibraga/turntide/fetcher/internal/models"
	"github.com/bfibraga/turntide/fetcher/internal/repository"
	"github.com/bfibraga/turntide/fetcher/internal/service"
)

var (
	dbPath string
)

// dbCmd represents the database access command
var dbCmd = &cobra.Command{
	Use:   "db",
	Short: "Access the database through the repository pattern",
	Long: `Database operations using the repository pattern.
This command provides access to the cards database at /shared/resources/cards.db`,
}

// dbListCmd lists all cards from the database
var dbListCmd = &cobra.Command{
	Use:   "list",
	Short: "List all cards from the database",
	RunE: func(cmd *cobra.Command, args []string) error {
		// Initialize the repository factory
		factory, err := repository.NewFactory(dbPath)
		if err != nil {
			return fmt.Errorf("failed to initialize repository factory: %w", err)
		}
		defer factory.Close()

		// Create a card repository
		cardRepo := factory.NewCardRepository()

		// Create a service
		svc := service.NewCardService(cardRepo)

		// Get all cards with context
		ctx := context.Background()
		cards, err := svc.GetAllCards(ctx, &models.CardFilter{})
		if err != nil {
			return fmt.Errorf("failed to get cards: %w", err)
		}

		fmt.Printf("Found %d cards:\n", len(cards))
		for _, card := range cards {
			fmt.Printf("- %s (%s)\n", card.Name, card.SetCode)
		}

		return nil
	},
}

// dbCountCmd counts the total number of cards
var dbCountCmd = &cobra.Command{
	Use:   "count",
	Short: "Count total cards in the database",
	RunE: func(cmd *cobra.Command, args []string) error {
		factory, err := repository.NewFactory(dbPath)
		if err != nil {
			return fmt.Errorf("failed to initialize repository factory: %w", err)
		}
		defer factory.Close()

		cardRepo := factory.NewCardRepository()

		svc := service.NewCardService(cardRepo)
		ctx := context.Background()
		stats, err := svc.GetCardStatistics(ctx)
		if err != nil {
			return fmt.Errorf("failed to get statistics: %w", err)
		}

		fmt.Printf("Total cards: %d\n", stats["total_cards"])
		return nil
	},
}

func init() {
	rootCmd.AddCommand(dbCmd)

	dbCmd.PersistentFlags().StringVar(&dbPath, "db-path", "", "Path to the SQLite database (defaults to /shared/resources/cards.db)")

	dbCmd.AddCommand(dbListCmd)
	dbCmd.AddCommand(dbCountCmd)
}

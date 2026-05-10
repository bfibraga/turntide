package cmd

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"time"

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
This command provides type-safe access to the cards database.`,
}

// dbListCmd lists cards from the database with optional filtering
var dbListCmd = &cobra.Command{
	Use:   "list",
	Short: "List cards from the database",
	Long:  `List cards with optional filtering. Use flags to filter results.`,
	Run: func(cmd *cobra.Command, args []string) {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		logger := slog.Default()
		factory, err := repository.NewFactory(dbPath, logger)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to initialize repository factory: %v\n", err)
			os.Exit(ExitConfigError)
		}
		defer factory.Close()

		cardRepo := factory.NewCardRepository()
		cardService := service.NewCardService(cardRepo)

		cards, err := cardService.GetAllCards(ctx, &models.CardFilter{Limit: 20})
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to get cards: %v\n", err)
			os.Exit(ExitGeneralError)
		}

		fmt.Printf("Found %d cards (showing first 20):\n\n", len(cards))
		for _, card := range cards {
			fmt.Printf("Name: %s\n", card.Name)
			fmt.Printf("  Set: %s\n", card.SetCode)
			fmt.Printf("  Type: %s\n", card.CardType)
			fmt.Printf("  Cost: %d\n", card.Cost)
			fmt.Printf("  Rarity: %s\n", card.Rarity)
			fmt.Println()
		}
	},
}

// dbCountCmd counts the total number of cards
var dbCountCmd = &cobra.Command{
	Use:   "count",
	Short: "Count total cards in the database",
	Run: func(cmd *cobra.Command, args []string) {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		logger := slog.Default()
		factory, err := repository.NewFactory(dbPath, logger)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to initialize repository: %v\n", err)
			os.Exit(ExitConfigError)
		}
		defer factory.Close()

		cardRepo := factory.NewCardRepository()
		cardService := service.NewCardService(cardRepo)

		stats, err := cardService.GetCardStatistics(ctx)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to get statistics: %v\n", err)
			os.Exit(ExitGeneralError)
		}

		fmt.Printf("Total cards: %d\n", stats["total_cards"])
	},
}

// dbSearchCmd searches for cards by name
var dbSearchCmd = &cobra.Command{
	Use:   "search [name]",
	Short: "Search cards by name",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		logger := slog.Default()
		factory, err := repository.NewFactory(dbPath, logger)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to initialize repository: %v\n", err)
			os.Exit(ExitConfigError)
		}
		defer factory.Close()

		cardRepo := factory.NewCardRepository()
		cardService := service.NewCardService(cardRepo)

		cards, err := cardService.GetCardsByName(ctx, args[0])
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to search cards: %v\n", err)
			os.Exit(ExitGeneralError)
		}

		if len(cards) == 0 {
			fmt.Fprintf(os.Stderr, "Error: no cards found matching '%s'\n", args[0])
			os.Exit(ExitNotFound)
		}

		fmt.Printf("Found %d cards matching '%s':\n\n", len(cards), args[0])
		for _, card := range cards {
			fmt.Printf("- %s (%s)\n", card.Name, card.SetCode)
			fmt.Printf("  Rarity: %s\n", card.Rarity)
			fmt.Printf("  Type: %s\n", card.CardType)
			fmt.Println()
		}
	},
}

// dbSetCmd retrieves cards from a specific set
var dbSetCmd = &cobra.Command{
	Use:   "set [code]",
	Short: "Get all cards from a specific set",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()

		logger := slog.Default()
		factory, err := repository.NewFactory(dbPath, logger)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to initialize repository: %v\n", err)
			os.Exit(ExitConfigError)
		}
		defer factory.Close()

		cardRepo := factory.NewCardRepository()
		cardService := service.NewCardService(cardRepo)

		cards, err := cardService.GetCardsBySetCode(ctx, args[0])
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to get cards: %v\n", err)
			os.Exit(ExitGeneralError)
		}

		if len(cards) == 0 {
			fmt.Fprintf(os.Stderr, "Error: no cards found in set '%s'\n", args[0])
			os.Exit(ExitNotFound)
		}

		fmt.Printf("Found %d cards in set '%s'\n\n", len(cards), args[0])
		for _, card := range cards {
			fmt.Printf("- %s\n", card.Name)
			fmt.Printf("  Rarity: %s\n", card.Rarity)
			fmt.Printf("  Type: %s\n", card.CardType)
		}
	},
}

func init() {
	rootCmd.AddCommand(dbCmd)

	dbCmd.PersistentFlags().StringVar(&dbPath, "db-path", "", "Path to the SQLite database (defaults to /shared/resources/cards.db)")

	dbCmd.AddCommand(dbListCmd)
	dbCmd.AddCommand(dbCountCmd)
	dbCmd.AddCommand(dbSearchCmd)
	dbCmd.AddCommand(dbSetCmd)
}

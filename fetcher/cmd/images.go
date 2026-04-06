/*
Copyright © 2026 Bruno Braga bf.braga@campus.fct.unl.pt
*/
package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/bfibraga/turntide/fetcher/internal/images/providers"
	"github.com/bfibraga/turntide/fetcher/internal/parsers"
	"github.com/bfibraga/turntide/fetcher/internal/repository"
	"github.com/spf13/cobra"
)

var (
	format     string
	output     string
	decklist   string
	singleCard string
)

// imagesCmd represents the images command
var imagesCmd = &cobra.Command{
	Use:   "images",
	Short: "Download card printings",
	Long:  `Download card printings from Scryfall.`,
	Run: func(cmd *cobra.Command, args []string) {
		if singleCard != "" && decklist != "" {
			fmt.Fprintf(os.Stderr, "Error: cannot use both --card and --decklist flags\n")
			os.Exit(ExitInvalidUsage)
		}

		var cardData []parsers.TurntideCardData

		if singleCard != "" {
			cardData = parsers.ParseTurntide(singleCard)
			if len(cardData) == 0 {
				fmt.Fprintf(os.Stderr, "Error: invalid card format: %s\n", singleCard)
				os.Exit(ExitInvalidUsage)
			}
		} else {
			var err error
			cardData, err = parseDecklist(args)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error: %v\n", err)
				if os.IsNotExist(err) {
					os.Exit(ExitNotFound)
				}
				os.Exit(ExitConfigError)
			}
		}

		if output == "" {
			output = "card_images"
		}

		factory, err := repository.NewFactory(dbPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: failed to initialize repository factory: %v\n", err)
			os.Exit(ExitConfigError)
		}
		defer factory.Close()

		cardRepo := factory.NewCardRepository()

		err = providers.ScryfallDownload(cardData, cardRepo, output, format)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(ExitNetworkError)
		}

		fmt.Printf("Successfully downloaded images to %s\n", output)
	},
}

func parseDecklist(args []string) ([]parsers.TurntideCardData, error) {
	var deck string
	if decklist != "" {
		fd, err := os.ReadFile(decklist)
		if err != nil {
			return nil, fmt.Errorf("error reading decklist file: %w", err)
		}
		deck = string(fd)
	} else if len(args) > 0 {
		deck = strings.Join(args, "\n")
	} else {
		return nil, fmt.Errorf("please provide a decklist file or a deck name")
	}

	return parsers.ParseTurntide(deck), nil
}

func init() {
	rootCmd.AddCommand(imagesCmd)

	imagesCmd.Flags().StringVarP(&format, "format", "f", "png", "Output format (png, jpg, webp)")
	imagesCmd.Flags().StringVarP(&output, "output", "o", "", "Output directory")
	imagesCmd.Flags().StringVarP(&decklist, "decklist", "d", "", "Decklist file")
	imagesCmd.Flags().StringVarP(&singleCard, "card", "c", "", "Single card in format 'CardName [SetCode] [CardID]'")
	imagesCmd.Flags().StringVar(&dbPath, "db-path", "", "Path to the SQLite database (defaults to /shared/resources/cards.db)")
}

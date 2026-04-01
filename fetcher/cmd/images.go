/*
Copyright © 2026 Bruno Braga bf.braga@campus.fct.unl.pt
*/
package cmd

import (
	"fmt"
	"os"

	"github.com/bfibraga/turntide/fetcher/internal/images/providers"
	"github.com/bfibraga/turntide/fetcher/internal/parsers"
	"github.com/bfibraga/turntide/fetcher/internal/repository"
	"github.com/spf13/cobra"
)

var (
	format   string
	output   string
	decklist string
)

// imagesCmd represents the images command
var imagesCmd = &cobra.Command{
	Use:   "images",
	Short: "Download card printings",
	Long:  `Download card printings from Scryfall.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		cardData, err := parseDecklist(args)
		if err != nil {
			return err
		}

		if output == "" {
			output = "card_images"
		}

		factory, err := repository.NewFactory(dbPath)
		if err != nil {
			return fmt.Errorf("failed to initialize repository factory: %w", err)
		}
		defer factory.Close()

		cardRepo := factory.NewCardRepository()

		err = providers.ScryfallDownload(cardData, cardRepo, output, format)
		if err != nil {
			return err
		}

		fmt.Printf("Successfully downloaded images to %s\n", output)
		return nil
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
		deck = args[0]
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
}

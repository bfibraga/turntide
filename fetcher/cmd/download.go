/*
Copyright © 2026 Bruno Braga bf.braga@campus.fct.unl.pt
*/
package cmd

import (
	"fmt"
	"os"

	"github.com/bfibraga/turntide/fetcher/internal/download/providers"
	"github.com/spf13/cobra"
)

const (
	MTGJSONProvider  = "mtgjson"
	ScryfallProvider = "scryfall"
)

var (
	DbPath   string
	Provider string

	ErrInvalidProvider = fmt.Errorf("invalid provider")
)

func validate(args []string) error {
	if len(args) > 0 {
		return fmt.Errorf("arguments not empty")
	}

	return nil
}

func getProvider() func(string) error {
	invalid := func(string) error { return ErrInvalidProvider }

	switch Provider {
	case MTGJSONProvider:
		return providers.MTGJSONDownload
	default:
		return invalid
	}
}

// downloadCmd represents the download command
var downloadCmd = &cobra.Command{
	Use:   "download",
	Short: "Download card data from a repository",
	Long:  `Download card database files from various providers.`,
	Run: func(cmd *cobra.Command, args []string) {
		/*if err := validate(args); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(ExitInvalidUsage)
		}*/

		err := getProvider()(DbPath)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(ExitNetworkError)
		}

		fmt.Printf("Successfully downloaded \n")
	},
}

func init() {
	rootCmd.AddCommand(downloadCmd)

	downloadCmd.Flags().StringVarP(&DbPath, "db-path", "d", "shared/resources/cards.db", "Path to the database")
	downloadCmd.Flags().StringVarP(&Provider, "provider", "p", "mtgjson", "Provider to use: mtgjson, scryfall")
}

package main

import (
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"time"

	_ "modernc.org/sqlite"

	"github.com/lmittmann/tint"
	"github.com/mattn/go-colorable"
	"github.com/mattn/go-isatty"

	"github.com/bfibraga/turntide/core/pkg/repository"
	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/clients"
	"github.com/bfibraga/turntide/server/internal/server/user"
	"github.com/joho/godotenv"
)

var (
	defaultConfig = NewConfig(4000, "./server.db")
	configPath    = flag.String("config", ".env", "path to the config file")
)

func main() {
	// Set up logger
	writer := os.Stdout
	options := &tint.Options{
		Level: slog.LevelInfo,
		TimeFormat: time.Kitchen,
		NoColor: !isatty.IsTerminal(writer.Fd()),
		ReplaceAttr: func(groups []string, attr slog.Attr) slog.Attr {
			if attr.Key == "error" {
				return tint.Attr(13, slog.String(attr.Key, attr.Value.String()))
			}

			return attr
		},
	}
	handler := tint.NewHandler(colorable.NewColorable(writer), options)
	logger := slog.New(handler)
	slog.SetDefault(logger)

	// Load config
	flag.Parse()

	err := godotenv.Load(*configPath)
	cfg, err := LoadConfig(defaultConfig)
	if err != nil {
		logger.Error("failed to load config file, defaulting to env vars", "error", err)
	}	

	// Setup server factory, repositories and services
	factory, err := repository.NewServerFactory(cfg.DBPath, logger)
	userRepo := factory.CreateUserRepository()

	userService := user.NewService(userRepo)

	// Initialize hub  
	hub := server.NewHub(logger, userService)
	hub.Initialize()

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		hub.Serve(clients.NewWebSocketClient, w, r)
	})

	// Start the server
	go hub.Run()

	addr := fmt.Sprintf(":%d", cfg.Port)
	err = http.ListenAndServe(addr, nil)
	if err != nil {
		logger.Error("failed to start server", "error", err)
		os.Exit(1)
	}
}

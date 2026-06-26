package main

import (
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"

	//"path/filepath"
	"strings"

	_ "modernc.org/sqlite"

	"github.com/bfibraga/turntide/core/pkg/repository"
	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/clients"
	"github.com/bfibraga/turntide/server/internal/server/components"
	"github.com/bfibraga/turntide/server/internal/server/logger"
	"github.com/bfibraga/turntide/server/internal/server/user"
	"github.com/joho/godotenv"
)

const (
	dockerMountedDataDir  = "/gameserver/data"
	dockerMountedCertsDir = "/gameserver/certs"
)

var (
	defaultConfig = NewConfig(
		4000, "./data",
		strings.Join([]string{dockerMountedCertsDir, "dev.turntide.bfibraga.me.pem"}, "/"),
		strings.Join([]string{dockerMountedCertsDir, "dev.turntide.bfibraga.me-key.pem"}, "/"),
		"./client/html5",
		slog.Default(),
	)
	configPath = flag.String("config", ".env.dev", "path to the config file")
)

func main() {
	// Set up logger
	loggerBuilder := logger.NewBuilder()
	// TODO: Set log format based whenever its production or development
	logger := loggerBuilder.
		WithLevel(slog.LevelDebug).
		Build()
	slog.SetDefault(logger)
	defaultConfig.SetLogger(logger)

	// Load config
	flag.Parse()

	err := godotenv.Load(*configPath)
	if err != nil {
		logger.Warn("no config file found, using defaults", "path", *configPath, "error", err)
	}

	cfg, err := LoadConfig(defaultConfig)
	if err != nil {
		logger.Error("failed to load config", "error", err)
		os.Exit(1)
	}

	if cfg.DBPath == "" {
		cfg.DBPath, err = cfg.coalescePaths(dockerMountedDataDir, ".")
		if err != nil {
			logger.Error("failed to resolve database path", "error", err)
			os.Exit(1)
		}
	}

	// Setup server factory, repositories and services
	factory, err := repository.NewServerFactory(cfg.DBPath+"/server.db", logger)
	if err != nil {
		logger.Error("failed to create server factory of the following path "+cfg.DBPath, "error", err)
		os.Exit(1)
	}

	userRepo := factory.CreateUserRepository()
	userService := user.NewService(userRepo)

	hub := server.NewHub(logger, userService, components.DefaultLobbyConfig())
	hub.Initialize()

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		hub.Serve(clients.NewWebSocketClient, w, r)
	})

	// Start the server
	go hub.Run()

	addr := fmt.Sprintf(":%d", cfg.Port)

	cfg.CertPath, err = cfg.coalescePaths(cfg.CertPath)
	cfg.KeyPath, err = cfg.coalescePaths(cfg.KeyPath)
	if err != nil {
		logger.Warn("failed to coalesce certification paths", "error", err)
	}

	logger.Info(fmt.Sprintf("Starting the server at %s", addr))
	logger.Debug(fmt.Sprintf("Using cert %s, key %s", cfg.CertPath, cfg.KeyPath))

	err = http.ListenAndServeTLS(addr, cfg.CertPath, cfg.KeyPath, nil)
	if err != nil {
		logger.Warn("Failed to start server with TLS", "error", err)
		logger.Info("Starting server without TLS")

		err = http.ListenAndServe(addr, nil)
		if err != nil {
			logger.Error("failed to start server without TLS", "error", err)
			os.Exit(1)
		}
	}
}

// addHTML5ExportHeaders sets the Cross-Origin-Opener-Policy and Cross-Origin-Embedder-Policy headers to enable HTML5 export functionality
func addHTML5ExportHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cross-Origin-Opener-Policy", "same-origin")
		w.Header().Set("Cross-Origin-Embedder-Policy", "require-corp")
		next.ServeHTTP(w, r)
	})
}

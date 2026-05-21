package main

import (
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	_ "modernc.org/sqlite"

	"github.com/bfibraga/turntide/core/pkg/repository"
	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/clients"
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
		4000, "./data/server.db",
		strings.Join([]string{dockerMountedCertsDir, "dev.turntide.bfibraga.me.pem"}, "/"),
		strings.Join([]string{dockerMountedCertsDir, "dev.turntide.bfibraga.me-key.pem"}, "/"),
		"./client/html5",
		slog.Default(),
	)
	configPath    = flag.String("config", ".env.prod", "path to the config file")
)

func main() {
	// Set up logger
	loggerBuilder := logger.NewBuilder()
	// TODO: Set log format based whenever its production or development
	logger := loggerBuilder.
		WithLevel(slog.LevelDebug).
		Build()
	slog.SetDefault(logger)
	
	// Load config
	flag.Parse()

	err := godotenv.Load(*configPath)
	cfg, err := LoadConfig(defaultConfig)
	if err != nil {
		logger.Error("failed to load config file, defaulting to env vars", "error", err)
	}	
	cfg.DBPath, err = cfg.coalescePaths(cfg.DBPath, dockerMountedDataDir, ".")
	if err != nil {
		logger.Error("failed to coalesce paths", "error", err)
		os.Exit(1)
	}
	
	// Setup server factory, repositories and services
	factory, err := repository.NewServerFactory(cfg.DBPath, logger)
	userRepo := factory.CreateUserRepository()

	userService := user.NewService(userRepo)

	// Initialize hub  
	hub := server.NewHub(logger, userService)
	hub.Initialize()

	// Define handler for serving the client HTML5 page	
  exportPath, err := cfg.coalescePaths(cfg.ClientHTML5Path, filepath.Join(cfg.DBPath, "html5"))
  if err != nil {
  	logger.Error("failed to coalesce paths", "error", err)
  	os.Exit(1)
  }
	http.Handle("/", addHTML5ExportHeaders(http.StripPrefix("/", http.FileServer(http.Dir(exportPath)))))
	
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		hub.Serve(clients.NewWebSocketClient, w, r)
	})

	// Start the server
	go hub.Run()

	addr := fmt.Sprintf(":%d", cfg.Port)

	cfg.CertPath, err = cfg.coalescePaths(cfg.CertPath)	
	cfg.KeyPath, err = cfg.coalescePaths(cfg.KeyPath)
	if err != nil {
		logger.Error("failed to coalesce paths", "error", err)
		os.Exit(1)
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
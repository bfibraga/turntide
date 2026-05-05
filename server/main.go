package main

import (
	"database/sql"
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"runtime/debug"

	_ "github.com/mattn/go-sqlite3"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/clients"
	"github.com/bfibraga/turntide/server/internal/server/user"
)

var (
	port   = flag.Int("port", 4000, "port to listen on")
	dbPath = flag.String("db-path", "./shared/resources/server.db", "path to the server database")
)

func main() {
	flag.Parse()

	handler := slog.NewJSONHandler(os.Stdout, nil)
	buildInfo, _ := debug.ReadBuildInfo()
	baseLogger := slog.New(handler)
	logger := baseLogger.With(
		slog.Group(
			"program_info",
			slog.Int("pid", os.Getpid()),
			slog.String("version", buildInfo.GoVersion),
		),
	)

	slog.SetDefault(logger)

	conn, err := sql.Open("sqlite3", *dbPath)
	if err != nil {
		logger.Error("failed to open database", "error", err)
		os.Exit(1)
	}
	defer conn.Close()

	err = conn.Ping()
	if err != nil {
		logger.Error("failed to ping database", "error", err)
		os.Exit(1)
	}

	userRepo := user.NewSQLiteUserRepository(conn)
	userService := user.NewService(userRepo)

	defer userRepo.Close()

	hub := server.NewHub(logger, userService)
	// Initialize runtime callbacks that require the hub to exist
	hub.Initialize()

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		hub.Serve(clients.NewWebSocketClient, w, r)
	})

	// Start the server
	go hub.Run()

	addr := fmt.Sprintf(":%d", *port)
	err = http.ListenAndServe(addr, nil)
	if err != nil {
		logger.Error("failed to start server", "error", err)
		os.Exit(1)
	}

}

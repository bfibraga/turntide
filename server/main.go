package main

import (
	"flag"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"runtime/debug"

	"github.com/bfibraga/turntide/server/internal/server"
	"github.com/bfibraga/turntide/server/internal/server/clients"
)

var (
	port = flag.Int("port", 4000, "port to listen on")
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

	hub := server.NewHub(logger)

	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		hub.Serve(clients.NewWebSocketClient, w, r)
	})

	// Start the server
	go hub.Run()

	addr := fmt.Sprintf(":%d", *port)
	err := http.ListenAndServe(addr, nil)
	if err != nil {
		logger.Error("failed to start server", "error", err)
		os.Exit(1)
	}

}

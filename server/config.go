package main

import (
	"errors"
	"fmt"
	"log/slog"
	"os"
	"strconv"
	"strings"
)

type Config struct {
	Port            int
	DBPath          string
	CertPath        string
	KeyPath         string
	ClientHTML5Path string

	Logger *slog.Logger
}

func NewConfig(port int, dbPath, certPath, keyPath, clientHTML5Path string, logger *slog.Logger) *Config {
	return &Config{
		Port:            port,
		DBPath:          dbPath,
		CertPath:        certPath,
		KeyPath:         keyPath,
		ClientHTML5Path: clientHTML5Path,
		Logger:          logger,
	}
}

func LoadConfig(defaultCfg *Config) (*Config, error) {
	var err error
	cfg := defaultCfg

	portStr := os.Getenv("SERVER_PORT")
	if portStr != "" {
		cfg.Port, err = strconv.Atoi(portStr)
		if err != nil {
			return nil, err
		}
	}

	if envDBPath := os.Getenv("SERVER_DATA_PATH"); envDBPath != "" {
		cfg.DBPath = envDBPath
	}
	if envCertPath := os.Getenv("SERVER_CERT_PATH"); envCertPath != "" {
		cfg.CertPath = envCertPath
	}
	if envKeyPath := os.Getenv("SERVER_KEY_PATH"); envKeyPath != "" {
		cfg.KeyPath = envKeyPath
	}
	if envClientPath := os.Getenv("CLIENT_HTML5_PATH"); envClientPath != "" {
		cfg.ClientHTML5Path = envClientPath
	}

	return cfg, nil
}

func (cfg *Config) SetLogger(logger *slog.Logger) {
	cfg.Logger = logger
}

func (cfg *Config) resolveLiveCertsPath(certPath string, fallbackPaths ...string) (string, error) {
	normalizedPath := strings.ReplaceAll(certPath, "\\", "/")
	pathComponents := strings.Split(normalizedPath, "/live/")

	if len(pathComponents) >= 2 {
		pathTail := pathComponents[len(pathComponents)-1]

		return cfg.coalescePaths(append(fallbackPaths, pathTail)...)
	}

	return certPath, nil
}

func (cfg *Config) coalescePaths(paths ...string) (string, error) {
	for i, path := range paths {
		if _, err := os.Stat(path); os.IsNotExist(err) {
			message := "path does not exist: " + path
			if i < len(paths)-1 {
				cfg.Logger.Warn(fmt.Sprintf("path does not exist: %s, trying next path", path))
				continue
			} else {
				cfg.Logger.Error(fmt.Sprintf("path does not exist: %s, no valid path found", path))
				return "", errors.New(message)
			}
		}
		return path, nil
	}

	return "", errors.New("no valid path found")
}

package main

import (
	"os"
	"strconv"
)

type Config struct {
	Port   int
	DBPath string
}

func NewConfig(port int, dbPath string) *Config {
	return &Config{
		Port:   port,
		DBPath: dbPath,
	}
}

func LoadConfig(defaultCfg *Config) (*Config, error) {
	cfg := defaultCfg

	port, err := strconv.Atoi(os.Getenv("SERVER_PORT"))
	if err != nil {
		return cfg, err
	}
	cfg.Port = port

	dbPath := os.Getenv("SERVER_DATA_PATH")
	if dbPath != "" {
		cfg.DBPath = dbPath
	}

	return cfg, nil
}
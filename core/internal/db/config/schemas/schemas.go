package config

import (
	_ "embed"
)

//go:embed cards.sql
var CardsSchemaSQL string

//go:embed server.sql
var ServerSchemaSQL string

package config

import (
	_ "embed"
)

//go:embed schema.sql
var SchemaSQL string
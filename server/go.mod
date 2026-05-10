module github.com/bfibraga/turntide/server

go 1.26.1

require (
	github.com/bfibraga/turntide/core v0.0.0
	github.com/gorilla/websocket v1.5.3
	golang.org/x/crypto v0.31.0
	google.golang.org/protobuf v1.36.11
)

require (
	github.com/go-faker/faker/v4 v4.7.0 // indirect
	github.com/mattn/go-sqlite3 v1.14.37 // indirect
	golang.org/x/text v0.29.0 // indirect
)

replace github.com/bfibraga/turntide/core => ../core

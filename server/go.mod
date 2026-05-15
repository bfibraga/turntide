module github.com/bfibraga/turntide/server

go 1.26.1

require (
	github.com/bfibraga/turntide/core v0.0.0-00010101000000-000000000000
	github.com/go-faker/faker/v4 v4.7.0
	github.com/gorilla/websocket v1.5.3
	github.com/joho/godotenv v1.5.1
	github.com/lmittmann/tint v1.1.3
	github.com/mattn/go-colorable v0.1.14
	github.com/mattn/go-isatty v0.0.20
	golang.org/x/crypto v0.31.0
	google.golang.org/protobuf v1.36.11
	modernc.org/sqlite v1.50.1
)

require (
	github.com/dustin/go-humanize v1.0.1 // indirect
	github.com/google/uuid v1.6.0 // indirect
	github.com/ncruces/go-strftime v1.0.0 // indirect
	github.com/remyoudompheng/bigfft v0.0.0-20230129092748-24d4a6f8daec // indirect
	golang.org/x/sys v0.42.0 // indirect
	golang.org/x/text v0.29.0 // indirect
	modernc.org/libc v1.72.3 // indirect
	modernc.org/mathutil v1.7.1 // indirect
	modernc.org/memory v1.11.0 // indirect
)

replace github.com/bfibraga/turntide/core => ../core

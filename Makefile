.PHONY: fetcher server

BIN_PATH := shared/resources/bin/

all: fetcher server

fetcher:
	go build -o $(BIN_PATH) ./fetcher

server:
	go build -o $(BIN_PATH) ./server

test:
	go test ./...

clean:
	rm -rf $(BIN_PATH)

.PHONY: fetcher server test clean sql

BIN_PATH := shared/resources/bin/
GODOT_BIN := $(shell which godot)
SQLC_BIN := $(shell which sqlc)

all: setup proto fetcher server

setup:
	go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
	go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest

fetcher:
	go build -o $(BIN_PATH) ./fetcher

server:
	go build -o $(BIN_PATH) ./server

test: test-client test-server
	@echo "Executed test suite"

test-client:
	$(GODOT_BIN) -d -s --path "$(PWD)/client" addons/gut/gut_cmdln.gd -gdir=res://test/unit -gconfig=res://test/unit/gutconfig.json

test-server:
	@go test ./server/test/...

clean:
	@rm -rf $(BIN_PATH)

sql: sql-fetcher sql-server
	@echo "Generated sqlc bindings"

sql-fetcher:
	@find ./fetcher -name "sqlc.yaml" -exec sh -c '$(SQLC_BIN) generate -f $$1' _ {} \;

sql-server:
	@find ./server -name "sqlc.yaml" -exec sh -c '$(SQLC_BIN) generate -f $$1' _ {} \;

proto: proto-server proto-client
	@echo "Generated protobuf bindings"

proto-server:
	@protoc \
		-I=shared \
	  --go_out=./server ./shared/*.proto

proto-client:
	@cd client && \
	  find ../shared -name "*.proto" -exec sh -c \
		'$(GODOT_BIN) --headless -q -s addons/godobuf/godobuf_cmdln.gd --input="$$1" --output="scripts/network/packets/$$(basename "$$1" .proto).gd"' _ {} \;

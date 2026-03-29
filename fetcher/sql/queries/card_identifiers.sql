-- name: GetIdentifierByUuid :one
SELECT * FROM cardIdentifiers WHERE uuid = ?;

-- name: GetIdentifierByScryfallId :one
SELECT * FROM cardIdentifiers WHERE scryfallId = ?;

-- name: GetIdentifiersByUuidList :many
SELECT * FROM cardIdentifiers WHERE uuid IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: GetAllIdentifiers :many
SELECT * FROM cardIdentifiers LIMIT ? OFFSET ?;

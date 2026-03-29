-- name: GetIdentifierByUuid :one
SELECT * FROM cardidentifiers WHERE uuid = ?;

-- name: GetIdentifierByScryfallId :one
SELECT * FROM cardidentifiers WHERE scryfallid = ?;

-- name: GetIdentifiersByUuidList :many
SELECT * FROM cardidentifiers WHERE uuid IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: GetAllIdentifiers :many
SELECT * FROM cardidentifiers LIMIT ? OFFSET ?;

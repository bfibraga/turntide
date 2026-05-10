-- name: GetIdentifierByUuid :one
SELECT * FROM cardidentifiers WHERE uuid = ?;

-- name: GetIdentifierByScryfallId :one
SELECT * FROM cardidentifiers WHERE scryfallid = ?;

-- name: GetIdentifiersByUuidList :many
SELECT * FROM cardidentifiers WHERE uuid IN (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);

-- name: GetAllIdentifiers :many
SELECT * FROM cardidentifiers LIMIT ? OFFSET ?;

-- name: GetCardByNameSetCodeAndNumber :one
SELECT c.uuid, c.name, c.setcode, c.number, ci.scryfallid
FROM cards c
JOIN cardidentifiers ci ON c.uuid = ci.uuid
WHERE c.name = ? AND c.setcode = ? AND c.number = ?;

-- name: GetCardByNameAndSetCode :one
SELECT c.uuid, c.name, c.setcode, c.number, ci.scryfallid
FROM cards c
JOIN cardidentifiers ci ON c.uuid = ci.uuid
WHERE c.name = ? AND c.setcode = ?
LIMIT 1;

-- name: GetSetByCode :one
SELECT * FROM sets WHERE code = ?;

-- name: GetSetByName :many
SELECT * FROM sets WHERE name LIKE ?;

-- name: ListAllSets :many
SELECT * FROM sets LIMIT ? OFFSET ?;

-- name: CountSets :one
SELECT COUNT(*) as count FROM sets;

-- name: GetCardByUUID :one
SELECT * FROM cards WHERE uuid = ? LIMIT 1;

-- name: ListCards :many
SELECT * FROM cards LIMIT ?;

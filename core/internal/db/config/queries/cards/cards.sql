-- name: GetCardByUuid :one
SELECT * FROM cards WHERE uuid = ?;

-- name: GetCardByName :many
SELECT * FROM cards WHERE name LIKE ?;

-- name: GetCardsBySetCode :many
SELECT * FROM cards WHERE setcode = ?;

-- name: ListAllCards :many
SELECT * FROM cards LIMIT ? OFFSET ?;

-- name: SearchCards :many
SELECT * FROM cards 
WHERE 1=1
  AND (? IS NULL OR name LIKE ?)
  AND (? IS NULL OR setcode = ?)
  AND (? IS NULL OR type LIKE ?)
LIMIT ? OFFSET ?;

-- name: CountCards :one
SELECT COUNT(*) as count FROM cards;

-- name: GetCardsByColor :many
SELECT * FROM cards WHERE colors LIKE ? LIMIT ? OFFSET ?;

-- name: GetCardsByRarity :many
SELECT * FROM cards WHERE rarity = ? LIMIT ? OFFSET ?;

-- name: GetCardsByManaValue :many
SELECT * FROM cards WHERE manavalue = ? LIMIT ? OFFSET ?;

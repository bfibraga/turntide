-- name: GetCardByUuid :one
SELECT * FROM cards WHERE uuid = ?;

-- name: GetCardByName :many
SELECT * FROM cards WHERE name LIKE ?;

-- name: GetCardsBySetCode :many
SELECT * FROM cards WHERE setcode = ?;

-- name: ListAllCards :many
SELECT * FROM cards LIMIT ? OFFSET ?;

-- name: SearchCards :many
SELECT * FROM cards c
WHERE 1=1
    AND (:artist IS NULL OR artist LIKE :artist)
    AND (:artistIds IS NULL OR artistIds LIKE :artistIds)
    AND (:asciiName IS NULL OR asciiName LIKE :asciiName)
    AND (:attractionLights IS NULL OR attractionLights LIKE :attractionLights)
    AND (:availability IS NULL OR availability LIKE :availability)
    AND (:boosterTypes IS NULL OR boosterTypes LIKE :boosterTypes)
    AND (:borderColor IS NULL OR borderColor LIKE :borderColor)
    AND (:cardParts IS NULL OR cardParts LIKE :cardParts)
    AND (:colorIdentity IS NULL OR colorIdentity LIKE :colorIdentity)
    AND (:colorIndicator IS NULL OR colorIndicator LIKE :colorIndicator)
    AND (:colors IS NULL OR colors LIKE :colors)
    AND (:defense IS NULL OR defense LIKE :defense)
    AND (:duelDeck IS NULL OR duelDeck LIKE :duelDeck)
    AND (:edhrecRank IS NULL OR edhrecRank = :edhrecRank)
    AND (:edhrecSaltiness IS NULL OR edhrecSaltiness = :edhrecSaltiness)
    AND (:faceConvertedManaCost IS NULL OR faceConvertedManaCost = :faceConvertedManaCost)
    AND (:faceFlavorName IS NULL OR faceFlavorName LIKE :faceFlavorName)
    AND (:faceManaValue IS NULL OR faceManaValue = :faceManaValue)
    AND (:faceName IS NULL OR faceName LIKE :faceName)
    AND (:facePrintedName IS NULL OR facePrintedName LIKE :facePrintedName)
    AND (:finishes IS NULL OR finishes LIKE :finishes)
    AND (:flavorName IS NULL OR flavorName LIKE :flavorName)
    AND (:flavorText IS NULL OR flavorText LIKE :flavorText)
    AND (:frameEffects IS NULL OR frameEffects LIKE :frameEffects)
    AND (:frameVersion IS NULL OR frameVersion LIKE :frameVersion)
    AND (:hand IS NULL OR hand LIKE :hand)
    AND (:hasAlternativeDeckLimit IS NULL OR hasAlternativeDeckLimit = :hasAlternativeDeckLimit)
    AND (:hasContentWarning IS NULL OR hasContentWarning = :hasContentWarning)
    AND (:isAlternative IS NULL OR isAlternative = :isAlternative)
    AND (:isFullArt IS NULL OR isFullArt = :isFullArt)
    AND (:isFunny IS NULL OR isFunny = :isFunny)
    AND (:isGameChanger IS NULL OR isGameChanger = :isGameChanger)
    AND (:isOnlineOnly IS NULL OR isOnlineOnly = :isOnlineOnly)
    AND (:isOversized IS NULL OR isOversized = :isOversized)
    AND (:isPromo IS NULL OR isPromo = :isPromo)
    AND (:isRebalanced IS NULL OR isRebalanced = :isRebalanced)
    AND (:isReprint IS NULL OR isReprint = :isReprint)
    AND (:isReserved IS NULL OR isReserved = :isReserved)
    AND (:isStorySpotlight IS NULL OR isStorySpotlight = :isStorySpotlight)
    AND (:isTextless IS NULL OR isTextless = :isTextless)
    AND (:isTimeshifted IS NULL OR isTimeshifted = :isTimeshifted)
    AND (:keywords IS NULL OR keywords LIKE :keywords)
    AND (:language IS NULL OR language LIKE :language)
    AND (:layout IS NULL OR layout LIKE :layout)
    AND (:leadershipSkills IS NULL OR leadershipSkills LIKE :leadershipSkills)
    AND (:life IS NULL OR life LIKE :life)
    AND (:loyalty IS NULL OR loyalty LIKE :loyalty)
    AND (:manaCost IS NULL OR manaCost LIKE :manaCost)
    AND (:manaValue IS NULL OR manaValue = :manaValue)
    AND (:name IS NULL OR name LIKE :name)
    AND (:number IS NULL OR number LIKE :number)
    AND (:originalPrintings IS NULL OR originalPrintings LIKE :originalPrintings)
    AND (:originalReleaseDate IS NULL OR originalReleaseDate LIKE :originalReleaseDate)
    AND (:originalText IS NULL OR originalText LIKE :originalText)
    AND (:otherFaceIds IS NULL OR otherFaceIds LIKE :otherFaceIds)
    AND (:power IS NULL OR power LIKE :power)
    AND (:printedName IS NULL OR printedName LIKE :printedName)
    AND (:printedText IS NULL OR printedText LIKE :printedText)
    AND (:printedType IS NULL OR printedType LIKE :printedType)
    AND (:printings IS NULL OR printings LIKE :printings)
    AND (:producedMana IS NULL OR producedMana LIKE :producedMana)
    AND (:promoTypes IS NULL OR promoTypes LIKE :promoTypes)
    AND (:rarity IS NULL OR rarity LIKE :rarity)
    AND (:rebalancedPrintings IS NULL OR rebalancedPrintings LIKE :rebalancedPrintings)
    AND (:relatedCards IS NULL OR relatedCards LIKE :relatedCards)
    AND (:securityStamp IS NULL OR securityStamp LIKE :securityStamp)
    AND (:setCode IS NULL OR setCode LIKE :setCode)
    AND (:side IS NULL OR side LIKE :side)
    AND (:signature IS NULL OR signature LIKE :signature)
    AND (:skuIds IS NULL OR skuIds LIKE :skuIds)
    AND (:sourceProducts IS NULL OR sourceProducts LIKE :sourceProducts)
    AND (:subsets IS NULL OR subsets LIKE :subsets)
    AND (:subtypes IS NULL OR subtypes LIKE :subtypes)
    AND (:supertypes IS NULL OR supertypes LIKE :supertypes)
    AND (:text IS NULL OR text LIKE :text)
    AND (:toughness IS NULL OR toughness LIKE :toughness)
    AND (:type IS NULL OR type LIKE :type)
    AND (:types IS NULL OR types LIKE :types)
    AND (:uuid IS NULL OR uuid LIKE :uuid)
    AND (:variations IS NULL OR variations LIKE :variations)
    AND (:watermark IS NULL OR watermark LIKE :watermark)
ORDER BY c.name ASC
LIMIT :limit OFFSET :offset
;

-- name: CountCards :one
SELECT COUNT(*) as count FROM cards;

-- name: GetCardsByColor :many
SELECT * FROM cards WHERE colors LIKE ? LIMIT ? OFFSET ?;

-- name: GetCardsByRarity :many
SELECT * FROM cards WHERE rarity = ? LIMIT ? OFFSET ?;

-- name: GetCardsByManaValue :many
SELECT * FROM cards WHERE manavalue = ? LIMIT ? OFFSET ?;

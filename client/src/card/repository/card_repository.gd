class_name CardRepository extends SQLRepository

const _table_name : String = "cards"
const DEFAULT_DB_PATH : String = "res://../shared/resources/cards.db"

func count_cards() -> int:
	var query : String = "SELECT COUNT(*) FROM %s;" % _table_name
	
	var success : bool = self._db.query_with_bindings(query, [])
	if !success:
		push_error("Card Count not successfull!")
		return 0
	
	var result : int = self._db.query_result.get(0).get("COUNT(*)", 0)
	print(result)
	
	return result
	
const DEFAULT_SEARCH_CARD_PARAMS : Dictionary[String, Variant] = {
	"artist": null,
	"artistIds": null,
	"asciiName": null,
	"attractionLights": null,
	"availability": null,
	"boosterTypes": null,
	"borderColor": null,
	"cardParts": null,
	"colorIdentity": null,
	"colorIndicator": null,
	"colors": null,
	"defense": null,
	"duelDeck": null,
	"edhrecRank": null,
	"edhrecSaltiness": null,
	"faceConvertedManaCost": null,
	"faceFlavorName": null,
	"faceManaValue": null,
	"faceName": null,
	"facePrintedName": null,
	"finishes": null,
	"flavorName": null,
	"flavorText": null,
	"frameEffects": null,
	"frameVersion": null,
	"hand": null,
	"hasAlternativeDeckLimit": null,
	"hasContentWarning": null,
	"isAlternative": null,
	"isFullArt": null,
	"isFunny": null,
	"isGameChanger": null,
	"isOnlineOnly": null,
	"isOversized": null,
	"isPromo": null,
	"isRebalanced": null,
	"isReprint": null,
	"isReserved": null,
	"isStorySpotlight": null,
	"isTextless": null,
	"isTimeshifted": null,
	"keywords": null,
	"language": null,
	"layout": null,
	"leadershipSkills": null,
	"life": null,
	"loyalty": null,
	"manaCost": null,
	"manaValue": null,
	"name": null,
	"number": null,
	"originalPrintings": null,
	"originalReleaseDate": null,
	"originalText": null,
	"otherFaceIds": null,
	"power": null,
	"printedName": null,
	"printedText": null,
	"printedType": null,
	"printings": null,
	"producedMana": null,
	"promoTypes": null,
	"rarity": null,
	"rebalancedPrintings": null,
	"relatedCards": null,
	"securityStamp": null,
	"setCode": null,
	"side": null,
	"signature": null,
	"skuIds": null,
	"sourceProducts": null,
	"subsets": null,
	"subtypes": null,
	"supertypes": null,
	"text": null,
	"toughness": null,
	"type": null,
	"types": null,
	"uuid": null,
	"variations": null,
	"watermark": null,
}

func search_cards(
	params: Dictionary[String, Variant] = {}
) -> Array[CardData]:
	var search_params : Dictionary[String, Variant] = DEFAULT_SEARCH_CARD_PARAMS.duplicate(true)
	search_params.merge(DEFAULT_PAGE_PARAMS)
	search_params.merge(params, true)
	
	var limit: int = search_params.get("page_size", 1)
	var offset: int = (search_params.get("page", 1) - 1) * limit

	# Normalize legacy/lowercase keys (UI historically uses lowercase 'setcode')
	if search_params.has("setcode") and not search_params.has("setCode"):
		search_params["setCode"] = search_params.get("setcode")
	if search_params.has("setCode") and not search_params.has("setcode"):
		search_params["setcode"] = search_params.get("setCode")

	var query: String = """
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
    LIMIT :limit 
    OFFSET :offset
    ;
	"""

	var query_params : Dictionary[String, Variant] = {
		"artist": _escape_string(search_params.get("artist")),
		"artistIds": _escape_string(search_params.get("artistIds")),
		"asciiName": _escape_string(search_params.get("asciiName")),
		"attractionLights": _escape_string(search_params.get("attractionLights")),
		"availability": _escape_string(search_params.get("availability")),
		"boosterTypes": _escape_string(search_params.get("boosterTypes")),
		"borderColor": _escape_string(search_params.get("borderColor")),
		"cardParts": _escape_string(search_params.get("cardParts")),
		"colorIdentity": _escape_string(search_params.get("colorIdentity")),
		"colorIndicator": _escape_string(search_params.get("colorIndicator")),
		"colors": _escape_string(search_params.get("colors")),
		"defense": _escape_string(search_params.get("defense")),
		"duelDeck": _escape_string(search_params.get("duelDeck")),
		"edhrecRank": search_params.get("edhrecRank"),
		"edhrecSaltiness": search_params.get("edhrecSaltiness"),
		"faceConvertedManaCost": search_params.get("faceConvertedManaCost"),
		"faceFlavorName": _escape_string(search_params.get("faceFlavorName")),
		"faceManaValue": search_params.get("faceManaValue"),
		"faceName": _escape_string(search_params.get("faceName")),
		"facePrintedName": _escape_string(search_params.get("facePrintedName")),
		"finishes": _escape_string(search_params.get("finishes")),
		"flavorName": _escape_string(search_params.get("flavorName")),
		"flavorText": _escape_string(search_params.get("flavorText")),
		"frameEffects": _escape_string(search_params.get("frameEffects")),
		"frameVersion": _escape_string(search_params.get("frameVersion")),
		"hand": _escape_string(search_params.get("hand")),
		"hasAlternativeDeckLimit": search_params.get("hasAlternativeDeckLimit"),
		"hasContentWarning": search_params.get("hasContentWarning"),
		"isAlternative": search_params.get("isAlternative"),
		"isFullArt": search_params.get("isFullArt"),
		"isFunny": search_params.get("isFunny"),
		"isGameChanger": search_params.get("isGameChanger"),
		"isOnlineOnly": search_params.get("isOnlineOnly"),
		"isOversized": search_params.get("isOversized"),
		"isPromo": search_params.get("isPromo"),
		"isRebalanced": search_params.get("isRebalanced"),
		"isReprint": search_params.get("isReprint"),
		"isReserved": search_params.get("isReserved"),
		"isStorySpotlight": search_params.get("isStorySpotlight"),
		"isTextless": search_params.get("isTextless"),
		"isTimeshifted": search_params.get("isTimeshifted"),
		"keywords": _escape_string(search_params.get("keywords")),
		"language": _escape_string(search_params.get("language")),
		"layout": _escape_string(search_params.get("layout")),
		"leadershipSkills": _escape_string(search_params.get("leadershipSkills")),
		"life": _escape_string(search_params.get("life")),
		"loyalty": _escape_string(search_params.get("loyalty")),
		"manaCost": _escape_string(search_params.get("manaCost")),
		"manaValue": search_params.get("manaValue"),
		"name": _escape_string(search_params.get("name")),
		"number": _escape_string(search_params.get("number")),
		"originalPrintings": _escape_string(search_params.get("originalPrintings")),
		"originalReleaseDate": _escape_string(search_params.get("originalReleaseDate")),
		"originalText": _escape_string(search_params.get("originalText")),
		"otherFaceIds": _escape_string(search_params.get("otherFaceIds")),
		"power": _escape_string(search_params.get("power")),
		"printedName": _escape_string(search_params.get("printedName")),
		"printedText": _escape_string(search_params.get("printedText")),
		"printedType": _escape_string(search_params.get("printedType")),
		"printings": _escape_string(search_params.get("printings")),
		"producedMana": _escape_string(search_params.get("producedMana")),
		"promoTypes": _escape_string(search_params.get("promoTypes")),
		"rarity": _escape_string(search_params.get("rarity")),
		"rebalancedPrintings": _escape_string(search_params.get("rebalancedPrintings")),
		"relatedCards": _escape_string(search_params.get("relatedCards")),
		"securityStamp": _escape_string(search_params.get("securityStamp")),
		"setCode": _escape_string(search_params.get("setCode")),
		"side": _escape_string(search_params.get("side")),
		"signature": _escape_string(search_params.get("signature")),
		"skuIds": _escape_string(search_params.get("skuIds")),
		"sourceProducts": _escape_string(search_params.get("sourceProducts")),
		"subsets": _escape_string(search_params.get("subsets")),
		"subtypes": _escape_string(search_params.get("subtypes")),
		"supertypes": _escape_string(search_params.get("supertypes")),
		"text": _escape_string(search_params.get("text")),
		"toughness": _escape_string(search_params.get("toughness")),
		"type": _escape_string(search_params.get("type")),
		"types": _escape_string(search_params.get("types")),
		"uuid": _escape_string(search_params.get("uuid")),
		"variations": _escape_string(search_params.get("variations")),
		"watermark": _escape_string(search_params.get("watermark")),
		"limit": limit,
		"offset": offset,
	}
	
	var success : bool = self._db.query_with_named_bindings(query, query_params)
	if !success:
		push_error("Card Search not successfull!")
		return []
		
	var result : Array[CardData] = []
	for data : Dictionary in self._db.query_result:
		var card_data : CardData = CardData.Builder.new() \
			.from_dict(data) \
			.build()
			
		result.append(card_data)
		
	return result

func _escape_string(value: Variant) -> Variant:
	if !value or value is not String or value.is_empty():
		return null
	
	return "%%%s%%" % value

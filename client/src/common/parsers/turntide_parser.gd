class_name TurntideParser
extends RefCounted

class TurntideCardData:
	var name: String
	var set_code: String
	var card_id: String

static func parse(content: String) -> Array[TurntideCardData]:
	var cards: Array[TurntideCardData] = []
	var lines: PackedStringArray = content.split("\n", false)
	for line: String in lines:
		var trimmed: String = line.strip_edges()
		if trimmed.is_empty():
			continue
		var card: TurntideCardData = _parse_line(trimmed)
		if card:
			cards.append(card)
	return cards

static func _parse_line(line: String) -> TurntideCardData:
	line = line.strip_edges()
	if line.is_empty():
		return null

	var card := TurntideCardData.new()
	var brackets: Array[String] = []
	var name_end_idx: int = 0

	var i: int = 0
	while i < line.length():
		if line[i] == '[':
			var closing_idx: int = line.find("]", i)
			if closing_idx == -1:
				i += 1
				continue
			var content: String = line.substr(i + 1, closing_idx - i - 1).strip_edges()
			brackets.append(content)
			if name_end_idx == 0:
				name_end_idx = i
			i = closing_idx
		i += 1

	if name_end_idx > 0:
		card.name = line.substr(0, name_end_idx).strip_edges()
	else:
		card.name = line
		return card

	if brackets.size() > 0:
		card.set_code = brackets[0]
	if brackets.size() > 1:
		card.card_id = brackets[1]

	return card

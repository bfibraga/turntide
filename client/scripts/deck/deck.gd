/*
Copyright © 2026 Bruno Braga bf.braga@campus.fct.unl.pt

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
class_name DeckCard
extends RefCounted

var uuid: String = ""
var quantity: int = 1

func _init(uuid: String = "", quantity: int = 1) -> void:
	self.uuid = uuid
	self.quantity = quantity

func to_dict() -> Dictionary:
	return { "uuid": uuid, "quantity": quantity }

static func from_dict(data: Dictionary) -> DeckCard:
	return DeckCard.new(
		data.get("uuid", ""),
		data.get("quantity", 1)
	)


class_name Deck
extends RefCounted

var name: String = ""
var format: String = "Commander"
var created_at: String = ""
var updated_at: String = ""
var cards: Array[DeckCard] = []

func _init() -> void:
	var now: String = Time.get_datetime_string_from_system(true)
	created_at = now
	updated_at = now

func add_card(card_uuid: String, quantity: int = 1) -> void:
	for card in cards:
		if card.uuid == card_uuid:
			card.quantity += quantity
			_mark_updated()
			return
	cards.append(DeckCard.new(card_uuid, quantity))
	_mark_updated()

func remove_card(card_uuid: String, quantity: int = 1) -> bool:
	for i in range(cards.size()):
		if cards[i].uuid == card_uuid:
			cards[i].quantity -= quantity
			if cards[i].quantity <= 0:
				cards.remove_at(i)
			_mark_updated()
			return true
	return false

func set_card_quantity(card_uuid: String, quantity: int) -> void:
	if quantity <= 0:
		remove_card(card_uuid, 999)
		return
	for card in cards:
		if card.uuid == card_uuid:
			card.quantity = quantity
			_mark_updated()
			return
	add_card(card_uuid, quantity)

func get_card_count() -> int:
	var total: int = 0
	for card in cards:
		total += card.quantity
	return total

func _mark_updated() -> void:
	updated_at = Time.get_datetime_string_from_system(true)

func to_dict() -> Dictionary:
	var cards_arr: Array[Dictionary] = []
	for card in cards:
		cards_arr.append(card.to_dict())
	return {
		"name": name,
		"format": format,
		"created_at": created_at,
		"updated_at": updated_at,
		"cards": cards_arr,
	}

static func from_dict(data: Dictionary) -> Deck:
	var deck = Deck.new()
	deck.name = data.get("name", "")
	deck.format = data.get("format", "Commander")
	deck.created_at = data.get("created_at", "")
	deck.updated_at = data.get("updated_at", "")
	
	var cards_arr: Array = data.get("cards", [])
	for card_data in cards_arr:
		deck.cards.append(DeckCard.from_dict(card_data))
	
	return deck

func _to_string() -> String:
	return "[Deck: %s (%s), %d cards]" % [name, format, get_card_count()]
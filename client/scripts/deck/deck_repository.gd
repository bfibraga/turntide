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
class_name DeckRepository
extends RefCounted

const DECKS_DIR: String = "cache/decks"
const FILE_EXTENSION: String = ".json"

var _deck_cache: Dictionary = {}

func _init() -> void:
	_ensure_directory()

func _ensure_directory() -> bool:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		push_error("Failed to open user:// directory")
		return false
	
	var path: String = DECKS_DIR
	if not dir.dir_exists(path):
		var err: Error = dir.make_dir_recursive(path)
		if err != OK:
			push_error("Failed to create decks directory: " + str(err))
			return false
	return true

func _get_file_path(deck_name: String) -> String:
	var safe_name: String = deck_name.replace(" ", "-").to_lower()
	safe_name = safe_name.replace("/", "").replace("\\", "")
	return "user://%s/%s%s" % [DECKS_DIR, safe_name, FILE_EXTENSION]

func save(deck: Deck) -> bool:
	var path: String = _get_file_path(deck.name)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	
	if file == null:
		push_error("Failed to open deck file for writing: " + path)
		return false
	
	var json: String = JSON.stringify(deck.to_dict(), "\t")
	file.store_string(json)
	file.close()
	
	_deck_cache[deck.name] = deck
	return true

func load(deck_name: String) -> Deck:
	if _deck_cache.has(deck_name):
		return _deck_cache[deck_name]
	
	var path: String = _get_file_path(deck_name)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	
	if file == null:
		push_error("Failed to open deck file: " + path)
		return null
	
	var json_str: String = file.get_as_text()
	file.close()
	
	var json: JSON = JSON.new()
	var error: Error = json.parse(json_str)
	if error != OK:
		push_error("Failed to parse deck JSON: " + json.get_error_message())
		return null
	
	var deck: Deck = Deck.from_dict(json.data)
	_deck_cache[deck.name] = deck
	return deck

func delete(deck_name: String) -> bool:
	var path: String = _get_file_path(deck_name)
	var dir: DirAccess = DirAccess.open("user://" + DECKS_DIR)
	
	if dir == null:
		return false
	
	var err: Error = dir.remove(path)
	if err != OK:
		push_error("Failed to delete deck: " + str(err))
		return false
	
	_deck_cache.erase(deck_name)
	return true

func list_decks() -> Array[String]:
	var dir: DirAccess = DirAccess.open("user://" + DECKS_DIR)
	if dir == null:
		return []
	
	var deck_names: Array[String] = []
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(FILE_EXTENSION):
			var name: String = file_name.replace(FILE_EXTENSION, "").replace("-", " ")
			deck_names.append(name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	deck_names.sort()
	return deck_names

func exists(deck_name: String) -> bool:
	var path: String = _get_file_path(deck_name)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	file.close()
	return true
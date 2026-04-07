# Deck Builder Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a deck builder system allowing players to create, edit, and save Magic: The Gathering decks locally as JSON files in `user://cache/decks/`.

**Architecture:** Three-panel UI inspired by Moxfield/Archidekt - deck list (left), current deck editor (middle), card search (right). Data layer uses JSON file storage with DeckRepository pattern. Integration via Godot state machine.

**Tech Stack:** Godot 4.6, GDScript, godot-sqlite (existing), JSON file I/O

---

## File Structure

```
scripts/deck/
├── deck_format.gd      # Enum for deck formats
├── deck.gd             # Data model (Deck + DeckCard)
├── deck_repository.gd  # File I/O to user://cache/decks/
└── deck_service.gd     # Business logic (search, add, remove cards)
states/deck_builder/
└── deck_builder_state.gd  # State script for deck builder
scenes/deck_builder/
└── deck_builder.tscn   # UI scene
```

---

## Task 1: Create Deck Format Enum

**Files:**
- Create: `client/scripts/deck/deck_format.gd`

- [ ] **Step 1: Write deck_format.gd**

```gdscript
class_name DeckFormat
extends RefCounted

enum Format {
    COMMANDER = 0,
    STANDARD = 1,
    MODERN = 2,
    PIONEER = 3,
    LEGACY = 4,
    VINTAGE = 5,
    PAUPER = 6,
    CASUAL = 7,
    CUSTOM = 8,
}

static func get_display_name(format: Format) -> String:
    match format:
        Format.COMMANDER: return "Commander"
        Format.STANDARD: return "Standard"
        Format.MODERN: return "Modern"
        Format.PIONEER: return "Pioneer"
        Format.LEGACY: return "Legacy"
        Format.VINTAGE: return "Vintage"
        Format.PAUPER: return "Pauper"
        Format.CASUAL: return "Casual"
        Format.CUSTOM: return "Custom"
        _: return "Unknown"

static func get_all_display_names() -> Array[String]:
    var names: Array[String] = []
    for format in Format.keys():
        names.append(get_display_name(Format[format]))
    return names

static func from_string(str: String) -> Format:
    var upper: String = str.to_upper().replace(" ", "_")
    for format in Format.keys():
        if format == upper:
            return Format[format]
    return Format.CUSTOM
```

- [ ] **Step 2: Commit**

```bash
git add client/scripts/deck/deck_format.gd
git commit -m "feat: add deck format enum"
```

---

## Task 2: Create Deck Data Model

**Files:**
- Create: `client/scripts/deck/deck.gd`

- [ ] **Step 1: Write deck.gd**

```gdscript
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
```

- [ ] **Step 2: Commit**

```bash
git add client/scripts/deck/deck.gd
git commit -m "feat: add deck data model with Deck and DeckCard classes"
```

---

## Task 3: Create Deck Repository

**Files:**
- Create: `client/scripts/deck/deck_repository.gd`

- [ ] **Step 1: Write deck_repository.gd**

```gdscript
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
```

- [ ] **Step 2: Commit**

```bash
git add client/scripts/deck/deck_repository.gd
git commit -m "feat: add deck repository for JSON file I/O"
```

---

## Task 4: Create Deck Service

**Files:**
- Create: `client/scripts/deck/deck_service.gd`

- [ ] **Step 1: Write deck_service.gd**

```gdscript
class_name DeckService
extends RefCounted

var _repository: DeckRepository
var _card_repository: CardRepository

func _init(card_repository: CardRepository) -> void:
    _repository = DeckRepository.new()
    _card_repository = card_repository

func create_deck(name: String, format: String = "Commander") -> Deck:
    var deck: Deck = Deck.new()
    deck.name = name
    deck.format = format
    _repository.save(deck)
    return deck

func save_deck(deck: Deck) -> bool:
    return _repository.save(deck)

func load_deck(name: String) -> Deck:
    return _repository.load(name)

func delete_deck(name: String) -> bool:
    return _repository.delete(name)

func list_decks() -> Array[String]:
    return _repository.list_decks()

func add_card(deck: Deck, card_uuid: String, quantity: int = 1) -> void:
    deck.add_card(card_uuid, quantity)

func remove_card(deck: Deck, card_uuid: String, quantity: int = 1) -> bool:
    return deck.remove_card(card_uuid, quantity)

func set_card_quantity(deck: Deck, card_uuid: String, quantity: int) -> void:
    deck.set_card_quantity(card_uuid, quantity)

func get_card_metadata(uuid: String) -> CardMetadata:
    var results: Array[CardMetadata] = _card_repository.search_cards({
        "uuid": uuid,
        "page": 1,
        "page_size": 1,
    })
    return results[0] if results.size() > 0 else null
```

- [ ] **Step 2: Commit**

```bash
git add client/scripts/deck/deck_service.gd
git commit -m "feat: add deck service for business logic"
```

---

## Task 5: Create Deck Builder State Script

**Files:**
- Create: `client/states/deck_builder/deck_builder_state.gd`

- [ ] **Step 1: Write deck_builder_state.gd**

```gdscript
class_name DeckBuilderState
extends SceneHolderState

var deck_service: DeckService
var current_deck: Deck = null
var deck_list: Array[String] = []

@onready var deck_list_panel: Control = $"%DeckListPanel"
@onready var deck_editor_panel: Control = $"%DeckEditorPanel"
@onready var card_search_panel: Control = $"%CardSearchPanel"

func _ready() -> void:
    deck_service = DeckService.new(Global.card_repository)
    _load_deck_list()

func _load_deck_list() -> void:
    deck_list = deck_service.list_decks()

func create_deck(name: String, format: String = "Commander") -> void:
    current_deck = deck_service.create_deck(name, format)
    _load_deck_list()
    _update_deck_editor()

func load_deck(name: String) -> void:
    current_deck = deck_service.load_deck(name)
    _update_deck_editor()

func save_current_deck() -> bool:
    if current_deck == null:
        return false
    return deck_service.save_deck(current_deck)

func delete_deck(name: String) -> bool:
    var result: bool = deck_service.delete_deck(name)
    if result:
        _load_deck_list()
        if current_deck != null and current_deck.name == name:
            current_deck = null
    return result

func add_card_to_deck(card_uuid: String) -> void:
    if current_deck == null:
        return
    deck_service.add_card(current_deck, card_uuid, 1)
    _update_deck_editor()
    save_current_deck()

func remove_card_from_deck(card_uuid: String) -> bool:
    if current_deck == null:
        return false
    var result: bool = deck_service.remove_card(current_deck, card_uuid, 1)
    if result:
        _update_deck_editor()
        save_current_deck()
    return result

func set_card_quantity(card_uuid: String, quantity: int) -> void:
    if current_deck == null:
        return
    deck_service.set_card_quantity(current_deck, card_uuid, quantity)
    _update_deck_editor()
    save_current_deck()

func search_cards(query: Dictionary) -> Array[CardMetadata]:
    return Global.card_repository.search_cards(query)

func get_card_metadata(uuid: String) -> CardMetadata:
    return deck_service.get_card_metadata(uuid)

func _update_deck_editor() -> void:
    pass

func enter_scene() -> void:
    super.enter_scene()
    _load_deck_list()

func Name() -> String:
    return "DeckBuilder"
```

- [ ] **Step 2: Commit**

```bash
git add client/states/deck_builder/deck_builder_state.gd
git commit -m "feat: add deck builder state script"
```

---

## Task 6: Create Deck Builder UI Scene

**Files:**
- Create: `client/scenes/deck_builder/deck_builder.tscn`

- [ ] **Step 1: Write deck_builder.tscn**

```gdscript
[gd_scene format=3 uid="uid://deck_builder_scene"]

[ext_resource type="PackedScene" uid="uid://bg123" path="res://scenes/fractal_background.tscn" id="1_bg"]

[node name="DeckBuilder" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="Fractal Background" parent="." instance=ExtResource("1_bg")]
layout_mode = 1

[node name="HSplitContainer" type="HSplitContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="LeftPanel" type="PanelContainer" parent="HSplitContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="DeckList" type="VBoxContainer" parent="HSplitContainer/LeftPanel"]
layout_mode = 2

[node name="Header" type="Label" parent="HSplitContainer/LeftPanel/DeckList"]
layout_mode = 2
text = "My Decks"

[node name="NewDeckButton" type="Button" parent="HSplitContainer/LeftPanel/DeckList"]
layout_mode = 2
text = "+ New Deck"

[node name="DeckListScroll" type="ScrollContainer" parent="HSplitContainer/LeftPanel/DeckList"]
layout_mode = 2
size_flags_vertical = 3

[node name="DeckListVBox" type="VBoxContainer" parent="HSplitContainer/LeftPanel/DeckList/DeckListScroll"]
layout_mode = 2

[node name="MiddlePanel" type="PanelContainer" parent="HSplitContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="DeckEditor" type="VBoxContainer" parent="HSplitContainer/MiddlePanel"]
layout_mode = 2

[node name="DeckNameEdit" type="LineEdit" parent="HSplitContainer/MiddlePanel/DeckEditor"]
layout_mode = 2
placeholder_text = "Deck Name"

[node name="FormatSelect" type="OptionButton" parent="HSplitContainer/MiddlePanel/DeckEditor"]
layout_mode = 2

[node name="CardCountLabel" type="Label" parent="HSplitContainer/MiddlePanel/DeckEditor"]
layout_mode = 2
text = "0 cards"

[node name="CardsScroll" type="ScrollContainer" parent="HSplitContainer/MiddlePanel/DeckEditor"]
layout_mode = 2
size_flags_vertical = 3

[node name="CardsList" type="VBoxContainer" parent="HSplitContainer/MiddlePanel/DeckEditor/CardsScroll"]
layout_mode = 2

[node name="Actions" type="HBoxContainer" parent="HSplitContainer/MiddlePanel/DeckEditor"]
layout_mode = 2

[node name="DeleteButton" type="Button" parent="HSplitContainer/MiddlePanel/DeckEditor/Actions"]
layout_mode = 2
text = "Delete"

[node name="SaveButton" type="Button" parent="HSplitContainer/MiddlePanel/DeckEditor/Actions"]
layout_mode = 2
text = "Save"

[node name="RightPanel" type="PanelContainer" parent="HSplitContainer"]
layout_mode = 2
size_flags_horizontal = 3

[node name="CardSearch" type="VBoxContainer" parent="HSplitContainer/RightPanel"]
layout_mode = 2

[node name="SearchHeader" type="Label" parent="HSplitContainer/RightPanel/CardSearch"]
layout_mode = 2
text = "Search Cards"

[node name="NameFilter" type="LineEdit" parent="HSplitContainer/RightPanel/CardSearch"]
layout_mode = 2
placeholder_text = "Card Name"

[node name="SetFilter" type="LineEdit" parent="HSplitContainer/RightPanel/CardSearch"]
layout_mode = 2
placeholder_text = "Set Code"

[node name="SearchButton" type="Button" parent="HSplitContainer/RightPanel/CardSearch"]
layout_mode = 2
text = "Search"

[node name="SearchResultsScroll" type="ScrollContainer" parent="HSplitContainer/RightPanel/CardSearch"]
layout_mode = 2
size_flags_vertical = 3

[node name="SearchResultsGrid" type="GridContainer" parent="HSplitContainer/RightPanel/CardSearch/SearchResultsScroll"]
layout_mode = 2
columns = 3
```

- [ ] **Step 2: Commit**

```bash
git add client/scenes/deck_builder/deck_builder.tscn
git commit -m "feat: add deck builder UI scene"
```

---

## Task 7: Create Deck Builder State Scene

**Files:**
- Create: `client/states/deck_builder/deck_builder.gd` (scene wrapper)

- [ ] **Step 1: Write deck_builder.gd**

```gdscript
[gd_scene format=3 uid="uid://deck_builder_state_scene"]

[ext_resource type="Script" uid="uid://state123" path="res://states/deck_builder/deck_builder_state.gd" id="1"]
[ext_resource type="PackedScene" uid="uid://scene123" path="res://scenes/deck_builder/deck_builder.tscn" id="2"]

[node name="DeckBuilder" type="Node"]
script = ExtResource("1")
packed_scene = ExtResource("2")
```

- [ ] **Step 2: Commit**

```bash
git add client/states/deck_builder/deck_builder.gd
git commit -m "feat: add deck builder state scene"
```

---

## Task 8: Integrate Into State Machine

**Files:**
- Modify: `client/GameManager.tscn` - add deck builder state to state machine
- Modify: `client/states/entered/entered_state.gd` - add button to navigate to deck builder

- [ ] **Step 1: Read current GameManager.tscn to understand structure**

```bash
# First read the file to see current structure
```

- [ ] **Step 2: Add deck builder button to entered_state**

Add navigation to deck builder from the entered (lobby) state. The exact implementation depends on the current UI structure.

- [ ] **Step 3: Commit**

```bash
git add client/states/entered/entered_state.gd
git commit -m "feat: add navigation to deck builder from lobby"
```

---

## Task 9: Test and Verify

**Files:**
- Test: Manual testing via Godot editor

- [ ] **Step 1: Run Godot and navigate to deck builder**
- [ ] **Step 2: Create a new deck**
- [ ] **Step 3: Search and add cards**
- [ ] **Step 4: Save and verify JSON file created in user://cache/decks/**
- [ ] **Step 5: Reload and verify deck loads correctly**

---

## Verification Checklist

- [ ] Spec: Create decks with name - implemented in Deck.new() + DeckRepository.save()
- [ ] Spec: Add/remove cards - implemented in Deck.add_card(), remove_card(), set_card_quantity()
- [ ] Spec: Search/filter cards - uses existing CardRepository.search_cards()
- [ ] Spec: Format support - DeckFormat enum with predefined options
- [ ] Spec: Save locally to user://cache/decks/ - implemented in DeckRepository
- [ ] Spec: Single JSON per deck - implemented with Deck.to_dict() / from_dict()
- [ ] Spec: UI 3-panel layout - implemented in deck_builder.tscn

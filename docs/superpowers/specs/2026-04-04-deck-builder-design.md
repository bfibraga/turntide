# Deck Builder Design Specification

**Date**: 2026-04-04
**Author**: Bruno Braga
**Status**: Draft

---

## 1. Overview

Local deck builder for Turntide (MTG card game) with card browser, deck editing, and export capabilities. Similar to Cockatrice but with lazy-loaded card images.

### Goals
- Card browser with search/filter (local SQLite via GDSQLite)
- Deck editor (add/remove cards, maindeck + sideboard)
- Modular export (Archidekt, MTG Arena, MTG JSON formats)
- Lazy image loading (download on-demand, cache locally)

### Non-Goals
- Card collection tracking
- Server sync (local-only)
- Card price data

---

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Deck Builder                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐   │
│  │ CardBrowser  │  │  DeckEditor  │  │   ExportManager     │   │
│  │     UI       │  │     UI       │  │       UI            │   │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬───────────┘   │
│         │                 │                     │               │
│  ┌──────▼─────────────────▼─────────────────────▼───────────┐ │
│  │                    DeckManager                             │ │
│  │  - load/save decks  - add/remove cards  - export          │ │
│  └─────────────────────┬──────────────────────────────────────┘ │
│                        │                                        │
│  ┌─────────────────────▼──────────────────────────────────────┐ │
│  │  CardRepository (GDSQLite)                                 │ │
│  │  - search_cards()  - get_card_by_uuid()                    │ │
│  └─────────────────────┬──────────────────────────────────────┘ │
│                        │                                        │
│  ┌─────────────────────▼──────────────────────────────────────┐ │
│  │  ImageLoader                                               │ │
│  │  - lazy load on add  - cache to res://resources/images/    │ │
│  └────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility |
|-----------|----------------|
| `CardRepository` | Query SQLite for card metadata |
| `ImageLoader` | Lazy-load images, manage cache |
| `DeckManager` | Deck CRUD operations, format handling |
| `DeckFormat` | Serialize/deserialize deck data |
| `CardBrowser` | Search UI, filter controls |
| `DeckEditor` | Deck list UI, add/remove controls |
| `ExportManager` | Format selection, file output |

---

## 3. Data Models

### 3.1 Card Metadata (from SQLite)

```gdscript
class_name CardMetadata
extends RefCounted

var uuid: String
var name: String
var set_code: String
var number: String
var rarity: String
var type_line: String
var mana_value: float
var colors: String
var text: String
var power: String
var toughness: String
var scryfall_id: String
```

### 3.2 Card Entry (in deck)

```gdscript
class_name CardEntry
extends RefCounted

var metadata: CardMetadata
var quantity: int
var is_sideboard: bool
var texture: Texture2D  # Lazy-loaded
```

### 3.3 Deck Data

```gdscript
class_name DeckData
extends RefCounted

var name: String
var format: String  # "standard", "commander", etc.
var mainboard: Array[CardEntry]
var sideboard: Array[CardEntry]
var created_at: String
var updated_at: String
```

---

## 4. Deck Format System

### Interface

```gdscript
class_name DeckFormatInterface
extends RefCounted

func serialize(deck: DeckData) -> String:
    pass

func deserialize(content: String, name: String) -> DeckData:
    pass
```

### Supported Formats

| Format | File Extension | Description |
|--------|----------------|-------------|
| Archidekt | `.json` | Archidekt export format |
| MTG Arena | `.txt` | Arena import format |
| MTG JSON | `.json` | MTGJSON deck format |
| Turntide | `.json` | Internal format (recommended) |

### Turntide JSON Format (Internal)

```json
{
  "name": "My Deck",
  "format": "commander",
  "mainboard": [
    { "uuid": "...", "quantity": 1 },
    { "uuid": "...", "quantity": 4 }
  ],
  "sideboard": [
    { "uuid": "...", "quantity": 2 }
  ],
  "created_at": "2026-04-04T12:00:00Z",
  "updated_at": "2026-04-04T12:00:00Z"
}
```

---

## 5. Image Loading Strategy

### Flow

1. Card added to deck → check `res://resources/images/{uuid}.png`
2. If exists → load from disk
3. If not exists → call fetcher CLI to download from Scryfall
4. Cache to `res://resources/images/`
5. Reload and display

### Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `image_path` | `res://resources/images/` | Image cache directory |
| `fetcher_path` | (configurable) | Path to fetcher binary |
| `cache_enabled` | `true` | Enable image caching |

---

## 6. Card Browser UI

### Layout

```
┌──────────────────────────────────────────────────────────────┐
│  [Search Bar                    ] [Filters ▼] [New] [Save]  │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐     │
│  │Card 1│ │Card 2│ │Card 3│ │Card 4│ │Card 5│ │Card 6│     │
│  │      │ │      │ │      │ │      │ │      │ │      │     │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘     │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐     │
│  │Card 7│ │Card 8│ │Card 9│ │Card 10│ │Card 11│ │Card 12│    │
│  │      │ │      │ │      │ │      │ │      │ │      │     │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘     │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  Showing 1-100 of 5000  [< Prev] [1] [2] [3...10] [Next >] │
└──────────────────────────────────────────────────────────────┘
```

### Filters
- Set: Dropdown (all sets from DB)
- Type: Dropdown (creature, instant, sorcery, etc.)
- Rarity: Dropdown (common, uncommon, rare, mythic)
- Color: Multi-select (W, U, B, R, G)
- Mana Value: Range slider (0-15)

---

## 7. Deck Editor UI

### Layout

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  Deck: [Deck Name                        ] [Export ▼] [Toggle View: List↔Grid]│
├──────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────┬──────────────────────────────────────┐│
│  │         DECK LIST               │        IMAGE VIEWER                  ││
│  │  ┌───────────────────────────┐  │  ┌────────────────────────────┐      ││
│  │  │ MAINBOARD (60)            │  │  │                            │      ││
│  │  │ ─────────────────────────│  │  │  ┌────┐ ┌────┐ ┌────┐      │      ││
│  │  │ 4x Lightning Bolt [M19]  │  │  │  │    │ │    │ │    │      │      ││
│  │  │ 1x Wrath of God [AKH]    │  │  │  │Card│ │Card│ │Card│      │      ││
│  │  │ 4x Counterspell [STX]     │  │  │  │ 1  │ │ 2  │ │ 3  │      │      ││
│  │  │ 4x Lightning Bolt [M19]  │  │  │  └────┘ └────┘ └────┘      │      ││
│  │  │ 3x Counterspell [STX]     │  │  │  ┌────┐ ┌────┐ ┌────┐      │      ││
│  │  │ ...                       │  │  │  │    │ │    │ │    │      │      ││
│  │  └───────────────────────────┘  │  │  │Card│ │Card│ │Card│      │      ││
│  │  ┌───────────────────────────┐  │  │  │ 4  │ │ 5  │ │ 6  │      │      ││
│  │  │ SIDEBOARD (15)            │  │  │  └────┘ └────┘ └────┘      │      ││
│  │  │ ─────────────────────────│  │  │                            │      ││
│  │  │ 2x Negate [M20]          │  │  │  [Hover to enlarge]       │      ││
│  │  │ 1x Fragmentize [KLD]     │  │  └────────────────────────────┘      ││
│  │  │ ...                       │  │                                      ││
│  │  └───────────────────────────┘  │                                      ││
│  └─────────────────────────────────┴──────────────────────────────────────┘│
├──────────────────────────────────────────────────────────────────────────────┤
│  Stats: 60 cards | avg CMC: 2.3 | Lands: 24                                │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Image Viewer Component

The Image Viewer displays card images in a grid layout, synchronizing with the selected card in the deck list.

| Feature | Description |
|---------|-------------|
| **Grid Layout** | Responsive grid of card thumbnails |
| **Hover Preview** | Hovering a thumbnail shows enlarged version |
| **Selection Sync** | Clicking a card in list highlights it in viewer |
| **Lazy Loading** | Images load on-demand as user scrolls |
| **View Toggle** | Switch between list-only, split, or image-only view |

### Interactions

1. **List Selection**: Click card in list → scroll to card in viewer
2. **Viewer Selection**: Click card in viewer → scroll to card in list
3. **Hover Enlarge**: Mouse hover on thumbnail shows full-size preview
4. **Drag Reorder**: Drag cards in list to reorder (optional)

---

## 8. Integration with Game

### State Machine Integration

The deck builder integrates as a new game state:

```
Client State Machine
├── ClosedState
├── ConnectedState
│   ├── LoginState
│   └── RegisterState
├── EnteredState (Lobby)
│   └── DeckBuilderState ← NEW
└── InGameState
```

### Entry Points

1. **From Lobby**: Button "Deck Builder" → transition to `DeckBuilderState`
2. **In-Game**: During mulligan, allow deck swapping

---

## 9. Error Handling

| Scenario | Handling |
|----------|----------|
| SQLite not found | Show error dialog, offer to configure path |
| Card not found in DB | Show "Card not found" in search results |
| Image fetch failed | Show placeholder, retry on next add |
| Deck file corrupted | Show error, offer to create new |
| Invalid export format | Show format error dialog |

---

## 10. Performance Considerations

- **Card Grid**: Use `ItemGrid` with visible-only rendering for large result sets
- **Image Loading**: Background thread, show loading spinner
- **Search**: Debounce input (300ms), paginate results (100 per page)
- **Deck Save**: Async write to avoid UI freeze

---

## 11. Future Considerations

- [ ] Server sync for deck sharing
- [ ] Card collection tracking
- [ ] Deck statistics (mana curve, color distribution)
- [ ] Import from URL (DeckStats, TappedOut)
- [ ] Card pricing data
- [ ] Deck validation (format legality)

---

## 12. Acceptance Criteria

1. ✓ Can search cards by name, set, type, rarity
2. ✓ Can add cards to maindeck or sideboard
3. ✓ Can adjust card quantities
4. ✓ Can remove cards from deck
5. ✓ Can save deck to local JSON file
6. ✓ Can load deck from local JSON file
7. ✓ Can export deck to Archidekt format
8. ✓ Can export deck to MTG Arena format
9. ✓ Images lazy-load when cards added
10. ✓ Images cached in `res://resources/images/`
11. ✓ Works offline after initial image load
12. ✓ Image viewer displays card thumbnails in grid
13. ✓ Hover on thumbnail shows enlarged preview
14. ✓ Selection syncs between list and image viewer

---

## 13. Dependencies

| Dependency | Purpose | Status |
|------------|---------|--------|
| GDSQLite | SQLite access | User will download |
| Fetcher CLI | Image downloads | Already exists |
| Godot 4.6 | Engine | Installed |

---

## 14. File Structure

```
client/
├── scripts/
│   └── deck_builder/
│       ├── deck_manager.gd          # Main orchestrator
│       ├── card_repository.gd       # SQLite access
│       ├── image_loader.gd         # Lazy image loading
│       ├── models/
│       │   ├── card_metadata.gd    # Card data model
│       │   ├── card_entry.gd        # Deck card entry
│       │   └── deck_data.gd         # Full deck model
│       ├── formats/
│       │   ├── format_interface.gd  # Abstract base
│       │   ├── archidekt_format.gd  # Archidekt JSON
│       │   ├── arena_format.gd      # MTG Arena text
│       │   └── mtgjson_format.gd    # MTGJSON format
│       └── ui/
│           ├── deck_builder.gd      # Main UI scene
│           ├── card_browser.gd      # Card search/grid
│           ├── deck_editor.gd       # Deck list panel
│           └── export_dialog.gd     # Export options
├── scenes/
│   └── deck_builder/
│       ├── deck_builder.tscn        # Main scene
│       ├── card_browser.tscn       # Card grid
│       └── deck_editor.tscn        # Deck panels
└── resources/
    └── images/                      # Image cache (generated)
```

---

**End of Design Specification**
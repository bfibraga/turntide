# PrintingsManager Design

**Date:** 2026-04-05
**Status:** Approved

## Overview

Manages card printing downloads with tracking, abstracting the FetcherCLI from consumers.

## Purpose

- Track which printings (card+set+number) have been downloaded
- Download printings on demand (only missing ones)
- Provide O(1) lookup for download status

## Architecture

### Singleton Pattern

- Accessible via `Global.printings_manager`
- Follows existing `Global.fetcher_cli` pattern in codebase

### Location

`client/scripts/utils/cli/printings_manager.gd`

### Responsibilities

1. Owns `FetcherCLI` instance
2. Ensures `cards.db` exists (first-run download)
3. Tracks downloaded printings in memory + JSON file
4. Downloads missing printings on demand

## Data Model

### In-Memory Tracking

`Dictionary` keyed by `uuid_setcode_number` for O(1) lookups.

```gdscript
{
    "uuid_setcode_number": {
        "path": "user://cache/images/CardName_setcode_abc123.png",
        "downloaded_at": "2026-04-05T10:30:00Z",
        "format": "png"
    }
}
```

Key format: `{uuid}_{setcode}_{number}` (underscore-separated)

### Persistence

- **File:** `user://cache/printings.json`
- **Load:** On init, read JSON into in-memory dict
- **Save:** On exit + periodic (every 10 downloads)

### Protection

1. **Atomic writes:** Write to temp file, then rename to replace original
2. **Periodic saves:** Every 10 new downloads
3. **Validation:** On load, validate JSON structure; if invalid, start fresh
4. **Rebuild method:** `rebuild()` regenerates tracker from filesystem

## API

### Core Methods

| Method | Description |
|--------|-------------|
| `is_downloaded(uuid, setcode, number) -> bool` | O(1) lookup |
| `get_needed(printings) -> Array[CardMetadata]` | Filter to missing only |
| `download(printings)` | Download missing printings |
| `rebuild()` | Regenerate tracker from filesystem |
| `clear()` | Reset all tracking |

### Integration with CardViewer

**Before (current):**
```gdscript
@onready var fetcher_cli: FetcherCLI = FetcherCLI.new()

func _ready() -> void:
    if !FileAccess.file_exists("user://cache/database/cards.db"):
        fetcher_cli.download().db_path("user://cache/database/cards.db").run()
    Global.fetcher_cli = fetcher_cli

func _on_card_name_search(card_name: String) -> void:
    var cards = Global.card_repository.search_cards(...)
    fetcher_cli.images().card_list(cards).run()
```

**After (with PrintingsManager):**
```gdscript
func _ready() -> void:
    Global.printings_manager.ensure_db_ready()

func _on_card_name_search(card_name: String) -> void:
    var cards = Global.card_repository.search_cards(...)
    Global.printings_manager.download(cards)
```

## File Paths

- **DB:** `user://cache/database/cards.db`
- **Images:** `user://cache/images/`
- **Tracker:** `user://cache/printings.json`

## Error Handling

- If tracker JSON corrupted, log warning and start fresh
- If download fails, report to consumer via signal
- If file missing but tracked, `rebuild()` recovers

## Implementation Notes

- Inherits from `RefCounted` (following `CLIWrapper` pattern)
- Uses `FileAccess` for JSON read/write
- Uses `DirAccess` for directory operations
- Signals: `download_started`, `download_progress`, `download_completed`
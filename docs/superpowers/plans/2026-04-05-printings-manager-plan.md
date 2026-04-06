# PrintingsManager Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a PrintingsManager class that tracks downloaded printings and abstracts FetcherCLI from consumers

**Architecture:** Singleton via Global.printings_manager, in-memory Dictionary for O(1) lookups, JSON persistence with atomic writes

**Tech Stack:** GDScript, Godot 4.6, SQLite (existing)

---

## File Structure

| File | Action | Purpose |
|------|--------|---------|
| `client/scripts/utils/cli/printings_manager.gd` | Create | Main class |
| `client/scripts/global.gd` | Modify | Add singleton |
| `client/card_viewer.gd` | Modify | Use PrintingsManager |

---

## Task 1: Create PrintingsManager Class

**Files:**
- Create: `client/scripts/utils/cli/printings_manager.gd`

- [ ] **Step 1: Write the skeleton with class definition and constants**

```gdscript
class_name PrintingsManager
extends RefCounted

const TRACKER_FILE := "user://cache/printings.json"
const DB_PATH := "user://cache/database/cards.db"
const IMAGES_PATH := "user://cache/images/"
const SAVE_INTERVAL := 10

var _fetcher_cli: FetcherCLI
var _printings: Dictionary = {}
var _save_counter: int = 0

signal download_progress(card_name: String, status: String)
signal download_completed(success: bool, message: String)

func _init() -> void:
    _fetcher_cli = FetcherCLI.new()
```

- [ ] **Step 2: Add load_tracker method**

```gdscript
func load_tracker() -> void:
    if not FileAccess.file_exists(TRACKER_FILE):
        return
    
    var file := FileAccess.open(TRACKER_FILE, FileAccess.READ)
    if file == null:
        push_warning("Failed to open tracker file, starting fresh")
        return
    
    var json_string := file.get_as_text()
    file.close()
    
    var json := JSON.new()
    var error := json.parse(json_string)
    if error != OK:
        push_warning("Tracker JSON corrupted, starting fresh")
        return
    
    var data: Dictionary = json.get_data()
    if data.is_empty():
        return
    
    _printings = data
```

- [ ] **Step 3: Add save_tracker method with atomic write**

```gdscript
func save_tracker() -> void:
    var json_string := JSON.stringify(_printings, "  ")
    
    var temp_file := TRACKER_FILE + ".tmp"
    var file := FileAccess.open(temp_file, FileAccess.WRITE)
    if file == null:
        push_error("Failed to write temp tracker file")
        return
    
    file.store_string(json_string)
    file.close()
    
    var dir := DirAccess.open("user://cache/")
    if dir == null:
        push_error("Failed to open user cache directory")
        return
    
    var err := dir.rename(temp_file, TRACKER_FILE)
    if err != OK:
        push_error("Failed to rename temp tracker file")
```

- [ ] **Step 4: Add is_downloaded method**

```gdscript
func is_downloaded(uuid: String, setcode: String, number: String) -> bool:
    var key := _make_key(uuid, setcode, number)
    return _printings.has(key)
```

- [ ] **Step 5: Add _make_key helper**

```gdscript
func _make_key(uuid: String, setcode: String, number: String) -> String:
    return "%s_%s_%s" % [uuid, setcode, number]
```

- [ ] **Step 6: Add get_needed method**

```gdscript
func get_needed(printings: Array[CardMetadata]) -> Array[CardMetadata]:
    var needed: Array[CardMetadata] = []
    for card: CardMetadata in printings:
        if not is_downloaded(card.uuid, card.setcode, card.number):
            needed.append(card)
    return needed
```

- [ ] **Step 7: Add ensure_db_ready method**

```gdscript
func ensure_db_ready() -> void:
    if not FileAccess.file_exists(DB_PATH):
        DirAccess.make_dir_recursive_absolute("user://cache/database")
        _fetcher_cli.download().db_path(DB_PATH).run()
```

- [ ] **Step 8: Add download method**

```gdscript
func download(printings: Array[CardMetadata]) -> void:
    var needed := get_needed(printings)
    if needed.is_empty():
        download_completed.emit(true, "All printings already downloaded")
        return
    
    DirAccess.make_dir_recursive_absolute(IMAGES_PATH)
    
    _fetcher_cli.images() \
        .db_path(DB_PATH) \
        .output_dir(IMAGES_PATH) \
        .card_list(needed) \
        .run()
    
    _fetcher_cli.task_finished.connect(_on_download_finished.bind(needed))

func _on_download_finished(output: Array[String], exit_code: int, downloaded: Array[CardMetadata]) -> void:
    _fetcher_cli.task_finished.disconnect(_on_download_finished)
    
    for card: CardMetadata in downloaded:
        var key := _make_key(card.uuid, card.setcode, card.number)
        _printings[key] = {
            "path": _get_image_path(card),
            "downloaded_at": Time.get_datetime_string_from_system(true),
            "format": "png"
        }
    
    _save_counter += 1
    if _save_counter >= SAVE_INTERVAL:
        save_tracker()
        _save_counter = 0
    
    if exit_code != 0:
        push_error("Download failed with exit code: ", exit_code)
        download_completed.emit(false, "Download failed: " + str(exit_code))
    else:
        download_completed.emit(true, "Downloaded %d printings" % downloaded.size())
```

- [ ] **Step 9: Add _get_image_path helper**

```gdscript
func _get_image_path(card: CardMetadata) -> String:
    var filename := "%s_%s_%s.png" % [card.name.replace(" ", "_"), card.setcode, card.uuid.substr(0, 8)]
    return IMAGES_PATH + filename
```

- [ ] **Step 10: Add rebuild method**

```gdscript
func rebuild() -> void:
    _printings.clear()
    
    if not DirAccess.dir_exists_absolute(IMAGES_PATH):
        return
    
    var dir := DirAccess.open(IMAGES_PATH)
    if dir == null:
        return
    
    dir.list_dir_begin()
    var filename := dir.get_next()
    while filename != "":
        if filename.ends_with(".png") or filename.ends_with(".jpg") or filename.ends_with(".webp"):
            var parts := filename.split("_")
            if parts.size() >= 3:
                var uuid := parts[parts.size() - 2]
                var setcode := parts[parts.size() - 3]
                var key := _make_key(uuid, setcode, "")
                _printings[key] = {
                    "path": IMAGES_PATH + filename,
                    "downloaded_at": "rebuilt",
                    "format": filename.get_extension()
                }
        filename = dir.get_next()
    dir.list_dir_end()
    
    save_tracker()
```

- [ ] **Step 11: Add clear method**

```gdscript
func clear() -> void:
    _printings.clear()
    save_tracker()
```

- [ ] **Step 12: Add _exit_tree to save on exit**

```gdscript
func _exit_tree() -> void:
    save_tracker()
```

- [ ] **Step 13: Commit**

```bash
git add client/scripts/utils/cli/printings_manager.gd
git commit -m "feat: add PrintingsManager class for tracking downloads"
```

---

## Task 2: Add PrintingsManager to Global

**Files:**
- Modify: `client/scripts/global.gd:6`

- [ ] **Step 1: Add printings_manager variable**

```gdscript
var printings_manager: PrintingsManager
```

- [ ] **Step 2: Add initialization in _ready or init**

The Global is a Node, so we need to initialize the PrintingsManager when Global is ready. But since PrintingsManager extends RefCounted, we can instantiate it directly.

```gdscript
func _ready() -> void:
    printings_manager = PrintingsManager.new()
    printings_manager.load_tracker()
```

- [ ] **Step 3: Commit**

```bash
git add client/scripts/global.gd
git commit -m "feat: add printings_manager singleton to Global"
```

---

## Task 3: Update CardViewer to use PrintingsManager

**Files:**
- Modify: `client/card_viewer.gd`

- [ ] **Step 1: Remove FetcherCLI instance variable**

Remove line 14: `@onready var fetcher_cli: FetcherCLI = FetcherCLI.new()`

- [ ] **Step 2: Update _ready to use PrintingsManager**

Replace lines 30-38:
```gdscript
    page_spin_box.value = page
    total_spin_box.value = page_size

    Global.printings_manager.ensure_db_ready()
```

- [ ] **Step 3: Remove Global.fetcher_cli assignment**

Remove line 38: `Global.fetcher_cli = fetcher_cli`

- [ ] **Step 4: Remove task_finished signal connection**

Remove line 25: `fetcher_cli.task_finished.connect(_on_fetcher_cli_task_finished)`

- [ ] **Step 5: Update _on_card_name_search**

Replace lines 40-53:
```gdscript
func _on_card_name_search(card_name: String) -> void:
    var cards: Array[CardMetadata] = Global.card_repository.search_cards({ 
        "name": card_name,
        "page": page,
        "page_size": page_size 
    })
    
    Global.printings_manager.download(cards)
```

- [ ] **Step 6: Update _on_fetcher_cli_task_finished to handle download_completed**

Replace the method to use PrintingsManager's signal:
```gdscript
func _on_printings_download_completed(success: bool, message: String) -> void:
    if not success:
        push_error(message)
    
    rich_text.clear()
    rich_text.append_text(message + "\n")
```

- [ ] **Step 7: Add signal connection in _ready**

Add after line 29:
```gdscript
    Global.printings_manager.download_completed.connect(_on_printings_download_completed)
```

- [ ] **Step 8: Commit**

```bash
git add client/card_viewer.gd
git commit -m "refactor: use PrintingsManager instead of direct FetcherCLI"
```

---

## Verification

- [ ] Run Godot and verify CardViewer works
- [ ] Check that printings.json is created in user://cache/
- [ ] Verify that multiple searches don't re-download existing images

---

## Plan complete

Saved to: `docs/superpowers/plans/2026-04-05-printings-manager-plan.md`

**Two execution options:**

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

**Which approach?**
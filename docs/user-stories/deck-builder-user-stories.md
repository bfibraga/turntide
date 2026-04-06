# Turntide Deck Builder - User Stories

**Project**: Turntide Deck Builder
**Date**: 2026-04-04
**Status**: Draft

---

## 1. Card Browser

### US-001: Search Cards by Name
**As a** player  
**I want to** search for cards by typing their name  
**So that** I can quickly find specific cards in the database

**Acceptance Criteria**:
- Search input accepts partial card names
- Results update as user types (with debounce)
- Results show card name, set, and type
- Empty search returns all cards (paginated)

### US-002: Filter Cards by Set
**As a** player  
**I want to** filter cards by set code  
**So that** I can find cards from a specific expansion

**Acceptance Criteria**:
- Dropdown shows all available sets from database
- Selecting a set filters results to that set only
- Filter combines with name search

### US-003: Filter Cards by Type
**As a** player  
**I want to** filter cards by card type  
**So that** I can find all creatures, instants, sorceries, etc.

**Acceptance Criteria**:
- Dropdown shows: Creature, Instant, Sorcery, Artifact, Enchantment, Planeswalker, Land
- Filter combines with other filters

### US-004: Filter Cards by Rarity
**As a** player  
**I want to** filter cards by rarity  
**So that** I can find all commons, uncommons, rares, or mythics

**Acceptance Criteria**:
- Dropdown shows: Common, Uncommon, Rare, Mythic
- Filter combines with other filters

### US-005: Filter Cards by Color
**As a** player  
**I want to** filter cards by color  
**So that** I can find all white, blue, black, red, green, or multicolored cards

**Acceptance Criteria**:
- Multi-select for W, U, B, R, G colors
- Filter combines with other filters

### US-006: Browse Card Results
**As a** player  
**I want to** browse through search results with pagination  
**So that** I can see many cards without loading all at once

**Acceptance Criteria**:
- Results paginated (100 per page)
- Page navigation shows current page and total
- Previous/Next buttons work correctly

---

## 2. Deck Editor

### US-010: Create New Deck
**As a** player  
**I want to** create a new empty deck  
**So that** I can start building a new deck from scratch

**Acceptance Criteria**:
- "New Deck" button creates empty deck
- User can enter deck name
- Mainboard and sideboard start empty

### US-011: Add Card to Mainboard
**As a** player  
**I want to** add a card to my mainboard from the card browser  
**So that** I can build my deck

**Acceptance Criteria**:
- Double-click or drag card from browser to mainboard
- Card appears in mainboard list with quantity 1
- Adding same card increments quantity

### US-012: Add Card to Sideboard
**As a** player  
**I want to** add a card to my sideboard  
**So that** I can include cards for post-board games

**Acceptance Criteria**:
- Drag card to sideboard panel
- Or use "Add to Sideboard" button
- Card appears in sideboard list

### US-013: Adjust Card Quantity
**As a** player  
**I want to** change the quantity of a card in my deck  
**So that** I can run 4 copies of a card instead of 1

**Acceptance Criteria**:
- Click +/- buttons to adjust quantity
- Minimum quantity is 1
- Setting to 0 removes card from deck

### US-014: Remove Card from Deck
**As a** player  
**I want to** remove a card from my deck  
**So that** I can adjust my deck composition

**Acceptance Criteria**:
- Right-click shows "Remove" option
- Click remove button removes card
- Card removed from both mainboard and sideboard

### US-015: Move Card Between Mainboard and Sideboard
**As a** player  
**I want to** move cards between mainboard and sideboard  
**So that** I can reorganize my deck

**Acceptance Criteria**:
- Drag card from mainboard to sideboard panel
- Drag card from sideboard to mainboard
- Quantity preserved during move

### US-016: View Deck Statistics
**As a** player  
**I want to** see deck statistics  
**So that** I can analyze my deck composition

**Acceptance Criteria**:
- Shows total card count (mainboard + sideboard)
- Shows average mana value (CMC)
- Shows land count
- Updates in real-time as deck changes

---

## 3. Image Viewer

### US-020: View Card Images in Deck
**As a** player  
**I want to** see card images in a grid view  
**So that** I can visualize my deck

**Acceptance Criteria**:
- Image viewer shows cards from current deck
- Cards displayed as thumbnail grid
- Lazy-loads images as user scrolls

### US-021: Hover to Enlarge Card Image
**As a** player  
**I want to** hover over a card thumbnail to see enlarged version  
**So that** I can read card details

**Acceptance Criteria**:
- Hovering shows larger version of card
- Shows card name and type line
- Pop-up follows mouse position

### US-022: Sync Selection Between List and Image Viewer
**As a** player  
**I want to** click a card in either list or image viewer and have both sync  
**So that** I can navigate easily

**Acceptance Criteria**:
- Click card in list scrolls to card in viewer
- Click card in viewer scrolls to card in list
- Selected card highlighted in both views

### US-023: Toggle View Mode
**As a** player  
**I want to** switch between list-only, split, or image-only view  
**So that** I can customize my workspace

**Acceptance Criteria**:
- Toggle button switches between modes
- Split view shows both list and images
- Mode preference remembered

---

## 4. Deck Storage

### US-030: Save Deck to File
**As a** player  
**I want to** save my deck to a local file  
**So that** I can come back to it later

**Acceptance Criteria**:
- "Save" button prompts for filename
- Deck saved as JSON to user://decks/
- Includes all cards, quantities, sideboard
- Includes metadata (name, created_at, updated_at)

### US-031: Load Deck from File
**As a** player  
**I want to** load a previously saved deck  
**So that** I can continue editing

**Acceptance Criteria**:
- "Load" button shows list of saved decks
- Selecting deck loads it into editor
- Mainboard and sideboard populated correctly
- Handles corrupted files gracefully

### US-032: List Saved Decks
**As a** player  
**I want to** see a list of all my saved decks  
**So that** I can choose which to load

**Acceptance Criteria**:
- Shows deck name and card count
- Shows last modified date
- Can sort by name or date

### US-033: Delete Saved Deck
**As a** player  
**I want to** delete a saved deck  
**So that** I can remove decks I no longer need

**Acceptance Criteria**:
- Delete option in deck list
- Confirmation dialog before delete
- Deck removed from storage

---

## 5. Export

### US-040: Export to Archidekt Format
**As a** player  
**I want to** export my deck in Archidekt format  
**So that** I can import it into Archidekt.com

**Acceptance Criteria**:
- Export dialog offers Archidekt format
- Output follows Archidekt JSON schema
- Includes mainboard and sideboard
- File saved with .json extension

### US-041: Export to MTG Arena Format
**As a** player  
**I want to** export my deck for MTG Arena  
**So that** I can import it into Arena

**Acceptance Criteria**:
- Export dialog offers MTG Arena format
- Output is plain text with "1 Card Name [Set]" format
- Properly handles quantity (1 per line)

### US-042: Export to MTGJSON Format
**As a** player  
**I want to** export my deck in MTGJSON format  
**So that** I can use it with other tools

**Acceptance Criteria**:
- Export dialog offers MTGJSON format
- Output follows MTGJSON deck schema
- Includes commander slot for EDH

---

## 6. Image Loading

### US-050: Lazy Load Card Images
**As a** player  
**I want to** have card images load on-demand  
**So that** initial load is fast

**Acceptance Criteria**:
- Images load only when card is added to deck
- Loading spinner shown while fetching
- Images cached after first load

### US-051: Cache Card Images Locally
**As a** player  
**I want to** have card images cached locally  
**So that** they load instantly on subsequent views

**Acceptance Criteria**:
- Images stored in res://resources/images/
- Filename based on card UUID
- Cache persists across sessions

### US-052: Download Missing Images
**As a** player  
**I want to** have missing images downloaded automatically  
**So that** I can see all cards in my deck

**Acceptance Criteria**:
- If image not cached, fetcher CLI is called
- Downloads from Scryfall API
- Shows progress during download
- Handles network errors gracefully

### US-053: Work Offline with Cached Images
**As a** player  
**I want to** use the deck builder offline  
**So that** I can work without internet

**Acceptance Criteria**:
- Previously cached images work offline
- New downloads require internet
- Clear error message if image unavailable offline

---

## 7. Integration

### US-060: Enter Deck Builder from Lobby
**As a** player  
**I want to** access the deck builder from the main lobby  
**So that** I can manage my decks before playing

**Acceptance Criteria**:
- "Deck Builder" button in lobby
- Clicking transitions to deck builder state
- Can return to lobby from deck builder

### US-061: Select Deck Before Game
**As a** player  
**I want to** select a deck before starting a game  
**So that** I can use my built deck

**Acceptance Criteria**:
- In pre-game, can browse saved decks
- Select deck loads it for the game
- Deck validated before game starts

---

## 8. Error Handling

### US-070: Handle Missing Database
**As a** player  
**I want to** see a clear error if the card database is not found  
**So that** I know what to fix

**Acceptance Criteria**:
- Error dialog explains the issue
- Suggests checking GDSQLite plugin installation

### US-071: Handle Corrupt Deck File
**As a** player  
**I want to** see a clear error if a deck file is corrupt  
**So that** I can recover or delete it

**Acceptance Criteria**:
- Error dialog shows "Invalid deck file"
- Offer to create new deck or delete corrupt file

### US-072: Handle Network Failure
**As a** player  
**I want to** see a clear error if image download fails  
**So that** I know the card image won't display

**Acceptance Criteria**:
- Error shown for failed downloads
- Retry option available
- Placeholder shown for unavailable images

---

## Appendix: Story Mapping

```
Epic: Card Browser
├── US-001: Search by name
├── US-002: Filter by set
├── US-003: Filter by type
├── US-004: Filter by rarity
├── US-005: Filter by color
└── US-006: Browse with pagination

Epic: Deck Editor
├── US-010: Create new deck
├── US-011: Add to mainboard
├── US-012: Add to sideboard
├── US-013: Adjust quantity
├── US-014: Remove card
├── US-015: Move between main/side
└── US-016: View stats

Epic: Image Viewer
├── US-020: View card images
├── US-021: Hover enlarge
├── US-022: Sync selection
└── US-023: Toggle view mode

Epic: Deck Storage
├── US-030: Save deck
├── US-031: Load deck
├── US-032: List decks
└── US-033: Delete deck

Epic: Export
├── US-040: Archidekt format
├── US-041: MTG Arena format
└── US-042: MTGJSON format

Epic: Image Loading
├── US-050: Lazy load
├── US-051: Local cache
├── US-052: Auto download
└ US-053: Offline support

Epic: Integration
├── US-060: Enter from lobby
└── US-061: Select before game

Epic: Error Handling
├── US-070: Missing DB
├── US-071: Corrupt file
└── US-072: Network failure
```

---

**End of User Stories**
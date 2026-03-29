# Scryfall Image Provider - Testing Guide

This document provides comprehensive testing procedures for the Scryfall image provider.

## Quick Start

### Run All Tests
```bash
cd /home/bfbraga/Documents/Programming/turntide
go test -v ./fetcher/internal/images/providers/
go test -v ./fetcher/cmd/
go test -v ./fetcher/internal/parsers/
```

### Run with Coverage
```bash
go test -cover ./fetcher/...
go test -coverprofile=coverage.out ./fetcher/...
go tool cover -html=coverage.out
```

### Run Benchmarks
```bash
go test -bench=. ./fetcher/internal/images/providers/
```

## Unit Tests

### File: `fetcher/internal/images/providers/scryfall_test.go`

Unit tests are organized by functionality:

#### 1. URL Building Tests
```bash
go test -run TestBuildScryfallImageURL -v
```
Tests:
- PNG format URL generation
- JPG format URL generation
- WebP format URL generation

Expected: All URLs follow pattern `https://api.scryfall.com/cards/{scryfallID}`

#### 2. Filename Sanitization Tests
```bash
go test -run TestSanitizeFilename -v
```
Tests:
- Simple card names (Island → Island)
- Names with slashes (Time / Tide → Time___Tide)
- Names with quotes ("The" Card → _The__Card)
- Names with colons (Name: Card → Name__Card)
- Complex names with multiple special chars

Expected: All invalid filename characters are replaced with underscores

#### 3. Image URL Selection Tests
```bash
go test -run TestGetImageURL -v
```
Tests:
- Preferring large over normal over small
- Fallback when large is missing
- Fallback when normal is missing
- Empty URLs list handling
- Empty URL strings handling

Expected: Always selects the best available image resolution

#### 4. HTTP Request Creation Tests
```bash
go test -run TestMustNewRequest -v
```
Tests:
- User-Agent header is set
- Accept header is application/json
- Request URL is correct
- Request method is correct

Expected: Requests have required Scryfall API headers

#### 5. Filename Creation Tests
```bash
go test -run TestCreateFilename -v
```
Tests:
- JPEG file extension detection
- PNG file extension detection
- WebP file extension detection
- Filename format: `CardName_SetCode_UUID.ext`

Expected: Correct file extensions and naming

## Integration Tests

### Manual Integration Testing

#### Test 1: Single Card Download
```bash
cd /home/bfbraga/Documents/Programming/turntide

# Create a test decklist
cat > test_deck.txt << 'EOF'
Island [LRW]
EOF

# Download images
go run ./fetcher images -d test_deck.txt -o ./test_output

# Verify
ls -lah test_output/
file test_output/*
```

Expected output:
```
Downloaded: Island [LRW]
Successfully downloaded images to ./test_output
```

Files created:
```
Island_LRW_bc9c4be7.jpg (200KB+)
```

#### Test 2: Multiple Cards
```bash
cat > test_deck.txt << 'EOF'
Island [LRW]
Mountain [LRW]
Forest [LRW]
Swamp [LRW]
Plains [LRW]
EOF

go run ./fetcher images -d test_deck.txt -o ./test_output
```

Expected: 5 images downloaded with correct filenames

#### Test 3: Invalid Cards Handling
```bash
cat > test_deck.txt << 'EOF'
Island [LRW]
NonexistentCard [ZZZ]
Mountain [LRW]
EOF

go run ./fetcher images -d test_deck.txt -o ./test_output
```

Expected output:
```
Warning: Card NonexistentCard from set ZZZ not found in database
Downloaded: Island [LRW]
Downloaded: Mountain [LRW]
Successfully downloaded images to ./test_output
```

#### Test 4: Custom Output Directory
```bash
go run ./fetcher images -d test_deck.txt -o ./my_cards
```

Expected: Directory `./my_cards` created with downloaded images

#### Test 5: Format Parameter
```bash
# PNG format (default behavior)
go run ./fetcher images -d test_deck.txt -o ./cards_png -f png

# JPG format (downloads best available)
go run ./fetcher images -d test_deck.txt -o ./cards_jpg -f jpg

# WebP format (downloads best available)
go run ./fetcher images -d test_deck.txt -o ./cards_webp -f webp
```

Expected: Images download successfully (Scryfall returns best available format)

#### Test 6: Decklist File Input
```bash
# Create a complex decklist
cat > modern_deck.txt << 'EOF'
4 Lightning Bolt [2XM]
4 Snapcaster Mage [2XM]
2 Spell Pierce [2XM]
3 Murktide [2XM]
2 Dress Down [SNC]
1 Dress Down [SNC]
EOF

go run ./fetcher images -d modern_deck.txt -o ./modern_images
```

Expected: All cards downloaded successfully

#### Test 7: Help Command
```bash
go run ./fetcher images --help
```

Expected output:
```
Download card printings from Scryfall.

Usage:
  fetcher images [flags]

Flags:
  -d, --decklist string   Decklist file
  -f, --format string     Output format (png, jpg, webp) (default "png")
  -h, --help              help for images
  -o, --output string     Output directory
```

## Error Scenarios

### Test 1: Missing Database
```bash
go run ./fetcher images -d test_deck.txt -o ./output --db-path /nonexistent/path
```

Expected: Error message about database not found

### Test 2: Network Error Simulation
Stop internet connection and run:
```bash
go run ./fetcher images -d test_deck.txt -o ./output
```

Expected: Warning for each failed card, but process completes

### Test 3: Missing Decklist File
```bash
go run ./fetcher images -d /nonexistent/file.txt -o ./output
```

Expected: Error message about file not found

### Test 4: Invalid Set Code
```bash
cat > test_deck.txt << 'EOF'
Island [INVALIDSET]
EOF

go run ./fetcher images -d test_deck.txt -o ./output
```

Expected:
```
Warning: Card Island from set INVALIDSET not found in database
Successfully downloaded images to ./output
```

## Performance Tests

### Benchmark Tests
```bash
go test -bench=. ./fetcher/internal/images/providers/
```

Results show:
- `BenchmarkSanitizeFilename`: ~5000+ ns/op
- `BenchmarkBuildScryfallImageURL`: ~300+ ns/op

### Large Decklist Test
```bash
# Create decklist with 100 unique cards
python3 << 'EOF'
# Get random 100 cards from database and write to file
import sqlite3
conn = sqlite3.connect('shared/resources/cards.db')
cursor = conn.cursor()
cursor.execute('SELECT DISTINCT c.name, c.setCode FROM cards c LIMIT 100')
with open('large_deck.txt', 'w') as f:
    for name, setCode in cursor.fetchall():
        f.write(f'{name} [{setCode}]\n')
EOF

time go run ./fetcher images -d large_deck.txt -o ./large_output
```

Monitor:
- Time to complete
- Memory usage
- Network requests (should be ~100)

## Validation Checklist

After testing, verify:

- [ ] All unit tests pass (`go test -v ./fetcher/...`)
- [ ] Integration tests pass (manual downloads work)
- [ ] Error handling works (invalid cards, network errors)
- [ ] Images are valid (can open in image viewer)
- [ ] Filenames are sanitized (no invalid characters)
- [ ] Database queries work (cards found correctly)
- [ ] Scryfall API integration works (correct headers, responses parsed)
- [ ] Output directory creation works
- [ ] Multiple cards download correctly
- [ ] Help/usage documentation is accessible

## Troubleshooting

### Issue: "Unknown driver sqlite3"
**Solution:** Database import is missing
```go
import _ "github.com/mattn/go-sqlite3"
```

### Issue: "API returned 400"
**Solution:** User-Agent or Accept headers missing
```go
req.Header.Set("User-Agent", "Turntide/1.0")
req.Header.Set("Accept", "application/json")
```

### Issue: Empty image files
**Solution:** Scryfall returned error. Check API response:
```bash
# Test API directly
curl -H "User-Agent: Turntide" \
     -H "Accept: application/json" \
     https://api.scryfall.com/cards/{scryfallID}
```

### Issue: Filename conflicts
**Solution:** UUID ensures uniqueness. Check for truncation:
```bash
# Verify UUID format: CardName_SetCode_UUID[:8].ext
ls -la card_images/ | head -5
```

## Files to Test

- `fetcher/internal/images/providers/scryfall.go` - Main provider
- `fetcher/cmd/images.go` - Command interface
- `fetcher/internal/parsers/turntide.go` - Decklist parser
- `fetcher/internal/images/providers/scryfall_test.go` - Unit tests

## CI/CD Integration

To run tests in CI/CD pipeline:

```bash
#!/bin/bash
set -e

echo "Running unit tests..."
go test -v -race -coverprofile=coverage.out ./fetcher/...

echo "Checking test coverage..."
go tool cover -func=coverage.out

echo "Running benchmarks..."
go test -bench=. ./fetcher/...

echo "All tests passed!"
```

## Real-World Test Decks

### Modern Format
```
4 Lightning Bolt [2XM]
4 Snapcaster Mage [2XM]
4 Murktide [2XM]
3 Teferi, Time Raveler [WAR]
```

### Standard Format
```
4 Fabled Passage [ZNR]
4 Omnath, Locus of Creation [ZNR]
```

### Commander Format
```
1 Muldrotha, the Gravetide [DAR]
1 Sol Ring [LEA]
```

## Success Criteria

✅ All unit tests pass
✅ Integration tests complete without errors
✅ Downloaded images are valid image files
✅ Filenames match pattern: `CardName_SetCode_UUID[:8].ext`
✅ Database queries retrieve correct Scryfall IDs
✅ Error messages are informative
✅ Help/usage is documented
✅ Performance is acceptable (<100ms per card)

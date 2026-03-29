# How to Test the Scryfall Image Provider

This document provides quick reference instructions for testing the Scryfall image provider implementation.

## Quick Start (1 minute)

```bash
cd /home/bfbraga/Documents/Programming/turntide

# Run all unit tests
go test -v ./fetcher/internal/images/providers/

# Run one integration test
go run ./fetcher images -d test/fixtures/basic_lands.txt -o test/output/test1

# Verify results
ls -lah test/output/test1/
file test/output/test1/*
```

## Testing Methods

### 1. Unit Tests (Automated)

**Run all unit tests:**
```bash
go test -v ./fetcher/internal/images/providers/
```

**Tests included:**
- `TestBuildScryfallImageURL` - URL generation
- `TestSanitizeFilename` - Filename sanitization  
- `TestGetImageURL` - Image URL selection
- `TestMustNewRequest` - HTTP header setup
- `TestQueryCardImages` - Database queries
- `TestCreateFilename` - Filename creation
- `TestScryfallDownload` - Full integration

**Expected output:**
```
PASS: TestBuildScryfallImageURL (0.00s)
PASS: TestSanitizeFilename (0.00s)
PASS: TestGetImageURL (0.00s)
PASS: TestMustNewRequest (0.00s)
PASS: TestQueryCardImages (0.00s)
PASS: TestScryfallDownload (0.11s)
PASS: TestCreateFilename (0.00s)
ok      github.com/bfibraga/turntide/fetcher/internal/images/providers  0.114s
```

### 2. Integration Tests (Manual)

**Test 1: Single Card**
```bash
# Create simple test
echo "Island [LRW]" > /tmp/test.txt

# Download
go run ./fetcher images -d /tmp/test.txt -o /tmp/test_output

# Verify
ls -lh /tmp/test_output/
# Should show: Island_LRW_bc9c4be7.jpg (~200KB)
```

**Test 2: Multiple Cards**
```bash
# Use provided fixture
go run ./fetcher images -d test/fixtures/basic_lands.txt -o test/output/basic

# Verify 5 images downloaded
ls test/output/basic/ | wc -l
# Output: 5
```

**Test 3: Invalid Cards Handling**
```bash
# Use fixture with mixed valid/invalid
go run ./fetcher images -d test/fixtures/mixed_valid_invalid.txt -o test/output/mixed

# Should show warnings for invalid cards
# Warning: Card InvalidCard123 from set ZZZ not found in database
# Warning: Card NonexistentCard from set FAKE not found in database
# Downloaded: Island [LRW]
# Downloaded: Mountain [LRW]
# Downloaded: Forest [LRW]
```

**Test 4: Different Formats**
```bash
# PNG (default)
go run ./fetcher images -d test/fixtures/basic_lands.txt -o test/output/png_test -f png

# JPG format
go run ./fetcher images -d test/fixtures/basic_lands.txt -o test/output/jpg_test -f jpg

# WebP format
go run ./fetcher images -d test/fixtures/basic_lands.txt -o test/output/webp_test -f webp

# All should download successfully
```

### 3. Test Fixtures (Pre-made Test Data)

Located in `test/fixtures/`:

```
basic_lands.txt         - 5 basic lands from LRW set
modern_deck.txt         - Cards from modern format
standard_deck.txt       - Cards from standard format
mixed_valid_invalid.txt - Mix of valid and invalid cards for error testing
large_deck.txt          - 10 cards for performance testing
```

Create new fixtures:
```bash
bash test/create_fixtures.sh
```

### 4. Code Quality Tests

```bash
# Format check
go fmt ./fetcher/...

# Lint check
go vet ./fetcher/...

# Build test
go build -o fetcher ./fetcher/

# Run all tests
go test ./fetcher/...
```

### 5. Coverage Analysis

```bash
# Generate coverage
go test -coverprofile=coverage.out ./fetcher/internal/images/providers/

# View summary
go tool cover -func=coverage.out

# View HTML report
go tool cover -html=coverage.out -o coverage.html
open coverage.html  # macOS
# or
firefox coverage.html  # Linux
```

**Current coverage:**
- Scryfall provider: 70% statement coverage
- Best covered: URL building (100%), filename sanitization (100%), image selection (100%)
- Room for improvement: Download image file handling (73.7%)

### 6. Performance Tests

**Benchmarks:**
```bash
go test -bench=. ./fetcher/internal/images/providers/

# Output:
# BenchmarkSanitizeFilename-8        2517744 ops     479.2 ns/op
# BenchmarkBuildScryfallImageURL-8  14091634 ops      88.62 ns/op
```

**Large decklist test:**
```bash
# Download 10 cards and time it
time go run ./fetcher images -d test/fixtures/large_deck.txt -o test/output/performance

# Should complete in <3 seconds for ~15 cards
```

## Test Files Created

```
fetcher/internal/images/providers/scryfall_test.go - 10 unit tests
test/fixtures/*.txt                                  - Test decklist files
test/run_tests.sh                                    - Automated test runner
test/create_fixtures.sh                              - Fixture creator
test/coverage.out                                    - Coverage data
TESTING.md                                           - Detailed test documentation
```

## Testing Checklist

Before considering the implementation complete, verify:

### Unit Tests
- [ ] `go test -v ./fetcher/internal/images/providers/` passes
- [ ] All 8 test functions pass
- [ ] No test failures or errors

### Integration Tests
- [ ] Single card download works
- [ ] Multiple card downloads work
- [ ] Invalid cards produce warnings (not errors)
- [ ] Help command works: `go run ./fetcher images --help`

### Image Validation
- [ ] Downloaded files are valid JPEGs
- [ ] File sizes are reasonable (~200KB per card)
- [ ] Filenames match pattern: `CardName_SetCode_UUID[:8].ext`

### Error Handling
- [ ] Missing database produces error message
- [ ] Invalid set codes are skipped with warning
- [ ] Network errors don't crash (with warnings)

### Code Quality
- [ ] `go fmt ./fetcher/...` passes (no formatting issues)
- [ ] `go vet ./fetcher/...` passes (no issues)
- [ ] `go build ./fetcher/` succeeds

### Coverage
- [ ] Coverage >= 70%
- [ ] Key functions have tests

## Running Tests in Different Environments

### Local Development
```bash
# Run everything quickly
go test -short ./fetcher/...

# With verbose output
go test -v ./fetcher/...
```

### CI/CD Pipeline
```bash
#!/bin/bash
go test -v -race -coverprofile=coverage.out ./fetcher/...
go tool cover -func=coverage.out
```

### Before Commit
```bash
go fmt ./fetcher/...
go vet ./fetcher/...
go test ./fetcher/...
go test -race ./fetcher/...
```

## Troubleshooting Tests

### Test says "unknown driver sqlite3"
**Solution:** SQLite driver import missing in provider
```go
import _ "github.com/mattn/go-sqlite3"
```

### Tests timeout
**Solution:** Increase timeout or use `-short` flag
```bash
go test -timeout 30s ./fetcher/...
go test -short ./fetcher/...
```

### Images won't download
**Solution 1:** Check Scryfall API headers
```bash
curl -H "User-Agent: Turntide" \
     -H "Accept: application/json" \
     https://api.scryfall.com/cards/{id}
```

**Solution 2:** Verify database path
```bash
ls -la shared/resources/cards.db
```

### Filenames have invalid characters
**Solution:** Verify sanitizeFilename() replaces special chars
```go
fmt.Println(sanitizeFilename("It That Betrays / The End?"))
// Output: It_That_Betrays___The_End_
```

## Example Test Session

```bash
$ cd /home/bfbraga/Documents/Programming/turntide

$ go test -v ./fetcher/internal/images/providers/
=== RUN   TestBuildScryfallImageURL
--- PASS: TestBuildScryfallImageURL (0.00s)
=== RUN   TestSanitizeFilename
--- PASS: TestSanitizeFilename (0.00s)
=== RUN   TestGetImageURL
--- PASS: TestGetImageURL (0.00s)
=== RUN   TestMustNewRequest
--- PASS: TestMustNewRequest (0.00s)
=== RUN   TestQueryCardImages
--- PASS: TestQueryCardImages (0.00s)
=== RUN   TestScryfallDownload
Downloaded: Island [LRW]
--- PASS: TestScryfallDownload (0.11s)
=== RUN   TestCreateFilename
--- PASS: TestCreateFilename (0.00s)
ok      github.com/bfibraga/turntide/fetcher/internal/images/providers  0.114s

$ go run ./fetcher images -d test/fixtures/basic_lands.txt -o test/output/demo
Downloaded: Island [LRW]
Downloaded: Mountain [LRW]
Downloaded: Forest [LRW]
Downloaded: Swamp [LRW]
Downloaded: Plains [LRW]
Successfully downloaded images to test/output/demo

$ ls -lah test/output/demo/
total 1.1M
drwxr-xr-x 2 user user 4.0K Mar 29 12:02 .
drwxr-xr-x 3 user user 4.0K Mar 29 12:02 ..
-rw-r--r-- 1 user user 207K Mar 29 12:02 Forest_LRW_625403b7.jpg
-rw-r--r-- 1 user user 192K Mar 29 12:02 Island_LRW_bc9c4be7.jpg
-rw-r--r-- 1 user user 206K Mar 29 12:02 Mountain_LRW_53700962.jpg
-rw-r--r-- 1 user user 195K Mar 29 12:02 Plains_LRW_a17c3246.jpg
-rw-r--r-- 1 user user 226K Mar 29 12:02 Swamp_LRW_b06f3c21.jpg

$ file test/output/demo/*
.../Forest_LRW_625403b7.jpg:   JPEG image data, JFIF, 672x936
.../Island_LRW_bc9c4be7.jpg:   JPEG image data, JFIF, 672x936
.../Mountain_LRW_53700962.jpg: JPEG image data, JFIF, 672x936
.../Plains_LRW_a17c3246.jpg:   JPEG image data, JFIF, 672x936
.../Swamp_LRW_b06f3c21.jpg:    JPEG image data, JFIF, 672x936

✓ All tests passed!
```

## Next Steps

After testing:
1. Review test coverage report
2. Fix any failing tests
3. Add tests for edge cases if coverage < 80%
4. Commit with test results in commit message
5. Create PR with test results

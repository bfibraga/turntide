#!/bin/bash
# Comprehensive test suite for Scryfall image provider

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_DIR"

echo "=========================================="
echo "Scryfall Image Provider - Test Suite"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
PASSED=0
FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "Running: $test_name... "
    if eval "$test_command" > /tmp/test_output.log 2>&1; then
        echo -e "${GREEN}PASS${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAIL${NC}"
        cat /tmp/test_output.log
        ((FAILED++))
    fi
}

echo "=========================================="
echo "1. Unit Tests"
echo "=========================================="
echo ""

run_test "Build URL" \
    "go test -run TestBuildScryfallImageURL -v ./fetcher/internal/images/providers/"

run_test "Sanitize Filename" \
    "go test -run TestSanitizeFilename -v ./fetcher/internal/images/providers/"

run_test "Get Image URL" \
    "go test -run TestGetImageURL -v ./fetcher/internal/images/providers/"

run_test "Create HTTP Request" \
    "go test -run TestMustNewRequest -v ./fetcher/internal/images/providers/"

run_test "Create Filename" \
    "go test -run TestCreateFilename -v ./fetcher/internal/images/providers/"

run_test "Query Card Images" \
    "go test -run TestQueryCardImages -v ./fetcher/internal/images/providers/"

echo ""
echo "=========================================="
echo "2. Integration Tests"
echo "=========================================="
echo ""

# Clean up output directory
rm -rf test/output/*

run_test "Single Card Download" \
    "go run ./fetcher images -d test/fixtures/basic_lands.txt -o test/output/single_card"

run_test "Modern Deck Download" \
    "go run ./fetcher images -d test/fixtures/modern_deck.txt -o test/output/modern"

run_test "Mixed Valid/Invalid Cards" \
    "go run ./fetcher images -d test/fixtures/mixed_valid_invalid.txt -o test/output/mixed"

echo ""
echo "=========================================="
echo "3. Validation Tests"
echo "=========================================="
echo ""

# Check if images were downloaded
SINGLE_CARD_COUNT=$(ls -1 test/output/single_card/ 2>/dev/null | wc -l)
if [ "$SINGLE_CARD_COUNT" -gt 0 ]; then
    echo -e "${GREEN}✓${NC} Single card test downloaded $SINGLE_CARD_COUNT images"
    ((PASSED++))
else
    echo -e "${RED}✗${NC} Single card test: No images downloaded"
    ((FAILED++))
fi

# Check image validity
if [ "$SINGLE_CARD_COUNT" -gt 0 ]; then
    FIRST_IMAGE=$(ls -1 test/output/single_card/ | head -1)
    FILE_TYPE=$(file "test/output/single_card/$FIRST_IMAGE" | grep -oE "(JPEG|PNG|WebP)" || echo "UNKNOWN")
    if [ "$FILE_TYPE" != "UNKNOWN" ]; then
        echo -e "${GREEN}✓${NC} Downloaded image is valid ($FILE_TYPE)"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Downloaded image is invalid"
        ((FAILED++))
    fi
fi

# Check filename format
if [ "$SINGLE_CARD_COUNT" -gt 0 ]; then
    FIRST_IMAGE=$(ls -1 test/output/single_card/ | head -1)
    if [[ "$FIRST_IMAGE" =~ ^[^_]+_[^_]+_[0-9a-f]{8}\.(jpg|png|webp)$ ]]; then
        echo -e "${GREEN}✓${NC} Filename format is correct: $FIRST_IMAGE"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} Filename format is incorrect: $FIRST_IMAGE"
        ((FAILED++))
    fi
fi

echo ""
echo "=========================================="
echo "4. Code Quality"
echo "=========================================="
echo ""

run_test "Go Format Check" \
    "go fmt ./fetcher/..."

run_test "Go Vet Check" \
    "go vet ./fetcher/..."

echo ""
echo "=========================================="
echo "5. Test Coverage"
echo "=========================================="
echo ""

echo "Generating coverage report..."
go test -coverprofile=test/coverage.out ./fetcher/... > /dev/null 2>&1
COVERAGE=$(go tool cover -func=test/coverage.out | grep total | awk '{print $3}')
echo "Total coverage: $COVERAGE"

echo ""
echo "=========================================="
echo "6. Benchmarks"
echo "=========================================="
echo ""

echo "Running benchmarks..."
go test -bench=. ./fetcher/internal/images/providers/ 2>&1 | grep "Benchmark"

echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo ""

TOTAL=$((PASSED + FAILED))
echo "Total Tests: $TOTAL"
echo -e "Passed: ${GREEN}$PASSED${NC}"
echo -e "Failed: ${RED}$FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}✗ Some tests failed${NC}"
    exit 1
fi

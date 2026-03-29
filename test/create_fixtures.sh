#!/bin/bash
# Test fixtures for Scryfall image provider

# Create test directories
mkdir -p test/fixtures
mkdir -p test/output

# Test Decklist 1: Basic lands
cat > test/fixtures/basic_lands.txt << 'EOF'
Island [LRW]
Mountain [LRW]
Forest [LRW]
Swamp [LRW]
Plains [LRW]
EOF

# Test Decklist 2: Modern format
cat > test/fixtures/modern_deck.txt << 'EOF'
4 Lightning Bolt [2XM]
4 Snapcaster Mage [2XM]
2 Murktide [2XM]
1 Ledger Shredder [SNC]
3 Subtlety [MH2]
2 Murktide [STA]
EOF

# Test Decklist 3: Standard format (recent)
cat > test/fixtures/standard_deck.txt << 'EOF'
4 Fabled Passage [M21]
4 Omnath, Locus of Creation [ZNR]
2 Uro, Titan of Nature's Wrath [THB]
3 Arboreal Grazer [WAR]
EOF

# Test Decklist 4: With invalid cards (should skip)
cat > test/fixtures/mixed_valid_invalid.txt << 'EOF'
Island [LRW]
InvalidCard123 [ZZZ]
Mountain [LRW]
NonexistentCard [FAKE]
Forest [LRW]
EOF

# Test Decklist 5: Large decklist for performance testing
cat > test/fixtures/large_deck.txt << 'EOF'
Island [LRW]
Mountain [LRW]
Forest [LRW]
Swamp [LRW]
Plains [LRW]
Island [M20]
Mountain [M20]
Forest [M20]
Swamp [M20]
Plains [M20]
EOF

echo "Test fixtures created in test/fixtures/"
ls -la test/fixtures/

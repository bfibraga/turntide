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
package models

import (
	"database/sql"
	"fmt"
	"time"

	"github.com/bfibraga/turntide/fetcher/internal/db"
)

// Card represents a card entity from the database
type Card struct {
	ID        int       `db:"id"`
	UUID      string    `db:"uuid"`
	Name      string    `db:"name"`
	SetCode   string    `db:"set_code"`
	CardType  string    `db:"card_type"`
	Rarity    string    `db:"rarity"`
	Cost      int       `db:"cost"`
	Power     int       `db:"power"`
	Toughness int       `db:"toughness"`
	Text      string    `db:"text"`
	ImageURL  string    `db:"image_url"`
	CreatedAt time.Time `db:"created_at"`
	UpdatedAt time.Time `db:"updated_at"`
}

// CardWithScryfallID represents a card with its Scryfall identifier
type CardWithScryfallID struct {
	UUID       string
	Name       string
	SetCode    string
	Number     string
	ScryfallID string
}

// CardFilter represents query filters for cards
type CardFilter struct {
	Name    *string
	SetCode *string
	Type    *string
	Rarity  *string
	Limit   int32
	Offset  int32
}

// Set represents a set entity from the database
type Set struct {
	Code        string `db:"code"`
	Name        string `db:"name"`
	Type        string `db:"type"`
	ReleaseDate string `db:"release_date"`
}

// ToCard converts a db.Card to a domain Card
func ToCard(dbCard db.Card) *Card {
	power := 0
	if dbCard.Power.Valid {
		fmt.Sscanf(dbCard.Power.String, "%d", &power)
	}

	toughness := 0
	if dbCard.Toughness.Valid {
		fmt.Sscanf(dbCard.Toughness.String, "%d", &toughness)
	}

	return &Card{
		UUID:      dbCard.Uuid.String,
		Name:      dbCard.Name.String,
		SetCode:   dbCard.Setcode.String,
		CardType:  dbCard.Type.String,
		Rarity:    dbCard.Rarity.String,
		Power:     power,
		Toughness: toughness,
		Text:      dbCard.Text.String,
		ImageURL:  dbCard.Artist.String,
	}
}

// ToCards converts a slice of db.Card to a slice of domain Cards
func ToCards(dbCards []db.Card) []*Card {
	cards := make([]*Card, 0, len(dbCards))
	for _, dbCard := range dbCards {
		cards = append(cards, ToCard(dbCard))
	}
	return cards
}

// ToCardWithScryfallID converts a GetCardByNameSetCodeAndNumberRow to CardWithScryfallID
func ToCardWithScryfallID(row db.GetCardByNameSetCodeAndNumberRow) *CardWithScryfallID {
	return &CardWithScryfallID{
		UUID:       row.Uuid.String,
		Name:       row.Name.String,
		SetCode:    row.Setcode.String,
		Number:     row.Number.String,
		ScryfallID: row.Scryfallid.String,
	}
}

// ToCardWithScryfallIDFromRow converts a GetCardByNameAndSetCodeRow to CardWithScryfallID
func ToCardWithScryfallIDFromRow(row db.GetCardByNameAndSetCodeRow) *CardWithScryfallID {
	return &CardWithScryfallID{
		UUID:       row.Uuid.String,
		Name:       row.Name.String,
		SetCode:    row.Setcode.String,
		Number:     row.Number.String,
		ScryfallID: row.Scryfallid.String,
	}
}

// ToSet converts a db.Set to a domain Set
func ToSet(dbSet db.Set) *Set {
	return &Set{
		Code:        dbSet.Code.String,
		Name:        dbSet.Name.String,
		Type:        dbSet.Type.String,
		ReleaseDate: dbSet.Releasedate.String,
	}
}

// ToSets converts a slice of db.Set to a slice of domain Sets
func ToSets(dbSets []db.Set) []*Set {
	sets := make([]*Set, 0, len(dbSets))
	for _, dbSet := range dbSets {
		sets = append(sets, ToSet(dbSet))
	}
	return sets
}

// ToNullString converts a string pointer to sql.NullString
func ToNullString(s *string) sql.NullString {
	if s == nil {
		return sql.NullString{Valid: false}
	}
	return sql.NullString{String: *s, Valid: true}
}

// ToNullFloat64 converts a float64 to sql.NullFloat64
func ToNullFloat64(f float64) sql.NullFloat64 {
	return sql.NullFloat64{Float64: f, Valid: f != 0}
}

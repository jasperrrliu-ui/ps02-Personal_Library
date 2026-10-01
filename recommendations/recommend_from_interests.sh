#!/bin/bash
# Recommend library-external books by matching interests.txt against genre and themes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATABASE="$SCRIPT_DIR/../data/book_database.sh"
METADATA="$SCRIPT_DIR/../data/book_metadata.csv"
INTERESTS="$SCRIPT_DIR/../data/interests.txt"
LIBRARY_FILE="$(mktemp)"
trap 'rm -f "$LIBRARY_FILE"' EXIT

bash "$DATABASE" list > "$LIBRARY_FILE"

awk -F',' -v interest_file="$INTERESTS" '
    NR == FNR {
        library[tolower($1 SUBSEP $2)] = 1
        next
    }
    FILENAME == interest_file {
        interest = tolower($0)
        if (interest != "") interests[interest] = 1
        next
    }
    FNR == 1 { next }
    {
        key = tolower($1 SUBSEP $2)
        if (key in library) next

        searchable = tolower($3 " " $5)
        score = 0
        matches = ""
        for (interest in interests) {
            if (index(searchable, interest) > 0) {
                score++
                matches = matches (matches == "" ? "" : "; ") interest
            }
        }
        if (score > 0) print score "|" $1 "|" $2 "|" $3 "|interests|Matches: " matches
    }
' "$LIBRARY_FILE" "$INTERESTS" "$METADATA" \
    | sort -t'|' -k1,1nr -k2,2 \
    | cut -d'|' -f2- \
    | head -n 3

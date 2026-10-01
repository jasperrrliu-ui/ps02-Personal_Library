#!/bin/bash
# Recommend library-external books using finished books only.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATABASE="$SCRIPT_DIR/../data/book_database.sh"
METADATA="$SCRIPT_DIR/../data/book_metadata.csv"
LIBRARY_FILE="$(mktemp)"
trap 'rm -f "$LIBRARY_FILE"' EXIT

bash "$DATABASE" list > "$LIBRARY_FILE"

awk -F',' '
    NR == FNR {
        library[tolower($1 SUBSEP $2)] = 1
        if ($5 == "finished") {
            authors[tolower($2)]++
            genres[tolower($3)]++
        }
        next
    }
    FNR == 1 { next }
    {
        key = tolower($1 SUBSEP $2)
        if (key in library) next

        score = 0
        reason = ""
        if (tolower($2) in authors) {
            score += 100 + authors[tolower($2)]
            reason = "Same author as a book you finished"
        }
        if (tolower($3) in genres) {
            score += genres[tolower($3)]
            if (reason == "") reason = "Genre you have finished"
        }
        if (score > 0) print score "|" $1 "|" $2 "|" $3 "|history|" reason
    }
' "$LIBRARY_FILE" "$METADATA" \
    | sort -t'|' -k1,1nr -k2,2 \
    | cut -d'|' -f2- \
    | head -n 3

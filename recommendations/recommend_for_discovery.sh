#!/bin/bash
# Recommend books outside genres already finished, for deliberate exploration.

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
        if ($5 == "finished") finished_genres[tolower($3)] = 1
        next
    }
    FNR == 1 { next }
    {
        key = tolower($1 SUBSEP $2)
        if (key in library) next
        if (tolower($3) in finished_genres) next
        print $1 "|" $2 "|" $3 "|discovery|Outside your finished genres"
    }
' "$LIBRARY_FILE" "$METADATA" | shuf -n 3

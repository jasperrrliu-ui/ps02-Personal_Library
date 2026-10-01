#!/bin/bash
# Refine combined recommendation candidates received through stdin.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATABASE="$SCRIPT_DIR/../data/book_database.sh"
LIBRARY_FILE="$(mktemp)"
trap 'rm -f "$LIBRARY_FILE"' EXIT

bash "$DATABASE" list > "$LIBRARY_FILE"

awk -F'|' '
    NR == FNR {
        library[tolower($1 SUBSEP $2)] = 1
        next
    }
    NF >= 5 {
        key = tolower($1 SUBSEP $2)
        source_key = $4 SUBSEP key
        if (key in library || source_key in seen_for_source) next

        seen_for_source[source_key] = 1
        count++
        title[count] = $1
        author[count] = $2
        genre[count] = $3
        source[count] = $4
        reason[count] = $5
    }
    END {
        source_order[1] = "history"
        source_order[2] = "interests"
        source_order[3] = "discovery"
        quota["history"] = 2
        quota["interests"] = 2
        quota["discovery"] = 1

        for (s = 1; s <= 3; s++) {
            current_source = source_order[s]
            selected_for_source = 0
            for (i = 1; i <= count && selected_for_source < quota[current_source]; i++) {
                key = tolower(title[i] SUBSEP author[i])
                if (source[i] == current_source && !(key in selected_key)) {
                    print title[i] "|" author[i] "|" genre[i] "|" source[i] "|" reason[i]
                    selected_key[key] = 1
                    selected_for_source++
                    total++
                }
            }
        }

        for (i = 1; i <= count && total < 5; i++) {
            key = tolower(title[i] SUBSEP author[i])
            if (!(key in selected_key)) {
                print title[i] "|" author[i] "|" genre[i] "|" source[i] "|" reason[i]
                selected_key[key] = 1
                total++
            }
        }
    }
' "$LIBRARY_FILE" -

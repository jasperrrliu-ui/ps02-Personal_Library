#!/bin/bash
# Look up local metadata by title. Author is used only to resolve duplicate titles.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METADATA_FILE="$SCRIPT_DIR/../data/book_metadata.csv"
title="${1:-}"
author="${2:-}"

[[ -n "$title" ]] || {
    echo "Usage: fetch_book_metadata.sh TITLE [AUTHOR]" >&2
    exit 1
}

[[ -f "$METADATA_FILE" ]] || {
    echo "Error: metadata catalog not found" >&2
    exit 1
}

record="$(awk -F',' -v t="$title" -v a="$author" '
    NR > 1 && tolower($1) == tolower(t) {
        if (a == "" || tolower($2) == tolower(a)) {
            record = $0
            count++
        }
    }
    END {
        if (count == 1) {
            print record
            exit 0
        }
        if (count == 0) exit 2
        exit 3
    }
' "$METADATA_FILE")" || status=$?

case "${status:-0}" in
    0)
        IFS=',' read -r found_title found_author genre year themes <<< "$record"
        printf '%s|%s|%s|%s\n' "$found_title" "$found_author" "$genre" "$year"
        ;;
    2)
        echo "Error: metadata not found for $title" >&2
        exit 2
        ;;
    3)
        echo "Error: multiple metadata records share the title $title; provide the author" >&2
        exit 3
        ;;
esac

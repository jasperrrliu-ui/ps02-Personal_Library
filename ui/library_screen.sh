#!/bin/bash
# UI layer: collect library input and display workflow results.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANAGE_LIBRARY="$SCRIPT_DIR/../workflows/manage_library.sh"

show_books() {
    awk -F',' '
        BEGIN { printf "%-34s %-25s %-24s %-13s %s\n", "TITLE", "AUTHOR", "GENRE", "STATUS", "RATING" }
        { printf "%-34s %-25s %-24s %-13s %s\n", $1, $2, $3, $5, $6 }
    '
}

pause() {
    gum input --placeholder "Press Enter to return to the menu" >/dev/null
}

action="${1:-}"

case "$action" in
    browse)
        echo "Your library"
        bash "$MANAGE_LIBRARY" browse | show_books
        pause
        ;;
    search)
        query="$(gum input --placeholder "Search title, author, genre, or year" | tr -d '\r')"
        if [[ -z "$query" ]]; then
            echo "Search cancelled: enter a search term."
        else
            echo "Search results"
            bash "$MANAGE_LIBRARY" search "$query" | show_books
        fi
        pause
        ;;
    add)
        title="$(gum input --placeholder "Title" | tr -d '\r')"
        author="$(gum input --placeholder "Author (optional)" | tr -d '\r')"
        genre="$(gum input --placeholder "Genre (optional if in metadata)" | tr -d '\r')"
        year="$(gum input --placeholder "Year (optional if in metadata)" | tr -d '\r')"
        status="$(gum choose want_to_read reading finished)"
        rating="$(gum input --placeholder "Rating 1-5 (optional)" | tr -d '\r')"
        link="$(gum input --placeholder "Link (optional)" | tr -d '\r')"

        if bash "$MANAGE_LIBRARY" add "$title" "$author" "$genre" "$year" "$status" "$rating" "$link"; then
            echo "Book added."
        fi
        pause
        ;;
    update-status)
        title="$(gum input --placeholder "Title" | tr -d '\r')"
        author="$(gum input --placeholder "Author (optional; only needed for duplicate titles)" | tr -d '\r')"
        status="$(gum choose want_to_read reading finished)"

        if bash "$MANAGE_LIBRARY" update-status "$title" "$author" "$status"; then
            echo "Reading status updated."
        fi
        pause
        ;;
    update-rating)
        title="$(gum input --placeholder "Title" | tr -d '\r')"
        author="$(gum input --placeholder "Author (optional; only needed for duplicate titles)" | tr -d '\r')"
        rating="$(gum input --placeholder "Rating 1-5, or leave blank to clear" | tr -d '\r')"

        if bash "$MANAGE_LIBRARY" update-rating "$title" "$author" "$rating"; then
            echo "Rating updated."
        fi
        pause
        ;;
    *)
        echo "Error: unknown library action: $action" >&2
        exit 1
        ;;
esac

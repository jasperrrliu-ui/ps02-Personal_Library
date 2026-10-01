#!/bin/bash

# Coordinate library operations. This file does not read books.csv directly.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATABASE_SCRIPT="$SCRIPT_DIR/../data/book_database.sh"
SEARCH_SCRIPT="$SCRIPT_DIR/../books/search_books.sh"
METADATA_SCRIPT="$SCRIPT_DIR/../books/fetch_book_metadata.sh"

usage() {
    cat <<'EOF'
Usage:
  manage_library.sh browse
  manage_library.sh search QUERY
  manage_library.sh add TITLE [AUTHOR] [GENRE] [YEAR] [STATUS] [RATING] [LINK]
  manage_library.sh update-status TITLE [AUTHOR] STATUS
  manage_library.sh update-rating TITLE [AUTHOR] RATING
EOF
}

fail() {
    echo "Error: $*" >&2
    exit 1
}

browse_library() {
    bash "$DATABASE_SCRIPT" list
}

search_library() {
    [[ -n "${1:-}" ]] || fail "search query is required"
    bash "$SEARCH_SCRIPT" "$1"
}

add_to_library() {
    local title="${1:-}"
    local author="${2:-}"
    local genre="${3:-}"
    local year="${4:-}"
    local status="${5:-want_to_read}"
    local rating="${6:-}"
    local link="${7:-}"
    local metadata

    [[ -n "$title" ]] || fail "title is required"

    # A unique title in the local catalog supplies canonical metadata.
    if metadata="$(bash "$METADATA_SCRIPT" "$title" 2>/dev/null)"; then
        IFS='|' read -r metadata_title metadata_author metadata_genre metadata_year <<< "$metadata"
        title="$metadata_title"
        author="$metadata_author"
        [[ -n "$genre" ]] || genre="$metadata_genre"
        [[ -n "$year" ]] || year="$metadata_year"
    else
        author="${author:-Unknown}"
        [[ -n "$genre" ]] || genre="Unknown"
    fi

    bash "$DATABASE_SCRIPT" add \
        "$title" "$author" "$genre" "$year" "$status" "$rating" "$link"
}

resolve_author() {
    local title="$1"
    local record
    local lookup_status

    if record="$(bash "$DATABASE_SCRIPT" find-title "$title")"; then
        IFS=',' read -r _ author _ <<< "$record"
        printf '%s\n' "$author"
    else
        lookup_status=$?
        if [[ "$lookup_status" -eq 3 ]]; then
            fail "multiple library books share the title $title; provide the author"
        fi
        fail "book not found: $title"
    fi
}

update_status() {
    [[ $# -eq 3 ]] || fail "update-status requires TITLE AUTHOR STATUS"
    local title="$1"
    local author="$2"
    local status="$3"

    [[ -n "$author" ]] || author="$(resolve_author "$title")"
    bash "$DATABASE_SCRIPT" update-status "$title" "$author" "$status"
}

update_rating() {
    [[ $# -eq 3 ]] || fail "update-rating requires TITLE AUTHOR RATING"
    local title="$1"
    local author="$2"
    local rating="$3"

    [[ -n "$author" ]] || author="$(resolve_author "$title")"
    bash "$DATABASE_SCRIPT" update-rating "$title" "$author" "$rating"
}

command="${1:-}"
shift || true

case "$command" in
    browse)
        browse_library
        ;;
    search)
        search_library "$@"
        ;;
    add)
        add_to_library "$@"
        ;;
    update-status)
        update_status "$@"
        ;;
    update-rating)
        update_rating "$@"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac

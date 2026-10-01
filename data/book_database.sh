#!/bin/bash

# The only application component that reads from or writes to books.csv.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_FILE="$SCRIPT_DIR/books.csv"

usage() {
    cat <<'EOF'
Usage:
  book_database.sh list
  book_database.sh search QUERY
  book_database.sh find-title TITLE
  book_database.sh exists TITLE AUTHOR
  book_database.sh add TITLE AUTHOR GENRE YEAR STATUS RATING LINK
  book_database.sh update-status TITLE AUTHOR STATUS
  book_database.sh update-rating TITLE AUTHOR RATING
EOF
}

fail() {
    echo "Error: $*" >&2
    exit 1
}

[[ -f "$DB_FILE" ]] || fail "database file not found: $DB_FILE"

valid_status() {
    case "$1" in
        want_to_read|reading|finished) return 0 ;;
        *) return 1 ;;
    esac
}

valid_rating() {
    [[ -z "$1" || "$1" =~ ^[1-5]$ ]]
}

check_no_commas() {
    local value
    for value in "$@"; do
        [[ "$value" != *,* ]] || fail "fields cannot contain commas in this CSV version"
    done
}

list_books() {
    tail -n +2 "$DB_FILE"
}

search_books() {
    local query="$1"
    [[ -n "$query" ]] || fail "search query is required"

    awk -F',' -v q="$(printf '%s' "$query" | tr '[:upper:]' '[:lower:]')" '
        BEGIN { OFS = "," }
        NR > 1 {
            for (i = 1; i <= 7; i++) {
                value = $i
                gsub(/[[:upper:]]/, "", value)
                if (index(tolower($i), q) > 0) {
                    print
                    next
                }
            }
        }
    ' "$DB_FILE"
}

find_by_title() {
    local title="$1"

    [[ -n "$title" ]] || fail "title is required"

    awk -F',' -v t="$title" '
        NR > 1 && tolower($1) == tolower(t) {
            record = $0
            count++
        }
        END {
            if (count == 1) {
                print record
                exit 0
            }
            if (count == 0) exit 2
            exit 3
        }
    ' "$DB_FILE"
}

book_exists() {
    local title="$1"
    local author="$2"

    awk -F',' -v t="$title" -v a="$author" '
        NR > 1 && tolower($1) == tolower(t) && tolower($2) == tolower(a) {
            found = 1
        }
        END { exit(found ? 0 : 1) }
    ' "$DB_FILE"
}

add_book() {
    local title="${1:-}"
    local author="${2:-Unknown}"
    local genre="${3:-Unknown}"
    local year="${4:-}"
    local status="${5:-want_to_read}"
    local rating="${6:-}"
    local link="${7:-}"

    [[ -n "$title" ]] || fail "title is required"
    [[ -n "$author" ]] || author="Unknown"
    [[ -n "$genre" ]] || genre="Unknown"
    valid_status "$status" || fail "invalid status: $status"
    valid_rating "$rating" || fail "rating must be empty or a number from 1 to 5"
    [[ -z "$year" || "$year" =~ ^-?[0-9]+$ ]] || fail "year must be an integer"
    check_no_commas "$title" "$author" "$genre" "$year" "$status" "$rating" "$link"

    if book_exists "$title" "$author"; then
        fail "book already exists: $title by $author"
    fi

    printf '%s,%s,%s,%s,%s,%s,%s\n' \
        "$title" "$author" "$genre" "$year" "$status" "$rating" "$link" >> "$DB_FILE"
}

update_field() {
    local title="$1"
    local author="$2"
    local field_number="$3"
    local new_value="$4"
    local temp_file

    check_no_commas "$new_value"
    temp_file="$(mktemp "${DB_FILE}.tmp.XXXXXX")" || fail "could not create temporary file"

    if ! awk -F',' -v OFS=',' \
        -v t="$title" -v a="$author" \
        -v field="$field_number" -v value="$new_value" '
        NR == 1 { print; next }
        tolower($1) == tolower(t) && tolower($2) == tolower(a) {
            $field = value
            found = 1
        }
        { print }
        END { if (!found) exit 2 }
    ' "$DB_FILE" > "$temp_file"; then
        rm -f "$temp_file"
        fail "book not found: $title by $author"
    fi

    mv "$temp_file" "$DB_FILE" || fail "could not update database file"
}

update_status() {
    local title="$1"
    local author="$2"
    local status="$3"

    valid_status "$status" || fail "invalid status: $status"
    update_field "$title" "$author" 5 "$status"
}

update_rating() {
    local title="$1"
    local author="$2"
    local rating="$3"

    valid_rating "$rating" || fail "rating must be empty or a number from 1 to 5"
    update_field "$title" "$author" 6 "$rating"
}

command="${1:-}"
shift || true

case "$command" in
    list)
        list_books
        ;;
    search)
        search_books "${1:-}"
        ;;
    find-title)
        [[ $# -eq 1 ]] || fail "find-title requires TITLE"
        find_by_title "$1"
        ;;
    exists)
        [[ $# -eq 2 ]] || fail "exists requires TITLE and AUTHOR"
        book_exists "$1" "$2"
        ;;
    add)
        add_book "${1:-}" "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}" "${7:-}"
        ;;
    update-status)
        [[ $# -eq 3 ]] || fail "update-status requires TITLE AUTHOR STATUS"
        update_status "$1" "$2" "$3"
        ;;
    update-rating)
        [[ $# -eq 3 ]] || fail "update-rating requires TITLE AUTHOR RATING"
        update_rating "$1" "$2" "$3"
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        usage >&2
        exit 1
        ;;
esac

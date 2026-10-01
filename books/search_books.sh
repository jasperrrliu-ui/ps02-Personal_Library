#!/bin/bash

# Search the user's library through the data layer.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATABASE_SCRIPT="$SCRIPT_DIR/../data/book_database.sh"

if [[ $# -gt 0 ]]; then
    query="$*"
else
    read -r query || query=""
fi

if [[ -z "$query" ]]; then
    echo "Error: search query is required" >&2
    exit 1
fi

exec bash "$DATABASE_SCRIPT" search "$query"

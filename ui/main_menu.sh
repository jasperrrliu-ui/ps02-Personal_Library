#!/bin/bash
# UI layer: show the main menu and return one stable action token.

set -euo pipefail

echo "Personal Book Manager" >&2

selection="$(gum choose \
    "Browse Library" \
    "Add Book" \
    "Search Library" \
    "Update Reading Status" \
    "Update Rating" \
    "Get Recommendations" \
    "Quit")"

case "$selection" in
    "Browse Library") echo "browse" ;;
    "Add Book") echo "add" ;;
    "Search Library") echo "search" ;;
    "Update Reading Status") echo "update-status" ;;
    "Update Rating") echo "update-rating" ;;
    "Get Recommendations") echo "recommendations" ;;
    "Quit"|"") echo "quit" ;;
esac

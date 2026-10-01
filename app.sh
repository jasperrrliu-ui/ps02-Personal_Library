#!/bin/bash
# Application entry point. It routes menu choices to UI screens.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MENU="$SCRIPT_DIR/ui/main_menu.sh"
LIBRARY_SCREEN="$SCRIPT_DIR/ui/library_screen.sh"
RECOMMENDATIONS_SCREEN="$SCRIPT_DIR/ui/recommendations_screen.sh"

if ! command -v gum >/dev/null 2>&1; then
    echo "Error: Gum is required. Install it before running this app." >&2
    exit 1
fi

while true; do
    choice="$(bash "$MENU")"

    case "$choice" in
        browse|add|search|update-status|update-rating)
            bash "$LIBRARY_SCREEN" "$choice"
            ;;
        recommendations)
            bash "$RECOMMENDATIONS_SCREEN"
            ;;
        quit|"")
            echo "Goodbye."
            exit 0
            ;;
    esac
done

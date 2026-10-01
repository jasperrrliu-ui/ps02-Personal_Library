#!/bin/bash
# UI layer: show recommendation progress and format the final shortlist.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW="$SCRIPT_DIR/../workflows/get_recommendations.sh"

echo "Generating recommendations"

bash "$WORKFLOW" | awk -F'|' '
    BEGIN { print ""; print "FINAL SHORTLIST" }
    {
        printf "\n%s\n  %s - %s\n  %s\n  %s\n", NR ". " $1, $2, $3, $4, $5
    }
'

gum input --placeholder "Press Enter to return to the menu" >/dev/null

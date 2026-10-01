#!/bin/bash
# Run three recommendation agents in parallel and refine their combined output.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RECOMMENDATIONS_DIR="$SCRIPT_DIR/../recommendations"
TEMP_DIR="$(mktemp -d)"
trap 'rm -f "$TEMP_DIR/history.txt" "$TEMP_DIR/interests.txt" "$TEMP_DIR/discovery.txt"; rmdir "$TEMP_DIR" 2>/dev/null || true' EXIT

echo "History agent: running" >&2
bash "$RECOMMENDATIONS_DIR/recommend_from_history.sh" > "$TEMP_DIR/history.txt" &
history_pid=$!

echo "Interest agent: running" >&2
bash "$RECOMMENDATIONS_DIR/recommend_from_interests.sh" > "$TEMP_DIR/interests.txt" &
interests_pid=$!

echo "Discovery agent: running" >&2
bash "$RECOMMENDATIONS_DIR/recommend_for_discovery.sh" > "$TEMP_DIR/discovery.txt" &
discovery_pid=$!

wait "$history_pid"
echo "History agent: done" >&2

wait "$interests_pid"
echo "Interest agent: done" >&2

wait "$discovery_pid"
echo "Discovery agent: done" >&2

cat "$TEMP_DIR/history.txt" "$TEMP_DIR/interests.txt" "$TEMP_DIR/discovery.txt" \
    | bash "$RECOMMENDATIONS_DIR/refine_recommendations.sh"

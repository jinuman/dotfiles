#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title fd open
# @raycast.mode compact
# @raycast.packageName Files
# @raycast.icon 🧭
# @raycast.argument1 { "type": "text", "placeholder": "Filename" }
# @raycast.argument2 { "type": "text", "placeholder": "Search Root", "optional": true }

set -euo pipefail

QUERY="$1"
ROOT="${2:-$HOME}"

# fd 로 숨김파일 포함해서 검색
RESULTS="$(fd -HI "$QUERY" "$ROOT" 2>/dev/null || true)"
FIRST="$(printf "%s\n" "$RESULTS" | head -n1)"

if [[ -z "${FIRST:-}" ]]; then
  echo "No match: $QUERY"
  exit 1
fi

open -a "Visual Studio Code" "$FIRST"
echo "Opened: $FIRST"
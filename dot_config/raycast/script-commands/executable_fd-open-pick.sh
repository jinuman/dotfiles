#!/bin/bash
# @raycast.schemaVersion 1
# @raycast.title fd open pick
# @raycast.mode compact
# @raycast.packageName Files
# @raycast.icon 🧭
# @raycast.argument1 { "type": "text", "placeholder": "Filename" }
# @raycast.argument2 { "type": "text", "placeholder": "Search Root", "optional": true }

set -euo pipefail

QUERY="$1"
ROOT="${2:-$HOME}"

# fd로 숨김/무시파일 포함해 검색 (최대 50개)
RESULTS="$(fd -HI -- "$QUERY" "$ROOT" 2>/dev/null | head -n 50 || true)"
if [ -z "${RESULTS}" ]; then
  echo "No match: $QUERY"
  exit 1
fi

# 선택창 (AppleScript). 취소 시 빈 문자열 반환
ESCAPED="$(printf "%s" "$RESULTS" | sed 's/\\/\\\\/g; s/"/\\"/g')"
SELECTION=$(/usr/bin/osascript <<EOF || true
set theList to paragraphs of "$ESCAPED"
set theChoice to choose from list theList with prompt "Select a file (up to 50):" default items item 1 of theList without multiple selections allowed
if theChoice is false then
  return ""
else
  return item 1 of theChoice as text
end if
EOF
)

if [ -z "${SELECTION}" ]; then
  echo "Cancelled."
  exit 0
fi

# VSCode로 열기 (원하면 open 으로 바꿔도 됨)
open -a "Visual Studio Code" "$SELECTION"
echo "Opened: $SELECTION"

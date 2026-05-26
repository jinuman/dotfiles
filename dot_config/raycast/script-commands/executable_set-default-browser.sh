#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Set Default Browser
# @raycast.mode silent
# @raycast.packageName Browser
#
# Optional parameters:
# @raycast.icon 🌐
# @raycast.argument1 { "type": "dropdown", "placeholder": "Choose browser", "data": [ { "title": "Safari", "value": "safari" }, { "title": "Chrome", "value": "chrome" } ] }
#
# Documentation:
# @raycast.description Set macOS default browser to Safari or Chrome using defaultbrowser CLI.

set -euo pipefail

CHOICE="${1:-}"

if [[ -z "$CHOICE" ]]; then
  echo "No browser selected."
  exit 1
fi

# Ensure CLI exists (Raycast runs non-interactive shell)
if ! command -v defaultbrowser >/dev/null 2>&1; then
  echo "defaultbrowser not found. Install with: brew install defaultbrowser"
  exit 1
fi

defaultbrowser "$CHOICE"

echo "Default browser set to: $CHOICE"

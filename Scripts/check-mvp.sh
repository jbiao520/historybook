#!/bin/bash
# Validate the source corpus, then validate the exact resources in the app.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
swift test
"$ROOT/Scripts/assemble-app.sh"
HISTORYBOOK_CONTENT_ROOT="$ROOT/.build/Historybook.app/Contents/Resources/Content" swift test

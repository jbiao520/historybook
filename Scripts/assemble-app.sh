#!/bin/bash
# Assemble a standalone, locally signed app; default to an optimized build.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIGURATION="${HISTORYBOOK_CONFIGURATION:-release}"
if [[ "$CONFIGURATION" != "debug" && "$CONFIGURATION" != "release" ]]; then
  echo "HISTORYBOOK_CONFIGURATION must be debug or release" >&2
  exit 1
fi
swift build -c "$CONFIGURATION"
BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
APP="$ROOT/.build/Historybook.app"
STAGE="$(mktemp -d "$ROOT/.build/Historybook-stage.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
STAGED_APP="$STAGE/Historybook.app"

mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"

cp "$BIN_DIR/Historybook" "$STAGED_APP/Contents/MacOS/Historybook"
chmod +x "$STAGED_APP/Contents/MacOS/Historybook"
cp "$ROOT/Packaging/Info.plist" "$STAGED_APP/Contents/Info.plist"

RESOURCE_BUNDLE="$BIN_DIR/Historybook_Historybook.bundle"
if [[ -d "$RESOURCE_BUNDLE/Contents/Resources/Content" ]]; then
  CONTENT="$RESOURCE_BUNDLE/Contents/Resources/Content"
elif [[ -d "$RESOURCE_BUNDLE/Content" ]]; then
  CONTENT="$RESOURCE_BUNDLE/Content"
else
  echo "The build has no bundled Content directory" >&2
  exit 1
fi
cp -R "$CONTENT" "$STAGED_APP/Contents/Resources/Content"

test -f "$STAGED_APP/Contents/Resources/Content/home.json"
test -f "$STAGED_APP/Contents/Resources/Content/styles/article.css"
plutil -lint "$STAGED_APP/Contents/Info.plist"
codesign --force --sign - "$STAGED_APP"
codesign --verify --strict "$STAGED_APP"

rm -rf "$APP"
mv "$STAGED_APP" "$APP"

echo "$APP"

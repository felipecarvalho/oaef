#!/usr/bin/env bash
# ==============================================================================
# Open Agentic Engineering Framework (OAEF) - Clean ZIP Export Bundler
# Author & Creator: Felipe Carvalho
# License: Apache License 2.0
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
VERSION="$(cat "$SCRIPT_DIR/VERSION" 2>/dev/null || echo "1.0.0")"
ZIP_NAME="oaef-v$VERSION.zip"
TARGET_ZIP="$PARENT_DIR/$ZIP_NAME"

echo "🧹 Cleaning repository of temporary and OS files..."
find "$SCRIPT_DIR" -name ".DS_Store" -type f -delete 2>/dev/null || true
find "$SCRIPT_DIR" -name "*~" -type f -delete 2>/dev/null || true
find "$SCRIPT_DIR" -name ".Spotlight-V100" -type d -exec rm -rf {} + 2>/dev/null || true
find "$SCRIPT_DIR" -name ".Trashes" -type d -exec rm -rf {} + 2>/dev/null || true

echo "📦 Bundling OAEF v$VERSION into: $TARGET_ZIP"
rm -f "$TARGET_ZIP"

cd "$PARENT_DIR"
zip -r -q "$ZIP_NAME" "oaef" -x "oaef/.git/*" "*/.git/*" "*.DS_Store*" "*node_modules*" "*build/*" "*.dart_tool/*"

echo "🔐 Generating SHA-256 Checksum..."
if command -v shasum >/dev/null 2>&1; then
  SHASUM_OUTPUT=$(shasum -a 256 "$TARGET_ZIP")
  echo "$SHASUM_OUTPUT" > "$PARENT_DIR/$ZIP_NAME.sha256"
  echo "   SHA-256: $(echo "$SHASUM_OUTPUT" | awk '{print $1}')"
elif command -v sha256sum >/dev/null 2>&1; then
  SHASUM_OUTPUT=$(sha256sum "$TARGET_ZIP")
  echo "$SHASUM_OUTPUT" > "$PARENT_DIR/$ZIP_NAME.sha256"
  echo "   SHA-256: $(echo "$SHASUM_OUTPUT" | awk '{print $1}')"
fi

echo ""
echo "✅ Export complete!"
echo "   Archive: $TARGET_ZIP"
echo "   Size:    $(du -h "$TARGET_ZIP" | awk '{print $1}')"
echo "   Ready to share, publish, or unpack into any system."

#!/usr/bin/env bash
set -euo pipefail

# Extract Nexus 5X (bullhead) vendor blobs and apply Android 15 blob_fixups
# Usage: ./scripts/extract_blobs.sh /path/to/dumbos-15

ROM_DIR="${1:-$(pwd)}"
BLOB_COMMIT="3bce2e142f622a354ae248214e31b6b4424fdfef"

if [[ ! -d "$ROM_DIR/vendor/lge/bullhead/.git" ]]; then
  echo "[ERROR] vendor/lge/bullhead not found in $ROM_DIR"
  exit 1
fi

TMP_BLOBS="$(mktemp -d)"
trap 'rm -rf "$TMP_BLOBS"' EXIT

echo "=== Resetting vendor/lge/bullhead before clean extraction ==="
git -C "$ROM_DIR/vendor/lge/bullhead" checkout -- .

echo "=== Extracting proprietary blobs from $BLOB_COMMIT ==="
git -C "$ROM_DIR/vendor/lge/bullhead" archive "$BLOB_COMMIT" proprietary | tar -x -C "$TMP_BLOBS"

# extract_utils expects system/ subdir when vendor/ exists at root of dump dir
mkdir -p "$TMP_BLOBS/proprietary/system"
for d in app bin etc framework lib lib64 priv-app; do
  if [[ -d "$TMP_BLOBS/proprietary/$d" && ! -e "$TMP_BLOBS/proprietary/system/$d" ]]; then
    ln -s "../$d" "$TMP_BLOBS/proprietary/system/$d"
  fi
done

echo "=== Running device/lge/bullhead/extract-files.py ==="
(cd "$ROM_DIR/device/lge/bullhead" && ./extract-files.py "$TMP_BLOBS/proprietary")

if [[ ! -f "$ROM_DIR/vendor/lge/bullhead/bullhead-vendor.mk" ]]; then
  echo "[ERROR] bullhead-vendor.mk was not generated! Extraction failed."
  exit 1
fi

echo "=== Vendor blobs extracted and fixed for Android 15 ==="

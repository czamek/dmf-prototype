#!/usr/bin/env bash
# Fetch a pinned MXL SDK release into vendor/mxl.
set -euo pipefail

MXL_VERSION="${MXL_VERSION:-v1.1.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/vendor/mxl"

if [ -d "$DEST/.git" ]; then
  echo "MXL already present in $DEST ($(git -C "$DEST" describe --tags 2>/dev/null || echo unknown))"
  exit 0
fi

mkdir -p "$ROOT/vendor"
git clone --depth 1 --branch "$MXL_VERSION" https://github.com/dmf-mxl/mxl.git "$DEST"
echo "MXL $MXL_VERSION is in $DEST"

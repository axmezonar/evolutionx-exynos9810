#!/usr/bin/env bash
set -euo pipefail

ANDROID_TOP="${1:-${ANDROID_BUILD_TOP:-$PWD}}"
if ! ANDROID_TOP="$(cd "$ANDROID_TOP" 2>/dev/null && pwd)"; then
  echo "ERROR: Android source directory does not exist: $ANDROID_TOP" >&2
  exit 1
fi
if [[ ! -f "$ANDROID_TOP/build/envsetup.sh" ]]; then
  echo "ERROR: $ANDROID_TOP is not an Android source root (missing build/envsetup.sh)." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/prepare-device-trees.sh" "$ANDROID_TOP"
cd "$ANDROID_TOP"
source build/envsetup.sh
lunch evolution_starlte-userdebug
mka bacon -j"${BUILD_JOBS:-4}"

echo
echo "Build finished. Inspect out/target/product/starlte/ for the generated ROM package."

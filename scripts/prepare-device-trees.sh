#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [ANDROID_SOURCE_ROOT]" >&2
  echo "Adds the Evolution X Android 17 lunch choices for Galaxy S9 (starlte / SM-G960F)." >&2
}

ANDROID_TOP="${1:-${ANDROID_BUILD_TOP:-$PWD}}"
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then usage; exit 0; fi

if ! ANDROID_TOP="$(cd "$ANDROID_TOP" 2>/dev/null && pwd)"; then
  echo "ERROR: Android source directory does not exist: $ANDROID_TOP" >&2
  exit 1
fi
if [[ ! -f "$ANDROID_TOP/build/envsetup.sh" ]]; then
  echo "ERROR: $ANDROID_TOP is not an Android source root (missing build/envsetup.sh)." >&2
  exit 1
fi

DEVICE_DIR="$ANDROID_TOP/device/samsung/starlte"
PRODUCT_MK="$DEVICE_DIR/lineage_starlte.mk"
PRODUCTS_MK="$DEVICE_DIR/AndroidProducts.mk"
if [[ ! -f "$DEVICE_DIR/device.mk" || ! -f "$PRODUCT_MK" || ! -f "$PRODUCTS_MK" ]]; then
  echo "ERROR: starlte device tree is incomplete under $DEVICE_DIR." >&2
  exit 1
fi

if ! grep -Fq 'PRODUCT_NAME := lineage_starlte' "$PRODUCT_MK"; then
  echo "ERROR: expected the upstream S9 product PRODUCT_NAME := lineage_starlte." >&2
  exit 1
fi
if ! grep -Fq 'vendor/lineage/config/common_full_phone.mk' "$PRODUCT_MK"; then
  echo "ERROR: starlte product does not inherit the Evolution X vendor/lineage common phone config." >&2
  exit 1
fi

# The upstream cnb product remains lineage_starlte; cp2a is the Android 17 release code.
if ! grep -Fq 'lineage_starlte-cp2a-userdebug' "$PRODUCTS_MK"; then
  cat >> "$PRODUCTS_MK" <<'EOF'

# Evolution X Android 17 (cnb / cp2a) build variants
COMMON_LUNCH_CHOICES += \
    lineage_starlte-cp2a-user \
    lineage_starlte-cp2a-userdebug
EOF
fi

echo "Prepared Evolution X product: lineage_starlte-cp2a-userdebug (SM-G960F)"
echo "Build with: cd \"$ANDROID_TOP\" && source build/envsetup.sh && lunch lineage_starlte-cp2a-userdebug && m evolution"

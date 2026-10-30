#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [ANDROID_SOURCE_ROOT]" >&2
  echo "Installs the Evolution X product definition for Galaxy S9 (starlte / SM-G960F)." >&2
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
if [[ ! -f "$DEVICE_DIR/device.mk" || ! -f "$DEVICE_DIR/lineage_starlte.mk" ]]; then
  echo "ERROR: starlte device tree is not synced under $DEVICE_DIR." >&2
  exit 1
fi

cat > "$DEVICE_DIR/evolution_starlte.mk" <<'EOF'
# Evolution X product definition for Samsung Galaxy S9 (Exynos)
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/product_launched_with_o.mk)
$(call inherit-product, device/samsung/starlte/device.mk)
$(call inherit-product, vendor/evolution/config/common_full_phone.mk)

PRODUCT_NAME := evolution_starlte
PRODUCT_DEVICE := starlte
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-G960F
PRODUCT_MANUFACTURER := samsung
PRODUCT_GMS_CLIENTID_BASE := android-samsung
EOF

# Retain the upstream Lineage lunch target while adding an Evolution X product.
if ! grep -Fq '$(LOCAL_DIR)/evolution_starlte.mk' "$DEVICE_DIR/AndroidProducts.mk"; then
  cat >> "$DEVICE_DIR/AndroidProducts.mk" <<'EOF'

PRODUCT_MAKEFILES += \
    $(LOCAL_DIR)/evolution_starlte.mk

COMMON_LUNCH_CHOICES += \
    evolution_starlte-user \
    evolution_starlte-userdebug \
    evolution_starlte-eng
EOF
fi

echo "Prepared Evolution X product: evolution_starlte (SM-G960F)"
echo "Next: cd \"$ANDROID_TOP\" && source build/envsetup.sh && lunch evolution_starlte-userdebug"

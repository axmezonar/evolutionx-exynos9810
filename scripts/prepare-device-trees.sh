#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

declare -A models=(
  [crownlte]="SM-N960F"
  [starlte]="SM-G960F"
  [star2lte]="SM-G965F"
)

for device in crownlte starlte star2lte; do
  dir="$ROOT/device/samsung/$device"
  [[ -d "$dir" ]] || { echo "Missing synced tree: $dir" >&2; exit 1; }

  cat > "$dir/evolution_\${device}.mk" <<EOF
# Evolution X product definition for \${device}
\$(call inherit-product, \$(SRC_TARGET_DIR)/product/core_64_bit.mk)
\$(call inherit-product, \$(SRC_TARGET_DIR)/product/full_base_telephony.mk)
\$(call inherit-product, device/samsung/\${device}/device.mk)
\$(call inherit-product, vendor/evolution/config/common_full_phone.mk)

PRODUCT_NAME := evolution_\${device}
PRODUCT_DEVICE := \${device}
PRODUCT_BRAND := samsung
PRODUCT_MODEL := ${models[$device]}
PRODUCT_MANUFACTURER := samsung
PRODUCT_GMS_CLIENTID_BASE := android-samsung
EOF

  cat > "$dir/AndroidProducts.mk" <<EOF
PRODUCT_MAKEFILES := \\
    \$(LOCAL_DIR)/evolution_\${device}.mk

COMMON_LUNCH_CHOICES := \\
    evolution_\${device}-user \\
    evolution_\${device}-userdebug \\
    evolution_\${device}-eng
EOF
done

echo "Evolution X product definitions installed for crownlte, starlte and star2lte."

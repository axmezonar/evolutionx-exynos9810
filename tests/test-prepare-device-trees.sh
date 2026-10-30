#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT
mkdir -p "$TMP_ROOT/build" "$TMP_ROOT/device/samsung/starlte"
: > "$TMP_ROOT/build/envsetup.sh"
cat > "$TMP_ROOT/device/samsung/starlte/device.mk" <<'EOF'
# fake tree for script validation
EOF
cat > "$TMP_ROOT/device/samsung/starlte/lineage_starlte.mk" <<'EOF'
# fake tree for script validation
EOF
cat > "$TMP_ROOT/device/samsung/starlte/AndroidProducts.mk" <<'EOF'
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/lineage_starlte.mk

COMMON_LUNCH_CHOICES := \
    lineage_starlte-userdebug
EOF

bash -n "$REPO_ROOT/scripts/prepare-device-trees.sh"
bash -n "$REPO_ROOT/scripts/build-starlte.sh"
bash "$REPO_ROOT/scripts/prepare-device-trees.sh" "$TMP_ROOT"
bash "$REPO_ROOT/scripts/prepare-device-trees.sh" "$TMP_ROOT"

grep -Fq '$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)' "$TMP_ROOT/device/samsung/starlte/evolution_starlte.mk"
grep -Fq 'PRODUCT_MODEL := SM-G960F' "$TMP_ROOT/device/samsung/starlte/evolution_starlte.mk"
grep -Fq '$(LOCAL_DIR)/evolution_starlte.mk' "$TMP_ROOT/device/samsung/starlte/AndroidProducts.mk"
test "$(grep -Fc '$(LOCAL_DIR)/evolution_starlte.mk' "$TMP_ROOT/device/samsung/starlte/AndroidProducts.mk")" -eq 1
grep -Fq 'lineage_starlte.mk' "$TMP_ROOT/device/samsung/starlte/AndroidProducts.mk"
echo "S9 product preparation tests passed."

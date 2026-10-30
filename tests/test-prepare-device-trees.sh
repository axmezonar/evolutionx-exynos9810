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
PRODUCT_NAME := lineage_starlte
PRODUCT_DEVICE := starlte
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
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

grep -Fq 'PRODUCT_NAME := lineage_starlte' "$TMP_ROOT/device/samsung/starlte/lineage_starlte.mk"
grep -Fq '$(call inherit-product, vendor/lineage/config/common_full_phone.mk)' "$TMP_ROOT/device/samsung/starlte/lineage_starlte.mk"
grep -Fq 'lineage_starlte-cp2a-user' "$TMP_ROOT/device/samsung/starlte/AndroidProducts.mk"
grep -Fq 'lineage_starlte-cp2a-userdebug' "$TMP_ROOT/device/samsung/starlte/AndroidProducts.mk"
test "$(grep -Fc 'lineage_starlte-cp2a-userdebug' "$TMP_ROOT/device/samsung/starlte/AndroidProducts.mk")" -eq 1
test ! -e "$TMP_ROOT/device/samsung/starlte/evolution_starlte.mk"
grep -Fq 'lineage_starlte-cp2a-userdebug' "$REPO_ROOT/scripts/build-starlte.sh"
grep -Fq 'm -j"${BUILD_JOBS:-4}" evolution' "$REPO_ROOT/scripts/build-starlte.sh"
echo "S9 cnb/cp2a product preparation tests passed."

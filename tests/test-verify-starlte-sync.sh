#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  mkdir -p "$TMP_ROOT/$(dirname "$path")"
  : > "$TMP_ROOT/$path"
done <<'EOF'
build/envsetup.sh
device/samsung/starlte/BoardConfig.mk
device/samsung/starlte/device.mk
device/samsung/starlte/lineage_starlte.mk
device/samsung/exynos9810-common/BoardConfigCommon.mk
device/samsung/exynos9810-common/common.mk
kernel/samsung/exynos9810/Makefile
kernel/samsung/exynos9810/arch/arm64/boot/Makefile
kernel/samsung/exynos9810/arch/arm64/configs/exynos9810-starlte_defconfig
kernel/samsung/exynos9810/scripts/samsung_bootimg.py
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-gcc
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ld
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-objcopy
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ar
vendor/samsung/starlte/BoardConfigVendor.mk
vendor/samsung/starlte/starlte-vendor.mk
vendor/samsung/exynos9810-common/BoardConfigVendor.mk
vendor/samsung/exynos9810-common/exynos9810-common-vendor.mk
vendor/lineage/config/common_full_phone.mk
vendor/lineage/config/common_mobile_full.mk
hardware/samsung/Android.bp
hardware/samsung_slsi-linaro/config/BoardConfig9810.mk
hardware/samsung_slsi-linaro/config/config.mk
hardware/samsung_slsi-linaro/exynos/Android.bp
hardware/samsung_slsi-linaro/exynos/gralloc/gralloc3
hardware/samsung_slsi-linaro/exynos/libaudio/audiohal
hardware/samsung_slsi-linaro/graphics/Android.bp
hardware/samsung_slsi-linaro/graphics/exynos9810
hardware/samsung_slsi-linaro/interfaces/Android.bp
hardware/samsung_slsi-linaro/openmax/Android.bp
hardware/lineage/generic-ims/ims.mk
device/samsung_slsi/sepolicy/sepolicy.mk
device/lineage/sepolicy/exynos/sepolicy.mk
device/lineage/sepolicy/libion/sepolicy.mk
EOF

chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-gcc"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ld"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-objcopy"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ar"
chmod +x "$TMP_ROOT/kernel/samsung/exynos9810/scripts/samsung_bootimg.py"

bash -n "$REPO_ROOT/scripts/verify-starlte-sync.sh"
bash "$REPO_ROOT/scripts/verify-starlte-sync.sh" "$TMP_ROOT"

chmod -x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-gcc"
if bash "$REPO_ROOT/scripts/verify-starlte-sync.sh" "$TMP_ROOT"; then
  echo "ERROR: preflight passed with a non-executable GCC toolchain." >&2
  exit 1
fi
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-gcc"
chmod -x "$TMP_ROOT/kernel/samsung/exynos9810/scripts/samsung_bootimg.py"
if bash "$REPO_ROOT/scripts/verify-starlte-sync.sh" "$TMP_ROOT"; then
  echo "ERROR: preflight passed with a non-executable Samsung boot packer." >&2
  exit 1
fi
chmod +x "$TMP_ROOT/kernel/samsung/exynos9810/scripts/samsung_bootimg.py"
rm "$TMP_ROOT/hardware/samsung_slsi-linaro/openmax/Android.bp"
if bash "$REPO_ROOT/scripts/verify-starlte-sync.sh" "$TMP_ROOT"; then
  echo "ERROR: preflight passed despite a missing required dependency." >&2
  exit 1
fi
echo "S9 sync preflight tests passed."

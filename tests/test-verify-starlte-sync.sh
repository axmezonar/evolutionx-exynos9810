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
kernel/samsung/exynos9810/arch/arm64/Makefile
kernel/samsung/exynos9810/arch/arm64/boot/dts/Makefile
kernel/samsung/exynos9810/arch/arm64/boot/Makefile
kernel/samsung/exynos9810/arch/arm64/configs/exynos9810-starlte_defconfig
kernel/samsung/exynos9810/scripts/samsung_bootimg.py
prebuilts/clang/kernel/linux-x86/clang-r416183b/bin/clang
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-ld
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-objcopy
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-as
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-nm
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-objdump
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-strip
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-ranlib
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-readelf
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-size
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-ar
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

chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-ld"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-objcopy"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-as"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-nm"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-objdump"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-strip"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-ranlib"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-readelf"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-size"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-androidkernel-4.9/bin/aarch64-linux-androidkernel-ar"
chmod +x "$TMP_ROOT/prebuilts/clang/kernel/linux-x86/clang-r416183b/bin/clang"
chmod +x "$TMP_ROOT/kernel/samsung/exynos9810/scripts/samsung_bootimg.py"
printf 'CONFIG_DTS_9810_STAR=y\n' > "$TMP_ROOT/kernel/samsung/exynos9810/arch/arm64/configs/exynos9810-starlte_defconfig"
printf 'Image.samsung: vmlinux scripts dtbs\n' > "$TMP_ROOT/kernel/samsung/exynos9810/arch/arm64/Makefile"
cat > "$TMP_ROOT/kernel/samsung/exynos9810/arch/arm64/boot/Makefile" <<'EOF'
$(obj)/Image.samsung: $(obj)/Image $(obj)/dt.img $(samsung_bootimg) FORCE
$(call if_changed,samsung_bundle)
EOF
printf 'dtb-$(CONFIG_DTS_9810_STAR) += exynos/exynos9810-starlte_eur_open_26.dtb\n' > "$TMP_ROOT/kernel/samsung/exynos9810/arch/arm64/boot/dts/Makefile"
cat > "$TMP_ROOT/device/samsung/exynos9810-common/BoardConfigCommon.mk" <<'EOF'
TARGET_KERNEL_SOURCE := kernel/samsung/exynos9810
BOARD_KERNEL_IMAGE_NAME := Image.samsung
BOARD_KERNEL_PAGESIZE := 2048
BOARD_CUSTOM_MKBOOTIMG := $(TARGET_KERNEL_SOURCE)/scripts/samsung_bootimg.py
TARGET_KERNEL_ADDITIONAL_FLAGS += SAMSUNG_BOOT_PAGESIZE=$(BOARD_KERNEL_PAGESIZE)
BOARD_MKBOOTIMG_ARGS := --header_version 0 \
    --kernel_offset $(BOARD_KERNEL_OFFSET) \
    --ramdisk_offset $(BOARD_KERNEL_RAMDISK_OFFSET) \
    --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
EOF

bash -n "$REPO_ROOT/scripts/verify-starlte-sync.sh"
bash "$REPO_ROOT/scripts/verify-starlte-sync.sh" "$TMP_ROOT"

chmod -x "$TMP_ROOT/prebuilts/clang/kernel/linux-x86/clang-r416183b/bin/clang"
if bash "$REPO_ROOT/scripts/verify-starlte-sync.sh" "$TMP_ROOT"; then
  echo "ERROR: preflight passed with a non-executable Clang compiler." >&2
  exit 1
fi
chmod +x "$TMP_ROOT/prebuilts/clang/kernel/linux-x86/clang-r416183b/bin/clang"
chmod -x "$TMP_ROOT/kernel/samsung/exynos9810/scripts/samsung_bootimg.py"
if bash "$REPO_ROOT/scripts/verify-starlte-sync.sh" "$TMP_ROOT"; then
  echo "ERROR: preflight passed with a non-executable Samsung boot packer." >&2
  exit 1
fi
chmod +x "$TMP_ROOT/kernel/samsung/exynos9810/scripts/samsung_bootimg.py"
cp "$TMP_ROOT/kernel/samsung/exynos9810/arch/arm64/configs/exynos9810-starlte_defconfig" "$TMP_ROOT/starlte_defconfig.bak"
printf 'CONFIG_DTS_9810_STAR2=y\n' > "$TMP_ROOT/kernel/samsung/exynos9810/arch/arm64/configs/exynos9810-starlte_defconfig"
if bash "$REPO_ROOT/scripts/verify-starlte-sync.sh" "$TMP_ROOT"; then
  echo "ERROR: preflight passed with the S9+ DTB selected instead of the S9 DTB." >&2
  exit 1
fi
mv "$TMP_ROOT/starlte_defconfig.bak" "$TMP_ROOT/kernel/samsung/exynos9810/arch/arm64/configs/exynos9810-starlte_defconfig"
cp "$TMP_ROOT/device/samsung/exynos9810-common/BoardConfigCommon.mk" "$TMP_ROOT/BoardConfigCommon.mk.bak"
printf 'TARGET_PREBUILT_KERNEL := prebuilt/Image\n' >> "$TMP_ROOT/device/samsung/exynos9810-common/BoardConfigCommon.mk"
if bash "$REPO_ROOT/scripts/verify-starlte-sync.sh" "$TMP_ROOT"; then
  echo "ERROR: preflight passed with a conflicting prebuilt-kernel override." >&2
  exit 1
fi
mv "$TMP_ROOT/BoardConfigCommon.mk.bak" "$TMP_ROOT/device/samsung/exynos9810-common/BoardConfigCommon.mk"
rm "$TMP_ROOT/hardware/samsung_slsi-linaro/openmax/Android.bp"
if bash "$REPO_ROOT/scripts/verify-starlte-sync.sh" "$TMP_ROOT"; then
  echo "ERROR: preflight passed despite a missing required dependency." >&2
  exit 1
fi
echo "S9 sync preflight tests passed."

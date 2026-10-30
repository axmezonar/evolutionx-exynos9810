#!/usr/bin/env bash
set -euo pipefail

ANDROID_TOP="${1:-${ANDROID_BUILD_TOP:-$PWD}}"
if ! ANDROID_TOP="$(cd "$ANDROID_TOP" 2>/dev/null && pwd)"; then
  echo "ERROR: Android source directory does not exist: $ANDROID_TOP" >&2
  exit 1
fi

required_paths=(
  "build/envsetup.sh"
  "device/samsung/starlte/BoardConfig.mk"
  "device/samsung/starlte/device.mk"
  "device/samsung/starlte/lineage_starlte.mk"
  "device/samsung/exynos9810-common/BoardConfigCommon.mk"
  "device/samsung/exynos9810-common/common.mk"
  "kernel/samsung/exynos9810/Makefile"
  "kernel/samsung/exynos9810/arch/arm64/Makefile"
  "kernel/samsung/exynos9810/arch/arm64/boot/dts/Makefile"
  "kernel/samsung/exynos9810/arch/arm64/boot/Makefile"
  "kernel/samsung/exynos9810/arch/arm64/configs/exynos9810-starlte_defconfig"
  "kernel/samsung/exynos9810/scripts/samsung_bootimg.py"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-gcc"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ld"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-objcopy"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-as"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-nm"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-objdump"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-strip"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ar"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ranlib"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-readelf"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-size"
  "vendor/samsung/starlte/BoardConfigVendor.mk"
  "vendor/samsung/starlte/starlte-vendor.mk"
  "vendor/samsung/exynos9810-common/BoardConfigVendor.mk"
  "vendor/samsung/exynos9810-common/exynos9810-common-vendor.mk"
  "vendor/lineage/config/common_full_phone.mk"
  "vendor/lineage/config/common_mobile_full.mk"
  "hardware/samsung/Android.bp"
  "hardware/samsung_slsi-linaro/config/BoardConfig9810.mk"
  "hardware/samsung_slsi-linaro/config/config.mk"
  "hardware/samsung_slsi-linaro/exynos/Android.bp"
  "hardware/samsung_slsi-linaro/exynos/gralloc/gralloc3"
  "hardware/samsung_slsi-linaro/exynos/libaudio/audiohal"
  "hardware/samsung_slsi-linaro/graphics/Android.bp"
  "hardware/samsung_slsi-linaro/graphics/exynos9810"
  "hardware/samsung_slsi-linaro/interfaces/Android.bp"
  "hardware/samsung_slsi-linaro/openmax/Android.bp"
  "hardware/lineage/generic-ims/ims.mk"
  "device/samsung_slsi/sepolicy/sepolicy.mk"
  "device/lineage/sepolicy/exynos/sepolicy.mk"
  "device/lineage/sepolicy/libion/sepolicy.mk"
)

missing=()
for path in "${required_paths[@]}"; do
  if [[ ! -e "$ANDROID_TOP/$path" ]]; then
    missing+=("$path")
  fi
done

if (( ${#missing[@]} > 0 )); then
  echo "ERROR: S9 source checkout is incomplete. Missing paths:" >&2
  printf "  - %s\n" "${missing[@]}" >&2
  echo "Run repo sync again and check local_manifests/exynos9810.xml." >&2
  exit 1
fi

required_executables=(
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-gcc"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ld"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-objcopy"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-as"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-nm"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-objdump"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-strip"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ar"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ranlib"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-readelf"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-size"
  "kernel/samsung/exynos9810/scripts/samsung_bootimg.py"
)

missing_executables=()
for path in "${required_executables[@]}"; do
  if [[ ! -x "$ANDROID_TOP/$path" ]]; then
    missing_executables+=("$path")
  fi
done

if (( ${#missing_executables[@]} > 0 )); then
  echo "ERROR: S9 kernel toolchain or Samsung boot packer is incomplete or not executable:" >&2
  printf "  - %s\n" "${missing_executables[@]}" >&2
  echo "Run repo sync again and check the kernel toolchain projects in local_manifests/exynos9810.xml." >&2
  exit 1
fi

KERNEL_DEFCONFIG="$ANDROID_TOP/kernel/samsung/exynos9810/arch/arm64/configs/exynos9810-starlte_defconfig"
KERNEL_ARCH_MAKE="$ANDROID_TOP/kernel/samsung/exynos9810/arch/arm64/Makefile"
KERNEL_BOOT_MAKE="$ANDROID_TOP/kernel/samsung/exynos9810/arch/arm64/boot/Makefile"
KERNEL_DTS_MAKE="$ANDROID_TOP/kernel/samsung/exynos9810/arch/arm64/boot/dts/Makefile"

if ! grep -Fqx 'CONFIG_DTS_9810_STAR=y' "$KERNEL_DEFCONFIG"; then
  echo "ERROR: S9 defconfig does not enable CONFIG_DTS_9810_STAR." >&2
  exit 1
fi
for wrong_device in CONFIG_DTS_9810_STAR2 CONFIG_DTS_9810_CROWN; do
  if grep -Eq "^${wrong_device}=y$" "$KERNEL_DEFCONFIG"; then
    echo "ERROR: S9 defconfig unexpectedly enables another Exynos 9810 device: $wrong_device." >&2
    exit 1
  fi
done
if ! grep -Fqx 'Image.samsung: vmlinux scripts dtbs' "$KERNEL_ARCH_MAKE"; then
  echo "ERROR: kernel top-level ARM64 Makefile does not expose the required Image.samsung target with DTB dependencies." >&2
  exit 1
fi
if ! grep -Fqx '$(obj)/Image.samsung: $(obj)/Image $(obj)/dt.img $(samsung_bootimg) FORCE' "$KERNEL_BOOT_MAKE" || ! grep -Fqx '$(call if_changed,samsung_bundle)' "$KERNEL_BOOT_MAKE"; then
  echo "ERROR: Samsung Image.samsung packaging rule is missing from arch/arm64/boot/Makefile." >&2
  exit 1
fi
if ! grep -Fqx 'dtb-$(CONFIG_DTS_9810_STAR) += exynos/exynos9810-starlte_eur_open_26.dtb' "$KERNEL_DTS_MAKE"; then
  echo "ERROR: Exynos 9810 DTS Makefile does not map the S9 config to the starlte DTB." >&2
  exit 1
fi

COMMON_BOARD_CONFIG="$ANDROID_TOP/device/samsung/exynos9810-common/BoardConfigCommon.mk"
required_boot_settings=(
  'TARGET_KERNEL_SOURCE := kernel/samsung/exynos9810'
  'BOARD_KERNEL_IMAGE_NAME := Image.samsung'
  'BOARD_CUSTOM_MKBOOTIMG := $(TARGET_KERNEL_SOURCE)/scripts/samsung_bootimg.py'
  'TARGET_KERNEL_ADDITIONAL_FLAGS += SAMSUNG_BOOT_PAGESIZE=$(BOARD_KERNEL_PAGESIZE)'
)
for setting in "${required_boot_settings[@]}"; do
  if ! grep -Fqx "$setting" "$COMMON_BOARD_CONFIG"; then
    echo "ERROR: S9 boot configuration is missing the required setting: $setting" >&2
    exit 1
  fi
done
if ! grep -Fq 'BOARD_MKBOOTIMG_ARGS := --header_version 0' "$COMMON_BOARD_CONFIG"; then
  echo "ERROR: S9 boot configuration must use legacy Samsung boot header version 0." >&2
  exit 1
fi
for boot_arg in '--kernel_offset $(BOARD_KERNEL_OFFSET)' '--ramdisk_offset $(BOARD_KERNEL_RAMDISK_OFFSET)' '--tags_offset $(BOARD_KERNEL_TAGS_OFFSET)'; do
  if ! grep -Fq -- "$boot_arg" "$COMMON_BOARD_CONFIG"; then
    echo "ERROR: S9 boot configuration is missing Samsung mkbootimg argument: $boot_arg" >&2
    exit 1
  fi
done

for forbidden in BOARD_CUSTOM_BOOTIMG BOARD_CUSTOM_BOOTIMG_MK BOARD_KERNEL_SEPARATED_DT TARGET_CUSTOM_DTBTOOL TARGET_PREBUILT_KERNEL; do
  if grep -Eq "^[[:space:]]*${forbidden}[[:space:]]*([:+?]?=)" "$COMMON_BOARD_CONFIG"; then
    echo "ERROR: obsolete or conflicting kernel/boot setting is present: $forbidden" >&2
    exit 1
  fi
done

echo "S9 source preflight passed: device tree, Samsung boot packer, kernel defconfig, GCC 4.9 kernel toolchain, vendor blobs, hardware and sepolicy dependencies are present."

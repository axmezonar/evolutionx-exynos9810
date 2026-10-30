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
  "kernel/samsung/exynos9810/arch/arm64/configs/exynos9810-starlte_defconfig"
  "prebuilts/clang/kernel/linux-x86/clang-r416183b/bin/clang"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-ld"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-objcopy"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-ar"
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
  "prebuilts/clang/kernel/linux-x86/clang-r416183b/bin/clang"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-ld"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-objcopy"
  "prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-androidkernel-ar"
)

missing_executables=()
for path in "${required_executables[@]}"; do
  if [[ ! -x "$ANDROID_TOP/$path" ]]; then
    missing_executables+=("$path")
  fi
done

if (( ${#missing_executables[@]} > 0 )); then
  echo "ERROR: S9 kernel toolchain is incomplete or not executable:" >&2
  printf "  - %s\\n" "${missing_executables[@]}" >&2
  echo "Run repo sync again and check the kernel toolchain projects in local_manifests/exynos9810.xml." >&2
  exit 1
fi

echo "S9 source preflight passed: device tree, Samsung boot packer, kernel defconfig, Clang/GCC toolchains, vendor blobs, hardware and sepolicy dependencies are present."

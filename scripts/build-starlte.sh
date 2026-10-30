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
bash "$SCRIPT_DIR/verify-starlte-sync.sh" "$ANDROID_TOP"
bash "$SCRIPT_DIR/prepare-device-trees.sh" "$ANDROID_TOP"

BUILD_JOBS="${BUILD_JOBS:-4}"
KERNEL_JOBS="${KERNEL_JOBS:-$BUILD_JOBS}"
for setting in BUILD_JOBS KERNEL_JOBS; do
  value="${!setting}"
  if [[ ! "$value" =~ ^[1-9][0-9]*$ ]]; then
    echo "ERROR: $setting must be a positive integer (got: $value)." >&2
    exit 1
  fi
done

cd "$ANDROID_TOP"
source build/envsetup.sh
lunch lineage_starlte-cp2a-userdebug

# This Android 17 build tree has no legacy kernel.mk target for this 4.9
# device kernel. Build Samsung's Image.samsung container explicitly, then
# stage it where Android's boot-image rules expect the kernel payload.
KERNEL_DIR="$ANDROID_TOP/kernel/samsung/exynos9810"
DEVICE_BOARD_CONFIG="$ANDROID_TOP/device/samsung/starlte/BoardConfig.mk"
COMMON_BOARD_CONFIG="$ANDROID_TOP/device/samsung/exynos9810-common/BoardConfigCommon.mk"
KERNEL_DEFCONFIG="$(awk '$1 == "TARGET_KERNEL_CONFIG" && $2 == ":=" { print $3; exit }' "$DEVICE_BOARD_CONFIG")"
KERNEL_IMAGE_NAME="$(awk '$1 == "BOARD_KERNEL_IMAGE_NAME" && $2 == ":=" { print $3; exit }' "$COMMON_BOARD_CONFIG")"
KERNEL_PAGE_SIZE="$(awk '$1 == "BOARD_KERNEL_PAGESIZE" && $2 == ":=" { print $3; exit }' "$COMMON_BOARD_CONFIG")"

if [[ "$KERNEL_DEFCONFIG" != "exynos9810-starlte_defconfig" ]]; then
  echo "ERROR: unexpected S9 kernel defconfig: ${KERNEL_DEFCONFIG:-<empty>}" >&2
  exit 1
fi
if [[ "$KERNEL_IMAGE_NAME" != "Image.samsung" ]]; then
  echo "ERROR: expected BOARD_KERNEL_IMAGE_NAME := Image.samsung (got: ${KERNEL_IMAGE_NAME:-<empty>})." >&2
  exit 1
fi
if [[ ! "$KERNEL_PAGE_SIZE" =~ ^[1-9][0-9]*$ ]]; then
  echo "ERROR: could not read a valid BOARD_KERNEL_PAGESIZE from $COMMON_BOARD_CONFIG." >&2
  exit 1
fi

PRODUCT_OUT="$(get_build_var PRODUCT_OUT)"
if [[ -z "$PRODUCT_OUT" ]]; then
  echo "ERROR: Android build did not return PRODUCT_OUT after lunch." >&2
  exit 1
fi
if [[ "$PRODUCT_OUT" != /* ]]; then
  PRODUCT_OUT="$ANDROID_TOP/$PRODUCT_OUT"
fi

CLANG_BIN="$ANDROID_TOP/prebuilts/clang/kernel/linux-x86/clang-r416183b/bin"
GCC_BIN="$ANDROID_TOP/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin"
CLANG="$CLANG_BIN/clang"
KERNEL_OUT="${KERNEL_OUT:-$PRODUCT_OUT/obj/KERNEL_OBJ}"
if [[ "$KERNEL_OUT" != /* ]]; then
  KERNEL_OUT="$ANDROID_TOP/$KERNEL_OUT"
fi
mkdir -p "$KERNEL_OUT" "$PRODUCT_OUT"
KERNEL_OUT="$(cd "$KERNEL_OUT" && pwd)"

export PATH="$CLANG_BIN:$GCC_BIN:$PATH"
KERNEL_BUILD_ARGS=(
  "ARCH=arm64"
  "CROSS_COMPILE=aarch64-linux-androidkernel-"
  "CLANG_TRIPLE=aarch64-linux-gnu-"
  "CC=$CLANG"
  "SAMSUNG_BOOT_PAGESIZE=$KERNEL_PAGE_SIZE"
)

echo
echo "Building S9 kernel: $KERNEL_DEFCONFIG -> $KERNEL_IMAGE_NAME"
make -C "$KERNEL_DIR" "O=$KERNEL_OUT" "${KERNEL_BUILD_ARGS[@]}" "$KERNEL_DEFCONFIG"
make -C "$KERNEL_DIR" "O=$KERNEL_OUT" "${KERNEL_BUILD_ARGS[@]}" -j"$KERNEL_JOBS" "$KERNEL_IMAGE_NAME"

KERNEL_IMAGE="$KERNEL_OUT/arch/arm64/boot/$KERNEL_IMAGE_NAME"
if [[ ! -s "$KERNEL_IMAGE" ]]; then
  echo "ERROR: kernel build completed without producing $KERNEL_IMAGE." >&2
  exit 1
fi
install -D -m 0644 "$KERNEL_IMAGE" "$PRODUCT_OUT/kernel"
echo "Staged Samsung kernel payload at $PRODUCT_OUT/kernel"

echo
echo "Building Evolution X Android 17 (S9 / starlte)"
m -j"$BUILD_JOBS" evolution

echo
echo "Build finished. Inspect $PRODUCT_OUT/ for the Evolution X package and boot/recovery images."

#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

# Create the minimum source layout consumed by the real build orchestrator.
while IFS= read -r path; do
  [[ -n "$path" ]] || continue
  mkdir -p "$TMP_ROOT/$(dirname "$path")"
  : > "$TMP_ROOT/$path"
done <<'EOF'
build/envsetup.sh
device/samsung/starlte/BoardConfig.mk
device/samsung/starlte/device.mk
device/samsung/starlte/lineage_starlte.mk
device/samsung/starlte/AndroidProducts.mk
device/samsung/exynos9810-common/BoardConfigCommon.mk
device/samsung/exynos9810-common/common.mk
kernel/samsung/exynos9810/Makefile
kernel/samsung/exynos9810/arch/arm64/boot/Makefile
kernel/samsung/exynos9810/arch/arm64/configs/exynos9810-starlte_defconfig
kernel/samsung/exynos9810/scripts/samsung_bootimg.py
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
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-gcc
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ld
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-objcopy
prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ar
EOF

chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-gcc"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ld"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-objcopy"
chmod +x "$TMP_ROOT/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-ar"
chmod +x "$TMP_ROOT/kernel/samsung/exynos9810/scripts/samsung_bootimg.py"

cat > "$TMP_ROOT/device/samsung/starlte/BoardConfig.mk" <<'EOF'
TARGET_KERNEL_CONFIG := exynos9810-starlte_defconfig
EOF
cat > "$TMP_ROOT/device/samsung/exynos9810-common/BoardConfigCommon.mk" <<'EOF'
BOARD_KERNEL_IMAGE_NAME := Image.samsung
BOARD_KERNEL_PAGESIZE := 2048
EOF
cat > "$TMP_ROOT/device/samsung/starlte/lineage_starlte.mk" <<'EOF'
PRODUCT_NAME := lineage_starlte
PRODUCT_DEVICE := starlte
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)
EOF
cat > "$TMP_ROOT/device/samsung/starlte/AndroidProducts.mk" <<'EOF'
PRODUCT_MAKEFILES := $(LOCAL_DIR)/lineage_starlte.mk
COMMON_LUNCH_CHOICES := lineage_starlte-userdebug
EOF

# envsetup exports the functions that the real build script expects.
cat > "$TMP_ROOT/build/envsetup.sh" <<'EOF'
lunch() {
  [[ "$1" == "lineage_starlte-cp2a-userdebug" ]] || {
    echo "Unexpected lunch target: $1" >&2
    return 1
  }
}
get_build_var() {
  [[ "$1" == "PRODUCT_OUT" ]] || return 1
  printf '%s\n' "$PWD/out/target/product/starlte"
}
m() {
  [[ "$*" == "-j2 evolution" ]] || {
    echo "Unexpected Android build command: $*" >&2
    return 1
  }
  [[ -s "$PWD/out/target/product/starlte/kernel" ]] || {
    echo "ROM target ran without a staged kernel." >&2
    return 1
  }
  printf '%s\n' "$*" > "$MOCK_ROM_TARGET"
}
EOF

MOCK_BIN="$TMP_ROOT/mock-bin"
mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/make" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%q ' "$@" >> "$MOCK_MAKE_LOG"
printf '\n' >> "$MOCK_MAKE_LOG"

kernel_out=""
for arg in "$@"; do
  case "$arg" in
    O=*) kernel_out="${arg#O=}" ;;
  esac
done
[[ -n "$kernel_out" ]] || {
  echo "make mock did not receive O=..." >&2
  exit 1
}

case " $* " in
  *" exynos9810-starlte_defconfig "*)
    mkdir -p "$kernel_out"
    : > "$kernel_out/.config"
    ;;
  *" Image.samsung "*)
    [[ -f "$kernel_out/.config" ]] || {
      echo "Image.samsung requested before defconfig." >&2
      exit 1
    }
    mkdir -p "$kernel_out/arch/arm64/boot"
    printf 'mock Samsung kernel container\n' > "$kernel_out/arch/arm64/boot/Image.samsung"
    ;;
  *)
    echo "Unexpected kernel make invocation: $*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$MOCK_BIN/make"

export MOCK_MAKE_LOG="$TMP_ROOT/make.log"
export MOCK_ROM_TARGET="$TMP_ROOT/rom-target.log"
PATH="$MOCK_BIN:$PATH" BUILD_JOBS=2 KERNEL_JOBS=2 \
  bash "$REPO_ROOT/scripts/build-starlte.sh" "$TMP_ROOT"

PRODUCT_KERNEL="$TMP_ROOT/out/target/product/starlte/kernel"
test -s "$PRODUCT_KERNEL"
grep -Fq 'mock Samsung kernel container' "$PRODUCT_KERNEL"
grep -Fq 'exynos9810-starlte_defconfig' "$MOCK_MAKE_LOG"
grep -Fq 'Image.samsung' "$MOCK_MAKE_LOG"
grep -Fq 'CROSS_COMPILE=aarch64-linux-android-' "$MOCK_MAKE_LOG"
grep -Fq 'ARCH=arm64' "$MOCK_MAKE_LOG"
grep -Fq 'SAMSUNG_BOOT_PAGESIZE=2048' "$MOCK_MAKE_LOG"
grep -Fq -- '-j2' "$MOCK_MAKE_LOG"
grep -Fq -- '-j2 evolution' "$MOCK_ROM_TARGET"

echo "S9 kernel build, staging and Evolution build orchestration test passed."

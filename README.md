# Evolution X — Galaxy S9 (Exynos 9810)

Initial device bring-up for the **Samsung Galaxy S9 Exynos variant**:

- Device codename: `starlte`
- Model: `SM-G960F`
- SoC: Samsung Exynos 9810
- Target ROM branch: Evolution X `cnb` (Android 17)
- Current branch version metadata: Android `17.0`, Evolution version base `12.3`, unofficial build by default
- Platform/device-tree base: LineageOS `lineage-24.0`

This project is not for the Snapdragon Galaxy S9 (`starqlte`) and must not be flashed to that variant.

## Source selection

The local manifest syncs only the S9's device tree, Exynos 9810 common tree, matching kernel, matching proprietary vendor blobs, and Samsung platform dependencies. The S9+ and Note 9 projects have been left out of this S9-first sync to avoid downloading unneeded trees and blobs.

The device/kernel/vendor trees are on the upstream ExyHyperBrick `lineage-24.0` branches. The Samsung Linaro stack includes ExyHyperBrick config and graphics (`lineage-21`) plus Exynos (`lineage-23.2`), and LineageOS interfaces and OpenMAX (`lineage-24.0`). The older config/graphics/Exynos branches retain Exynos 9810-specific support not present in the generic current graphics tree. These pins are compatibility choices, not Android 17 certification claims; the first compile will validate whether more porting is required.

## Build host

A 64-bit Arch Linux host with at least 300–400 GB free SSD is recommended for a full source checkout and build. 32 GB RAM is workable; use a modest parallelism setting and sufficient swap. Start with `BUILD_JOBS=4` and `KERNEL_JOBS=4` on a 32 GB machine. The local manifest syncs the AArch64 GCC 4.9 cross-compiler and binutils used by the upstream legacy kernel build rule. The `cnb` manifest syncs OpenJDK 21 and OpenJDK 25 prebuilts. Soong selects the build JDK from the release configuration; do not force your system `JAVA_HOME` to an arbitrary version. Your system having Java 25 only should not, by itself, block this build.

Install the Android build prerequisites from the current Android/Lineage build documentation and make sure `repo`, Git, Python, Git LFS, and standard build utilities are available. **Important for this legacy kernel:** the pinned GCC 4.9 wrapper uses an absolute `/usr/bin/python` shebang. On Arch, install the official `python` package (`sudo pacman -S python`) and verify `test -x /usr/bin/python` before starting the kernel build.

## Sync the Android 17 source

From the directory where you want the Android source checkout:

```bash
repo init -u https://github.com/Evolution-X/manifest -b cnb --git-lfs
mkdir -p .repo/local_manifests
cp /path/to/evolutionx-exynos9810/local_manifests/exynos9810.xml .repo/local_manifests/exynos9810.xml
repo sync -c -j4 --force-sync --no-clone-bundle --no-tags
```

Use the S9 bring-up branch of this repository for the scripts while the changes are under review:

```bash
git clone -b s9-bringup https://github.com/axmezonar/evolutionx-exynos9810.git
```

## Prepare and build the S9

Run this from the Android source root. The build script checks the complete S9 source set and executable kernel toolchains, preserves the upstream `lineage_starlte` product, adds Evolution X's Android 17 `cp2a` lunch choices, builds the device kernel, stages its output, and only then starts the ROM build:

```bash
BUILD_JOBS=4 KERNEL_JOBS=4 bash /path/to/evolutionx-exynos9810/scripts/build-starlte.sh "$PWD"
```

The kernel phase reads the actual S9 defconfig, Samsung image name and page size from the synced device configuration. It uses the upstream AArch64 GCC 4.9 cross-toolchain, then runs the kernel's `Image.samsung` target. That target creates Samsung's Exynos 9810 kernel/DTBH container; it is **not a standalone flashable image**. The script stages it as `$PRODUCT_OUT/kernel`, which is the kernel payload consumed by Android's boot-image packaging rules, before running `m evolution`.

`BUILD_JOBS` controls Android's ROM build parallelism and `KERNEL_JOBS` controls the separate kernel build. Both default to 4; reduce them if the workstation runs out of RAM. You can override the kernel build directory with `KERNEL_OUT`.

To inspect the synced source and product setup without starting a build:

```bash
bash /path/to/evolutionx-exynos9810/scripts/verify-starlte-sync.sh "$PWD"
bash /path/to/evolutionx-exynos9810/scripts/prepare-device-trees.sh "$PWD"
```

Expected lunch target: `lineage_starlte-cp2a-userdebug`. Evolution X's current `cnb` manifest uses the `lineage_<codename>-cp2a-<variant>` form and builds with `m evolution`; the current vendor config sets Android version `17.0`, Evolution version base `12.3`, and defaults `EVO_BUILD_TYPE` to `Unofficial`. Use the build script rather than invoking `m evolution` directly, because the Android 17 build tree does not automatically build this legacy Exynos kernel from its source checkout.

## Validation sequence

A successful compile is only the first milestone. Before publishing or flashing a build, validate on an actual **SM-G960F**:

1. Boot and recovery access; verify boot/vendor_boot/dtbo partition assumptions and recovery compatibility.
2. Display, touch, brightness, auto-rotation, proximity and ambient-light sensors.
3. Wi-Fi, Bluetooth, NFC, GPS, SIM detection, LTE data, VoLTE/IMS and calls.
4. Front/rear cameras, video recording, flash and camera switching.
5. Fingerprint, audio/microphone, speakers, USB/MTP and charging.
6. Encryption/decryption, reboot, SELinux enforcing state, OTA/update flow and thermal behavior.

Keep a known-good stock firmware and a recovery path available. Do not flash an image built for a different model or Snapdragon variant.

## Current completion status

The S9 source integration and product-definition scaffolding are present. Static CI checks cover shell syntax, S9 lunch-choice generation, idempotence, required source paths and executable toolchains, the kernel build/staging hand-off, and XML well-formedness. **No Android ROM build, emulator run, boot test or physical hardware test has been performed in this environment.** The ROM is therefore not finished or safe to distribute yet; compiler output and device logs will drive the next porting fixes.

## Scope

S9 is the first target. S9+ (`star2lte`) and Note 9 (`crownlte`) bring-up will follow only after the S9 has a reproducible successful build and validated boot.

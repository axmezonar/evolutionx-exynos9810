# Evolution X — Exynos 9810

Unofficial bring-up workspace for Samsung Exynos 9810 devices:

| Codename | Device | Model |
|---|---|---|
| `starlte` | Galaxy S9 | SM-G960F |
| `star2lte` | Galaxy S9+ | SM-G965F |
| `crownlte` | Galaxy Note 9 | SM-N960F |

## ROM base

- Upstream: [Evolution-X/manifest](https://github.com/Evolution-X/manifest)
- Target branch: `cnb` (Android 17)
- The upstream manifest currently pins its platform projects to `lineage-24.0`.

## Build host

Your previously described Arch Linux workstation (i7-10610U, 32 GB RAM, at least 1 TB free SSD) is a workable starting point. Keep generous swap available. Use the JDK version required by the exact Android build branch; do not assume the newest system Java is compatible.

## Sync

```bash
repo init -u https://github.com/Evolution-X/manifest -b cnb
mkdir -p .repo/local_manifests
cp /path/to/evolutionx-exynos9810/local_manifests/exynos9810.xml .repo/local_manifests/exynos9810.xml
repo sync -c --force-sync --no-clone-bundle --no-tags -j4
```

Apply the product definitions after syncing:

```bash
bash /path/to/evolutionx-exynos9810/scripts/prepare-device-trees.sh
source build/envsetup.sh
lunch evolution_starlte-userdebug
mka bacon
```

Use `evolution_star2lte-userdebug` for S9+ or `evolution_crownlte-userdebug` for Note 9.

## Current status and caveats

This is a bring-up scaffold, not a verified ROM release. Device, kernel, and proprietary vendor trees selected here are on LineageOS 24.0 branches. Some Samsung Linaro hardware dependencies are older (config/graphics 21; Exynos 23.2) and are explicitly pinned in the local manifest. They must be validated against the Android 17 build before claiming compatibility.

No successful build, boot, radio, camera, fingerprint, NFC, audio, encryption, or OTA test is claimed. Expect API/Soong, sepolicy, blob, and kernel integration fixes. Do not flash anything until the image has been built and tested on the exact model. Exynos and Snapdragon variants are not interchangeable.

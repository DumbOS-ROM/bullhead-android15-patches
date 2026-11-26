# CHECKPOINT — bullhead (DumbOS / LineageOS 22.2 - Android 15)

- **Tanggal/Waktu:** 2026-11-26 14:00 WIB (Clean Full Rebuild dengan Patch Kernel 3.10 Lengkap)
- **Build ID / Artifact Terakhir:** `DumbOS-22.2-20261126-UNOFFICIAL-bullhead.zip` (`862M`, SHA-256: `4cccc84ced3b33ccddbba759b352ec2bbd5b117cf97e3f8507af57ab89542837`) | `boot.img` (`13M`, SHA-256: `d81a1ade930b50ec6cf1cc5fb732e6a2d9dcb8d033925d6b3b726dd6e4135fc`) | `recovery.img` (`19M`, SHA-256: `d8619cb0f0c420ada886cdecc51ee21d6325aeff25a4dce25c65b8ef14430012`)
- **Platform Base (`frameworks/base`):** `DumbOS-ROM/android_frameworks_base@c57d659cb` (`full microG signature spoofing for priv-apps, hasSigningCertificate & checkSignatures`)
- **Vendor DumbOS:** `DumbOS-ROM/android_vendor_dumbos@7bc0bdf` (`feat(lineage-22.2): add DumbQuickStepService for swipe gesture navigation & Settings nav menu`)
- **Device Tree & Kernel Fork:** `DumbOS-ROM/android_device_lge_bullhead` & `DumbOS-ROM/android_kernel_lge_bullhead` (branch `dumbos-22.2-bullhead`, Linux `3.10` + eBPF backport `5.4.302`)
- **Batas Partisi:** `boot` <= `33554432` bytes (aktual `13565952`, 40.43%) | `recovery` <= `33554432` bytes (aktual `19771392`, 58.92%) | `system` <= `3221225472` bytes (aktual `2.1G`) | `cache` <= `100663296` bytes | `userdata` <= `11649679360` bytes

## 1. Do Not Break List (Build-Verified, Menunggu Uji Perangkat)
- [ ] Display & Touch (Adreno 418, `disable_scs=true` via `build/soong` patch)
- [ ] Audio Speaker & 3.5mm Jack (`audio@2.0` legacy HIDL)
- [x] DumbLauncher + `DumbQuickStepService` (`vendor/dumbos@7bc0bdf`)
- [x] microG Full Signature Spoofing (`c57d659cb`)
- [x] Kernel 3.10 Userspace Compat (`libprocessgroup`: `"Cgroup v2 is unavailable; skipping process cgroup creation"` terverifikasi di `system/lib64/libprocessgroup.so`)
- [ ] Monochrome Engine (`ThemeOverlayController`), & Custom Fonts (`OnePlusSlate` di `/system/fonts`)
- [ ] Thermal / CPU / GPU / ZRAM (`CONFIG_ZRAM=y`, `CONFIG_ZRAM_LZ4_COMPRESS=y`, `MALLOC_SVELTE=true`)
- [ ] GNSS / Sensor / Wi-Fi / BT / RIL / Camera
- [ ] USB Gadget / ADB & `pstore`/`ramoops` (`CONFIG_PSTORE_RAM=y`, `CONFIG_LGE_HANDLE_PANIC=y`)

## 2. Daftar Patch Aktif (Synced & Idempotent)
Semua patch disimpan di `DumbOS-ROM/bullhead-android15-patches` dan diterapkan via `scripts/apply_patches.sh`:
- `local_manifests/bullhead_dumbos.xml` — Manifest khusus DumbOS (menunjuk ke `DumbOS-ROM/android_device_lge_bullhead` & `DumbOS-ROM/android_kernel_lge_bullhead` branch `dumbos-22.2-bullhead`).
- `patches/build_make/0001-4622a0a1...patch` — Re-sign recovery image di system/vendor.
- `patches/build_soong/0001-4c6a0dda...patch` — Opsi `disable_scs` (Shadow Call Stack) untuk blob Adreno 8.1 (`x18`).
- `patches/frameworks_av/0001..0002` — Widevine legacy HAL & `libaudioclient` `onNewService`.
- `patches/frameworks_base/0001..0007` — SIM PIN bouncer, QR scanner 270deg, ZRAM/CachedAppOptimizer tanpa freezer, USAP zygote, FRP secret.
- `patches/frameworks_base/0008-fonts-Disable-installable-on-AOSP-fonts-xml-for-Dumb.patch` — Set `installable: false` pada `fonts.xml` dan `font_fallback.xml` AOSP.
- `patches/frameworks_base/0009-frameworks-tolerate-kernels-without-fs-verity.patch` — Toleransi kernel tanpa `fs-verity`.
- `patches/frameworks_opt_telephony/0001..0003` — WAP push bounds, single SIM data sub, IMS wake lock.
- `patches/hardware_interfaces/0001-03d829a9.patch` — `audio: Size the binder threadpool before starting it`.
- `patches/packages_apps_Settings/0001..0003` — FRP OEM unlocking guard & Wi-Fi calling switch sync.
- `patches/packages_services_Iwlan/0001..0002` — VTI tunnel endpoints & wake lock.
- `patches/art/0001-art-support-explicit-suspend-on-the-legacy-arm64-ker.patch` — Explicit suspend support untuk kernel 3.10 arm64.
- `patches/frameworks_native/0001-binder-support-legacy-activity-manager-transactions.patch` — Legacy binder/gpuservice support.
- `patches/packages_modules_Connectivity/0001-Connectivity-add-a-non-eBPF-path-for-legacy-kernels.patch` — Non-eBPF path untuk kernel 3.10.
- `patches/packages_modules_DnsResolver/0001-DnsResolver-skip-BPF-socket-tagging-when-unsupported.patch` — Skip BPF socket tagging jika tidak didukung.
- `patches/system_core/0001-libprocessgroup-tolerate-an-unavailable-cgroup-v2-hi.patch` — Toleransi cgroup v2 tidak tersedia (KRITIS: tanpa ini `init`/`libprocessgroup` macet di logo Google).
- `patches/system_memory_lmkd/0001-lmkd-support-in-kernel-LMK-without-PSI-monitoring.patch` — In-kernel LMK tanpa PSI monitoring.
- `patches/system_netd/0001-netd-use-legacy-bandwidth-control-without-BPF.patch` — Legacy bandwidth control tanpa BPF.
- `patches/vendor_partner_gms/0001-GmsCore-Fix-zip2zip-glob-pattern-for-Android-15.patch` — Mengubah pola `zip2zip` di `GmsCore/Android.mk` dari `/**` menjadi `/**/*` untuk Android 15.
- `DumbOS-ROM/android_device_lge_bullhead` (`proprietary-files.txt`) — Fixup hash `vendor/app/ims/ims.apk` disesuaikan ke `e8ef07d1899e5ccc2fb0b0374b3d8f2afc371fb4`.

## 3. Catatan Error Patch Saat Rebuild & Perbaikannya
- **`0001-GmsCore-Fix-zip2zip-glob-pattern-for-Android-15.patch` & `0008-fonts-Disable-installable-on-AOSP-fonts-xml-for-Dumb.patch`:** Keduanya berformat raw `git diff` (tanpa header `From `), sehingga `git am` gagal dengan `Patch format detection failed`. Diperbaiki di `scripts/apply_patches.sh` dengan fallback `git apply --index` + `git commit` bila `git am` gagal.
- **Belum diuji di perangkat fisik:** Build bersih `20261126` (`4cccc84c...`) perlu di-flash ke Nexus 5X (plus `/cache/blod` jika unit BLOD) untuk verifikasi boot & hardware (Fase 2–4).

## 4. Hipotesis yang Sudah Digugurkan (Ruled-Out)
- *`extract-files.py` gagal dengan `Partition system not extracted` / `Some files failed to process`:* Sudah diselesaikan di `scripts/extract_blobs.sh` dan `proprietary-files.txt`.
- *Stuck logo Google pada build `20261125` (`D:\DumbOS-ROM`) disebabkan oleh patch BLOD atau microG `c57d659cb`:* Digugurkan oleh diff biner langsung (`OLD` vs `NEW`), yang membuktikan hilangnya 8 patch kompatibilitas kernel 3.10 (khususnya `libprocessgroup` cgroup v2) sebagai akar masalah.

## 5. Bukti Audit Terakhir
- **Build Server:** `waffle.serverhive.in` (`~/dumbos-15`, clean full build `18:58`, exit code `0`, `SHA256SUMS.txt` terverifikasi).
- **Uptime Uji Perangkat:** Menunggu uji flash build `20261126`.

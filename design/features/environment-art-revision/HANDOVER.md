# Handover perbaikan aset dan scenery untuk AI berikutnya

15 November 2026, Asia/Jakarta. Dokumen ini adalah pintu masuk pekerjaan; rincian desain tetap di [plan.md](plan.md), status fitur tetap di [PROGRESS](../../../PROGRESS.md).

## Kondisi saat diserahkan

- Pengguna meminta file Studio disimpan pada **E:/Antigravity/Fly High/Fly High.rbxl** dan dokumentasi disiapkan untuk AI lain.
- MCP mendeteksi sesi Edit dengan file lokal `Fly High.rbxl`, place **97043730132219**, universe **10776821830**. `save_place` mengembalikan **NotNeeded / LocalFile** dengan path tersebut: Studio melaporkan tidak ada perubahan yang belum disimpan. File lokal tersedia, 2.164.854 byte, SHA-256 **EA632B7B6AE0219EE5802DB6843203734AB33D79E32C5EE16D0B3E3B0D072495**. Ini konfirmasi file lokal yang sudah tersimpan, bukan save cloud atau publikasi baru.
- File belum dibuka ulang pada pemeriksaan ini. Jangan mengklaim seluruh isi binary sama dengan Studio atau versi published/cloud tanpa pemeriksaan terpisah. Tidak memeriksa versi cloud terbaru.
- Studio: 54 source, 0 pemain, fixture scenery tidak ada. Tidak menjalankan Playtest atau mengubah source/aset pada tugas penyimpanan ini.
- Salinan sebelum pemeriksaan disimpan di `audit/local-save-handover-2026-11-15/Fly High.before-save.rbxl`. [Respons alat dan bukti disk](../../../audit/local-save-handover-2026-11-15/README.md).
- Working tree berisi banyak pekerjaan sebelumnya yang belum di-commit. Jangan reset/clean/overwrite source pengguna. Tidak ada commit/push baru dari tugas ini.

## Baca dahulu

1. [AGENTS](../../../AGENTS.md), [HANDOVER utama](../../../HANDOVER.md), [PROGRESS](../../../PROGRESS.md), [WORKFLOW](../../../docs/WORKFLOW.md).
2. Bagian rintangan dan lima tema bioma pada [PRD](../../../PRD_Fly_High.md), lalu [inventaris scenery](../../SCENERY.md).
3. **[Rencana revisi lengkap](plan.md)**: inventaris, prioritas P0/P1/P2, arah seni, LOD, urutan batch dan gerbang penerimaan.
4. [Audit aset](../../../audit/environment-art-review-2026-11-15/README.md), terutama screenshot penerbangan pengguna **2.421 km**. Capture fixture close-up sebelumnya tidak membuktikan komposisi kamera penerbangan bagus.
5. [Audit skill Blender](../../../docs/roblox-development/blender-skills-review-2026-11-15/README.md) sebelum menjalankan script paket.

## Status implementasi yang harus dibedakan

**Sudah tersedia:** paket 18 model/34 komponen, perbaikan opacity VFX cuaca, dan reuse 17 keluarga model pada lima scenery. Lihat checkpoint implementasi pada PROGRESS; tidak perlu membangun ulang semuanya dari nol.

**Belum dikerjakan:** revisi seni yang dirumuskan setelah screenshot pengguna menunjukkan tornado bertingkat, awan terlepas, skala timpang dan ruang bawah kosong. Seluruh usulan `plan.md` masih proposal. Audit/instalasi skill bukan bukti polesan tersebut sudah dilakukan. Lanjutkan sesuai instruksi pengguna kepada AI penerima.

## Titik mulai yang disarankan

Kerjakan **Batch 1 Area 2** terlebih dahulu: tornado latar kontinu, kepala/kaki menyatu, keluarga storm cloud dan hujan, lalu komposisi dari gondola sekitar 2.421 km. Tetapkan patokan mutu dari kamera pemain sebelum mengulang kit pada area lain. Setelah itu urutannya pulau/air, kosmik/fauna/LOD, gerbang/kapal/istana, lalu prop kecil/rintangan lanjutan.

Jangan memperbaiki kekosongan dengan menambah objek acak atau memperbesar semua aset. Jangan menggunakan shader/volumetrik Blender seolah otomatis berjalan di Roblox. Pertahankan band, damage, spawn, warning, hitbox, collision cloud walk, barrier, seat dan alur arrival kecuali instruksi pengguna mengubah lingkup gameplay.

## Source dan aset penting

- `audit/sources/ReplicatedStorage/FlyHigh/Modules/BiomeScenery.luau`: scenery lima zona; `buildStormVortex` masih membentuk 29 elipsoid. Tornado latar pada source checkpoint memakai lebar atas 175 dan tinggi 237 stud.
- `audit/sources/ReplicatedStorage/FlyHigh/Modules/SceneryHabitatArt.luau`: salinan visual template rintangan, fauna/pedestal/ornamen. Tidak memberi flag target atau collision.
- `audit/sources/ServerScriptService/FlyHighServer/ObstacleArt.luau`, `ObstacleVisuals.luau`, `ObstacleMotion.luau`, `ObstacleManager.luau`, `LargeChallengeManager.luau`: pisahkan model/VFX dari aturan gameplay.
- `assets/generate-scenery-meshes.cjs`: generator landmark; perubahan file ini belum mengubah template Studio.
- `tools/build_obstacle_models.py` dan `assets/models/obstacles/generated/manifest.json`: source/manifest paket Blender. `FlyHigh_Obstacle_Atelier.blend` adalah file kerja model. Scene live sebelumnya memiliki duplikat phoenix; ekspor hanya root yang disepakati pada manifest, jangan hapus duplikat pengguna.
- Studio: `ReplicatedStorage.FlyHigh.Templates.ObstacleMeshes`, `EnvironmentAssets.BiomeLandmarkMeshes`, serta `Workspace.CloudPalace`. Emblem statis `CustomArchitecture.PhoenixGateEmblem` ikut disalin ke vista.
- Source Studio harus dibaca dengan **ScriptEditorService.GetEditorSource** dan dibandingkan dengan mirror sebelum memilih acuan. Snapshot parity lama tidak otomatis berlaku untuk sesi AI baru.

## Skill yang tersedia

Lima skill baru ada di `C:/Users/fahma/.codex/skills/`: `blender-core`, `blender-environment-kits`, `blender-asset-qa`, `blender-hardsurface-modeling`, `blender-weather-fx`. Upstream commit dikunci ke `b1b21dfb73bc40b874ebf2aa12645931bfed3523`, 25 file cocok SHA-256. Blender yang diperiksa 5.3.0. Pada mesin lain, gunakan snapshot audit dan lakukan pemasangan terarah; jangan menganggap skill sudah tersedia.

Gunakan skill yang diperlukan untuk batch aktif saja. Script upstream belum dijalankan oleh sesi audit. Beberapa helper menghapus data dengan nama tertentu atau mengubah shared mesh/material; gunakan scene/salinan milik tugas. Tidak ada otorisasi tambahan untuk upgrade aplikasi, auto-run script, upload berbayar atau publikasi hanya karena skill terpasang.

## Penutupan setiap batch

Simpan source yang dapat diedit, preview sudut sebanding dan manifest impor. Periksa model di Studio, dari kamera penerbangan normal dan grafis rendah; uji akses/collision terpisah. Rekam build/source hash, altitude target/aktual, fixture, screenshot/video dan log. Perbarui **baris WORLD-02/GAME-06 yang sama** sesuai lingkup, bersihkan fixture, pulihkan Edit/Test/satu pemain dan simpan place. Bedakan source parity, simpan lokal, buka ulang binary, commit dan push. Jangan menandai proposal ini selesai hanya karena model berhasil diekspor.

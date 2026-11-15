# Audit dan instalasi skill Blender — 15 November 2026

Atas permintaan pengguna untuk mencari/memasang skill sebelum rencana polesan aset. Lima skill dipasang; **tidak menjalankan script Blender dari paket ini dan tidak mengubah aset game**.

Sumber: [EL4CTEO/blender-skills](https://github.com/EL4CTEO/blender-skills/tree/b1b21dfb73bc40b874ebf2aa12645931bfed3523), commit `b1b21dfb73bc40b874ebf2aa12645931bfed3523`, lisensi MIT. Versi skill 1.2.0. Sumber ini berbeda dari snapshot Roblox lama; audit ulang dilakukan, bukan memakai reputasi/audit sebelumnya sebagai jaminan.

| Skill | Kebutuhan Fly High | Snapshot |
| --- | --- | --- |
| blender-core | Fondasi eksekusi Blender, isolasi scene pengguna, kompatibilitas API | [SKILL](skills/blender-core/SKILL.md) |
| blender-environment-kits | Proporsi kit, pivot, sambungan, peletakan flora/ornamen terhadap permukaan | [SKILL](skills/blender-environment-kits/SKILL.md) |
| blender-asset-qa | Pemeriksaan geometri serta review multi-sudut sebelum ekspor | [SKILL](skills/blender-asset-qa/SKILL.md) |
| blender-hardsurface-modeling | Bevel, shading dan struktur kapal, arsitektur, drone, satelit | [SKILL](skills/blender-hardsurface-modeling/SKILL.md) |
| blender-weather-fx | Rancangan lapisan hujan/petir/kabut dan batas ekspor ke engine | [SKILL](skills/blender-weather-fx/SKILL.md) |

Dipilih lima dari 28 skill repository; core merupakan pendukung empat spesialis. Tidak memuat semuanya otomatis. NPR/toon, simulasi, rendering batch, generasi 3D berbayar dan installer upstream tidak dipasang. Kandidat art-director generik juga tidak dipasang: routing/identitas/agennya terlalu luas untuk kebutuhan audit ini. Roblox-world-level-design dan asset-pipeline tetap dipakai untuk komposisi/penerapan engine.

## Metode dan putusan

- Clone tanpa checkout, hook upstream tidak dipakai; ekspor hanya direktori terpilih. Tidak menjalankan installer repository.
- 25 file / 187.821 byte dipindai, seluruh entri regular blob `100644`; tidak ada symlink, path traversal, NUL atau kontrol bidi.
- Python diparsing sebagai AST, import/titik subprocess/write/delete ditinjau. Tidak ditemukan akses jaringan, pengiriman data, pengambilan credential atau kode obfuscation pada subset terpilih. Pemeriksaan manual difokuskan pada entry point dan operasi yang dapat mengubah scene/file. Ini bukan pembuktian formal semua perilaku runtime.
- Instalasi menggunakan helper skill-installer bawaan Codex, ref commit tetap. Seluruh 25 file terpasang cocok SHA-256 dengan snapshot audit; LICENSE MIT dilengkapi pada kelima direktori.
- Terpasang di `C:/Users/fahma/.codex/skills/<nama-skill>/`. Skill dapat ditemukan otomatis mulai giliran berikutnya. Isi snapshot yang telah dibaca dipakai sebagai referensi perencanaan pada sesi ini.
- Blender yang tersambung terverifikasi **5.3.0**, sehingga sesuai rentang versi paket. Telemetry consent=false; pustaka aset dan generator eksternal off. Tidak mengubah status tersebut.

Putusan: **layak dipasang untuk cakupan terpilih berdasarkan pemeriksaan statis ini**. Tidak ada jaminan keamanan absolut atau jaminan hasil visual. Update versi/commit membatalkan cakupan audit dan memerlukan pemeriksaan ulang.

## Batas wajib sebelum eksekusi mendatang

1. `run_in_blender.py` memang menjalankan script/expr lokal melalui subprocess; hanya gunakan kode yang dibaca dan diotorisasi. Instalasi bukan izin menjalankan script upstream sekarang.
2. `lightning.py` menghapus objek/material bernama `ENV_Storm_*`; `terrain.py` dapat mengosongkan mesh dengan nama yang sama. Gunakan scene/proyek salinan milik tugas dan periksa benturan nama.
3. `kit_check --fix` dapat mengubah data mesh tertaut; `surface_weather` mengubah material bersama. Gunakan salinan ekspor/material terlebih dahulu.
4. `review_shots.py` memulihkan banyak state tetapi tidak seluruhnya, misalnya format gambar dan warna objek. Jalankan di scene review terpisah. Jangan mengandalkan klaim restore sebagai bukti tanpa pemeriksaan.
5. `--save` menulis path yang diberikan; jangan menimpa source `.blend` pengguna. Profile Roblox (mis. watertight/20k tri) adalah heuristik skill; evaluasi pengecualian untuk membran, daun atau VFX terbuka. Bukan batas universal semua aset Roblox.
6. Shader node Blender, Geometry Nodes cuaca serta volume tidak otomatis menjadi efek Roblox. Gunakan Blender untuk bentuk/mask/tekstur; implementasi akhir dan QA harus di Roblox. Jangan menyalin kepadatan partikel render offline ke mobile.

[Manifest/hash](manifest.json), [scan AST/pola](static-scan.json), [putusan dan caveat](review-status.json), [hasil instalasi](installation-verification.json), [lisensi](LICENSE). Snapshot `.py` disimpan untuk audit, bukan perintah eksekusi otomatis.

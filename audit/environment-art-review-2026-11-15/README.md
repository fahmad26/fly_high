# Review aset dan rencana revisi — 15 November 2026

**Audit/read-only dan dokumentasi. Tidak ada implementasi polesan baru.** Rencana lengkap: [Environment art revision](../../design/features/environment-art-revision/plan.md).

## Bukti yang dibaca

- [Screenshot pengguna pada penerbangan 2.421 km](user-flight-2421km.png): tornado latar berundak, awan lepas, skala tidak seimbang dan kekosongan lapisan bawah.
- [Galeri model](../obstacle-polish-implementation-2026-11-15/README.md): hero-models, early-models, object-models dan solid-models diperiksa secara visual pada sesi ini. Capture historis tersebut bukan QA kamera penerbangan terbaru.
- [Capture scenery/plaza terakhir](../scenery-obstacle-consistency-2026-11-15/README.md) menjadi dasar review lima tema serta hubungan dekorasi/rintangan.
- [Studio inventory](studio-inventory.json): read-only pada Edit, place 97043730132219, universe 10776821830. 18 template rintangan, 18 landmark dan struktur palace diperiksa; potongan source funnel 29 elipsoid dikonfirmasi.
- [Blender geometry](blender-geometry.json), [scene](blender-state.json), [versi/add-on](blender-addon.json): Blender 5.3.0, FlyHigh_Obstacle_Atelier, OBJECT, frame 81, 19 empty/37 mesh termasuk duplikat phoenix sebelumnya. Pemeriksaan tidak mengganti scene, frame, selection, material atau geometri.

Pemeriksaan mesh sederhana membaca data melalui bpy/bmesh; BMesh sementara dibebaskan. Tidak menjalankan script upstream, modifier, normals recalc, triangulate, render, ekspor atau save. Hasil boundary/non-manifold/degenerate/scale tidak menggantikan QA menyeluruh normals, UV, self-intersection, animasi atau tampilan Roblox.

## Temuan angka yang membantu prioritas

Manifest paket berisi 18 model/34 komponen dengan 57.768 tris sumber. Camar 4.972, elang 5.196, lebah 5.976, wyvern 6.210, phoenix 5.788, satelit 8.444; grid panel satelit memakai 5.760 tris. Kombinasi 19 camar dan 4 elang di scene Dawn setara 115.252 tris sumber. Ini perkalian inventaris, bukan pengukuran jumlah segitiga GPU, draw call, frame time atau FPS perangkat mobile.

Bentuk yang sudah manifold masih dapat tampak kasar karena proporsi, shading, siluet, skala layar, penataan atau material. Rencana tidak meminta membangun ulang semua model atau membulatkan kristal/es yang sengaja berbidang.

## Skill

Lima skill baru telah dipasang pada commit terkunci: blender-core, blender-environment-kits, blender-asset-qa, blender-hardsurface-modeling, blender-weather-fx. [Audit dan hasil instalasi](../../docs/roblox-development/blender-skills-review-2026-11-15/README.md). 25 file cocok SHA-256, lisensi MIT disertakan; tidak menjalankan script Blender dari skill. Ketersediaan otomatis dimulai giliran berikutnya.

## Batas dan invariansi

- Tidak memulai Playtest baru, membuat fixture baru, menggerakkan kamera Studio atau menyimpan/publish place pada tugas ini.
- Tidak membuat, mengimpor, mengunggah, mengganti atau menghapus aset game. Git commit/push tidak dilakukan.
- Hash file `.rbxl` dan seluruh source mirror dibandingkan dengan baseline awal audit; hasil ada pada [invariance.json](invariance.json). Pemeriksaan hash file bukan bukti binary telah dibuka ulang atau cloud sama dengan Studio.
- Status pekerjaan seni adalah proposal. Bukan hasil QA visual/performa untuk versi yang sudah diperbaiki. Studio tetap Edit; Blender tetap scene pengguna yang sama.

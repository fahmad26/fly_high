# Model rintangan Fly High

Model asli dibuat dengan Blender untuk implementasi 15 November 2026. [QA dan batas verifikasi](../../../audit/obstacle-polish-implementation-2026-11-15/README.md).

- `generated/FlyHigh_Obstacles.glb`: 18 model / 34 mesh, satu atlas, tidak menyertakan Cube scene awal.
- `generated/manifest.json`: anggaran segitiga dan dimensi model; `components.json`: ukuran/pusat native Roblox per komponen.
- `generated/FlyHigh_Obstacle_Atelier.blend`: copy scene kerja; scene pengguna awal dipertahankan. Terdapat duplikat phoenix eksperimen yang tidak termasuk paket unggahan. Ekspor hanya daftar root pada manifest.
- [Generator](../../../tools/build_obstacle_models.py) membuat scene baru dan menolak menimpa Atelier yang sudah ada. Blender safe mode tetap aktif; tidak memakai layanan generasi berbayar.
- Paket Roblox `99873351598859` Approved, atlas impor `98805576529305`. Pasang melalui Studio; gunakan [penyiapan template](../../../tools/import_obstacle_models.luau) hanya saat `ObstacleMeshes` belum ada. Periksa diff sebelum mengganti template yang sudah dipoles.
- Template memakai pivot Core identitas, geometri menghadap -Z dan direct child Wing/Aperture. Unggahan GLB memakai meter; normalisasi ukuran dan rotasi Y 180° dijalankan pada MeshPart hasil impor, bukan mengubah file untuk melewati izin.
- Tandai ImportVerified sesudah verifikasi ukuran, orientasi, warna dan nama komponen. Flag ini adalah pemeriksaan impor, bukan persetujuan visual pengguna atau kelulusan QA mobile.

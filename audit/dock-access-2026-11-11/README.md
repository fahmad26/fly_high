# Jalan dan akses dermaga — 11 November 2026

Build dasar 44093850df0044a86a9285f0f9f0412023369e63, Studio lokal Fly High.rbxl. Perubahan berupa Terrain dan objek place; source gameplay tidak diubah.

## Akar masalah dan perbaikan

- [Sampel awal](before.json): tanah di dekat Dermaga A mencapai 16,32 stud, sedangkan deck berada sekitar 10,28 stud. Pemeriksaan jarak antar-dermaga dari atas sebelumnya tidak membuktikan akses di level pemain.
- Material tanah pada percobaan jalan lama sulit terbaca dan sebagian tertutup IslandGround. Sekarang ada permukaan jalan nyata selebar 9 stud, berwarna batu krem matte, dengan border rendah tanpa penghalang.
- Jalan utama menghubungkan plaza spawn ke promenade setengah lingkaran radius 70, lalu bercabang ke A–E. Posisi dermaga, PreviewBase, volume spawn dan clearance 68,883 stud dipertahankan.
- Tanah dalam radius 22 stud dari dermaga dan sepanjang akses diratakan; tepi area grading dibaurkan. [Sampel akhir](heights.json) mencatat sekitar 10,00–10,004 stud di radius 20 dari kelima dermaga. Tanaman mengikuti perubahan tinggi tanah; 14 dekorasi yang mengganggu jalan dipindahkan.
- Permukaan akhir memakai 167 part sederhana tanpa UnionOperation. Tidak ada collider tinggi yang mengharuskan pemain melompat. Border noncollidable dan diputus pada persimpangan.

## QA dan fixture

[Driver server](walk.server.luau) dan [client](walk.client.luau): satu klien native Studio, karakter direset di spawn di antara kasus, lalu Humanoid berjalan sepanjang waypoint menuju tiap dermaga. Tidak ada teleport di sepanjang rute, jump otomatis, shield atau launch balon.

[Hasil akhir](walk-results.json) menyimpan posisi, waktu, health dan state aktual pada waypoint. Kriteria: kelima rute sampai ke dermaga yang benar, CurrentPod cocok, pemain hidup, dan nol runtime error server. Tidak mencakup uji perangkat fisik, avatar tinggi, penerbangan atau penilaian kenyamanan manusia.

[Tampilan atas akhir](top-final.jpg) dan [Dermaga A dari level pemain](dock-a-final.jpg) adalah screenshot Edit setelah perbaikan, bukan screenshot saat berjalan.

## Percobaan yang ditolak

- Grading pertama menganggap voxel Air sebagai tanah. Perubahan dibatalkan lewat ChangeHistory sebelum dilanjutkan.
- Grading berikutnya menghasilkan permukaan raycast 12 stud walaupun target occupancy 10; percobaan FillBlock terisolasi mengonfirmasi offset permukaan Terrain. Area percobaan luar pulau dibersihkan, target occupancy dikoreksi menjadi 8, lalu raycast kelima dermaga mengonfirmasi permukaan sekitar 10.
- Jalan CSG lulus [uji jalan awal](walk-csg-results.json), tetapi inspeksi visual atas menemukan lubang render akibat geometri coplanar. Screenshot top-csg-rejected.jpg disimpan; hasil itu tidak dipakai sebagai bukti visual akhir. Union diganti part sederhana, lalu uji jalan diulang.

Untuk merekonstruksi akses: layout.luau melakukan grading dan konstruksi awal; paving-final.luau mengganti paving menjadi bentuk akhir. polish.luau merupakan percobaan CSG yang ditolak, jangan dijalankan untuk hasil akhir. before.rbxl adalah backup lokal sebelum perubahan.

Lihat build.json untuk SHA place, cleanup dan status Git. Place disimpan setelah fixture dihapus, Edit/Test/satu pemain, kamera kembali ke pulau. Binary belum dibuka ulang untuk dibandingkan. Belum commit/push pada tugas ini.

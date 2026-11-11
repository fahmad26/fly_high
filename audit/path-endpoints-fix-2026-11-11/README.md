# Sambungan ujung A/E — 11 November 2026

Pemeriksaan visual sebelumnya hanya mengambil B/C. Walaupun driver berjalan lulus A–E, bentuk ujung A/E masih salah: cabang radial ditempel pada ujung busur sebagai simpang T, padahal jalur harus berbelok. Temuan pengguna membatalkan kesimpulan bahwa seluruh sambungan sudah rapi.

## Perbaikan

[Generator Edit](build-surface.luau) menggantikan generator path-seams-fix sebelumnya. Busur utama dihentikan di titik singgung; A/E memakai fillet radius tengah 5 stud dengan lebar 9 stud. Pusat fillet berjarak 75 stud dari pusat busur besar; titik singgung dan arah tangent dihitung dari geometri, bukan diisi patch persegi. Nat dan border mengikuti belokan, lalu menyambung ke akses lurus menuju dermaga. B/C/D mempertahankan jenis simpang tengah.

Collider jalan lama tetap aktif; dekorasi baru non-collision/query/touch dan anchored. [QA geometri](geometry-qa.json): 1.274 part visual, nol pelanggaran flag. Source gameplay, Terrain dan posisi dermaga tidak diubah. Belum ada benchmark perangkat fisik.

## Verifikasi akhir

Build, dirty files dan hash place ada di [build.json](build.json). Native Studio solo, satu klien, viewport default, jaringan lokal, unpublished mock.

| Dermaga | Bukti visual dekat | Uji berjalan |
| --- | --- | --- |
| A | [Belokan ujung](junction-a.jpg) | reached=true, CurrentPod=Pod_A, alive=true |
| B | [Simpang diagonal](junction-b.jpg) | reached=true, CurrentPod=Pod_B, alive=true |
| C | [Simpang tengah](junction-c.jpg) | reached=true, CurrentPod=Pod_C, alive=true |
| D | [Simpang diagonal](junction-d.jpg) | reached=true, CurrentPod=Pod_D, alive=true |
| E | [Belokan ujung](junction-e.jpg) | reached=true, CurrentPod=Pod_E, alive=true |

Foto A/E memperlihatkan tepi luar membulat dan seluruh lebar jalur menyatu, bukan dua persegi yang bersentuhan pada sudut. Semua gambar diperiksa langsung, bukan hanya diekspor. Banner HUD menunjukkan posisi avatar di E setelah driver selesai; nama file gambar mengikuti koordinat kamera/objek dermaga yang difoto, bukan banner avatar.

[Driver](walk.client.luau) dan [hasil mentah](walk-results.json): reset pose hanya di spawn sebelum setiap rute, berjalan melewati waypoint busur dan masuk dermaga. Tidak melompat atau teleport selama rute. Ini pengujian otomatis, bukan kenyamanan manusia/ponsel/variasi avatar.

[Console](console.json) hanya memuat informasi offline mock. Sebagian capture awal hanya menampilkan HUD; tidak dipakai sebagai bukti visual. Diagnostik Set3dRenderingEnabled ditolak kapabilitas dan tidak mengubah game. Pengaktifan jendela Studio melalui Computer Use memulihkan tampilan; capture akhir A–E berhasil. Tidak ada perubahan izin/security.

[Cleanup](cleanup.json): nol fixture, Edit/Test/satu pemain, viewport default dan kamera pulau. [Save](save.json) lokal berhasil; binary belum dibuka ulang untuk pembandingan. Belum commit/push.

Pencegahan: pemeriksaan jalan wajib mencakup setiap sambungan A–E, kedua ujung busur dan simpang tengah. Lulus uji berjalan tidak boleh menggantikan review visual. Capture kosong harus dianggap belum terverifikasi.

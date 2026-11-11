# Aturan pengerjaan, sinkronisasi dan bukti Fly High

Berlaku untuk setiap AI/developer. Dokumen ini menangani perbedaan Studio–Git, backlog yang tetap tertulis setelah diimplementasikan, serta klaim QA tanpa bukti atau dengan altitude berbeda.

## Pemilik informasi

| Informasi | Tempat pemeliharaan |
| --- | --- |
| Aturan produk | PRD_Fly_High.md |
| Keadaan workspace dan arsitektur | HANDOVER.md |
| Status fitur dan temuan | PROGRESS.md |
| Detail desain satu fitur | design/ atau katalog aset |
| Hasil uji per run | audit/ |
| Laporan lama | docs/ARCHIVE.md dan riwayat Git |

Baca AGENTS, HANDOVER, PROGRESS, lalu bagian PRD/desain terkait. Gunakan hanya skill yang relevan. Ringkasan lain merujuk ke pemilik informasi tersebut agar tidak muncul beberapa daftar status terbaru yang saling bertentangan.

## Sebelum edit

1. Jalankan git status. Catat branch, HEAD, origin/main lokal dan file yang telah berubah.
2. Temukan ulang Studio serta place. ID koneksi dapat berubah setelah aplikasi dibuka ulang.
3. Baca source dengan ScriptEditorService.GetEditorSource agar perubahan editor ikut diperiksa. Bandingkan dengan mirror dan HEAD.
4. Jika berbeda, periksa diff dan instruksi pengguna sebelum memilih acuan. Pengguna pernah memilih Studio sebagai acuan implementasi lokal. Pertahankan perubahan pengguna.
5. Perubahan generator GLB/PNG belum memperbarui place. Catat impor, unggah dan verifikasi hasilnya.

## Gerbang sinkronisasi source dan place

1. Terapkan perubahan pada implementasi yang dipilih dan salin ke mirror DataModel yang tepat.
2. Bandingkan semua source yang diubah. Sebelum klaim seluruh source sinkron, inventarisasi ketiga akar produksi dan cocokkan daftar path, class serta isi semua source.
3. Nyatakan normalisasi. Baseline dokumentasi memakai UTF-8, CRLF menjadi LF dan LF akhir dihapus, lalu membandingkan panjang byte dan hash rolling. Hash rolling hanya pemeriksaan pendamping. Diff isi atau hash kriptografis diperlukan untuk bukti kesamaan yang lebih kuat.
4. Periksa objek/properti terkait, termasuk Terrain, ukuran/pivot, collision, prompt, atribut dan StarterPlayer. Kecocokan source belum mencakup objek tersebut.
5. Hentikan Playtest, bersihkan fixture, simpan place melalui Studio, rekam SHA-256 file tersimpan serta waktu pengambilan hash.
6. Sebelum klaim isi binary place sama dengan Studio, buka ulang salinan file tersimpan di sesi pemeriksaan dan bandingkan ekspor source serta properti/model relevan. Jika belum dilakukan, tulis file tersimpan/hash dicatat dengan isi binary belum diverifikasi ulang.
7. Sesudah commit, verifikasi file tercakup dan status working tree. Sesudah push, verifikasi tujuan branch dan commit remote. origin/main lokal tanpa fetch/respons push baru hanya mencatat referensi lokal.
8. Perbarui HANDOVER dan PROGRESS. Baseline adalah snapshot bertanggal dan tidak berlaku otomatis setelah edit berikutnya.

Pisahkan istilah Studio cocok dengan mirror, file place tersimpan, commit tercipta dan push berhasil. Klaim sinkron Studio–mirror–Git menyebut commit serta file yang diperiksa.

## Gerbang bukti QA

Setiap run yang dipakai untuk status terverifikasi menyimpan catatan berikut dalam satu folder audit.

| Field | Isi wajib |
| --- | --- |
| Identitas | ID run, tanggal/waktu dan timezone |
| Build | Commit dasar, dirty files, hash source yang diuji, SHA-256 place bila tersedia |
| Lingkungan | Studio, jumlah klien, perangkat/orientasi/viewport, jaringan |
| Skenario | Target, langkah normal entry point, nilai aktual |
| Fixture | Altitude warp, shield, pause hazard, mock, percepatan atau input skrip |
| Bukti | Path screenshot asli dan log mentah per skenario |
| Hasil | Pass/fail/blocked, ekspektasi dan hasil aktual |
| Batas | Bagian belum diuji dan perubahan setelah capture |
| Cleanup | Fixture terhapus, Test, satu pemain, viewport default |

- Rekam altitude target dan altitude aktual terpisah. Nama screenshot atau angka bulat pada narasi tidak menggantikan pengukuran.
- Konflik historis 1.850/1.900 km tetap OPEN-03 sampai ada bukti yang tepat. Jangan memilih salah satu atau menganggap keduanya lulus.
- Jangan memakai screenshot pass awal sebagai bukti polesan berikutnya. Tuliskan tanggal/pass yang benar.
- Hasil yang hanya ada di chat diberi status dilaporkan di sesi. Ekspor bukti sebelum menaikkan status menjadi selesai terverifikasi.
- Raw report gagal tetap gagal meskipun rute mencapai puncak. Verifikasi terminal terpisah tidak menjadikan seluruh run end-to-end hijau.
- Simpan kegagalan fixture dan pengulangannya sebagai run berbeda. Pisahkan error alat, error game dan pesan mock, dengan log mentah tetap utuh.
- Source yang berubah setelah QA membuat bukti sebelumnya historis untuk source tersebut. Ulangi pemeriksaan relevan atau nyatakan batasnya.
- Jika Studio terputus atau QA gagal, tandai belum diverifikasi. Pembaruan dokumentasi tidak menghasilkan bukti gameplay baru.

## Progres dan penutupan

- Perbarui entri PROGRESS yang sama dengan implementasi, bukti dan sisa pekerjaan.
- Backlog yang sudah dibangun diubah menjadi implementasi tersedia. Buat kriteria QA tersisa yang jelas agar AI berikutnya tidak membangun ulang aset.
- Catat persetujuan visual, implementasi dan QA secara terpisah. Hindari persentase tanpa denominator serta kriteria yang disepakati.
- Hapus fixture runtime sesudah test. Pulihkan Edit / Test / satu pemain / viewport default dan simpan place.
- Commit/push bila diminta, dengan catatan file yang belum masuk commit.
- Sebelum menggabung/menghapus dokumen, pindahkan informasi unik, perbarui tautan dan simpan rujukan versi historis. Bukti mentah gagal tetap disimpan.

## Format penutupan pekerjaan

Perbarui satu baris fitur dengan catatan berikut; jangan membuat ringkasan “status terbaru” tambahan di dokumen lain.

```text
ID fitur/temuan:
Tanggal/waktu/timezone:
Perubahan dan kriteria penerimaan:
Build dasar + dirty files + hash source:
Studio ↔ mirror / binary tersimpan / commit / push: masing-masing hasil dan batasnya
QA: run ID, perangkat/viewport/klien, fixture, target dan hasil aktual
Bukti: path log dan screenshot yang tersimpan, atau “hanya dilaporkan di sesi”
Status: implementasi / verifikasi / temuan tersisa
Cleanup: fixture, mode Test, satu pemain, viewport default
Langkah berikut:
```

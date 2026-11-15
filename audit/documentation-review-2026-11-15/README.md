# Pemeriksaan dan perapian dokumentasi — 15 November 2026

Scope: dokumentasi dan berkas lokal, tanpa Studio, Playtest, cloud, commit atau push baru. Skill review Roblox dipakai untuk memisahkan aturan produk, implementasi dan bukti pengujian; tidak menjalankan skill gameplay/desain lain.

## Baseline yang diperiksa

- HEAD lokal main `969892d`, dengan referensi origin/main lokal sama. Tidak melakukan fetch/ls-remote, sehingga bukan verifikasi remote baru.
- Paket pekerjaan sebelumnya sudah tercakup pada commit lokal `80cdcaf`, `2c69bcf`, `2f71551`, `aecd1c7`, `969892d`; pernyataan belum commit/push pada run terdahulu bersifat historis.
- Mirror `audit/sources/` berisi 52 source. Place lokal 1.916.916 byte, SHA-256 `4C8CE3A5BFD3F9F1E549FF845DBF36038C862A9976A489812DEE235C848194D3` cocok checkpoint terakhir. Ini pemeriksaan disk, bukan bukti binary sama dengan Studio atau QA gameplay terbaru.
- [Baseline mesin](baseline.json) mencatat commit, status lokal sebelum tugas, hash place dan inventaris source. [Inventaris bukti](evidence-inventory.json) mencatat berkas yang benar-benar tersedia di setiap folder, bukan merekonstruksi hasil uji.

## Perubahan dokumentasi

1. Memperbaiki 12 tautan `../../sources/` menjadi `../sources/` pada [laporan tracker](../altitude-tracker-redesign-2026-11-14/README.md).
2. Mengganti urutan kerja yang masih menyebut desain Figma sebagai tahap sekarang pada [Daily Login/Koin](../../design/features/daily-login-and-coins/design.md) menjadi implementasi tersedia dan QA tersisa.
3. Menambahkan acuan Git terkini pada HANDOVER, menandai tabel baseline serta laporan lama sebagai historis, dan memperbarui DOC-01 di PROGRESS. Hash/build run lama dipertahankan.
4. Memberi penjelasan cakupan bukti pada 21 laporan tanggal 13–15 November. Semua 21 folder yang diperiksa berisi README dan screenshot, tanpa file log/manifest mentah terpisah (`json/jsonl/log/csv/txt`). Screenshot tetap bukti visual; klaim naratif parity/kompilasi/event tidak diperiksa ulang.
5. Menambahkan OPEN-07 untuk bukti QA mentah dan OPEN-08 untuk konflik 432/422 km. Klaim bahwa rekor pribadi benar pada run leaderboard tidak disahkan dari data yang bertentangan.
6. Mempertegas WORKFLOW: laporan historis tidak menentukan status HEAD, checksum rolling tidak disebut perbandingan exact, serta log lama tidak boleh direkonstruksi seolah bukti asli.

## Konflik yang tetap terbuka

**OPEN-07:** ekspor log asli bila masih dapat dipulihkan; jika tidak, jalankan ulang skenario dengan build/lingkungan/fixture serta log baru. Tidak ada log gameplay dibuat oleh tugas dokumentasi ini.

**OPEN-08:** narasi menyebut sekitar 432 km, papan menampilkan 422 km. Belum dapat menetapkan salah catat atau bug. PRD tetap maksimum ketinggian saat pemain hidup; uji ulang terkontrol 1.000→700 km dan nilai all-time/bulanan diperlukan. Tidak mengubah kode atau menyatakan 432 km sudah terkonfirmasi.

Multiplayer, perangkat fisik, cloud/Robux nyata, perjalanan penuh dan pembukaan ulang binary tetap mengikuti temuan/defer di PROGRESS. Pemeriksaan ini tidak menutupnya.

## Validasi

[Hasil validasi tautan](validation.json) menyimpan cakupan file dan tautan lokal yang rusak bila ada. Diff diperiksa untuk whitespace dan cakupan dokumentasi saja; file sumber Luau serta place tidak diubah. Backup lokal lama dipertahankan. Perubahan dokumentasi tugas ini belum di-commit/push.

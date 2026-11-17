# Mode tes pengguna sementara — 17 November 2026

**SUDAH DIKEMBALIKAN setelah pengguna selesai tes, 17 November 2026.** Mode tes tidak lagi aktif di Studio place 97043730132219. Catatan setup/QA di bawah bersifat historis. Baseline Git: `6f6dc64`, working tree bersih sebelum mode tes dipasang.

Rollback: ketiga source Studio diperiksa belum berubah sejak pemasangan patch, kemudian dipulihkan persis ke baseline dan lolos compile 3/3. Mirror kembali sama dengan HEAD (git diff source kosong). Workspace attribute `FlyHighUserTest` dihapus; Edit, 0 pemain, tidak ada fixture runtime. Inventory/progres persisten tidak diubah. Tidak dilakukan Playtest ulang yang mengakses profil asli, save place, publish atau commit. Bukti: [rollback-results.json](rollback-results.json).

## Perubahan

- Workspace attribute `FlyHighUserTest=true` (nilai awal: nil). Seluruh override juga mensyaratkan `RunService:IsStudio()`.
- BalloonManager: menolak `ApplyPuncture`, termasuk SelfShot dan Collision; kecepatan vertikal serta horizontal dikali 4. Pengali kru dan bonus Turbo tetap berlaku.
- DataManager: memakai jalur mock in-memory yang sudah tersedia selama mode ini aktif. Setiap sesi Play dimulai dengan Turbo Gas 1, Tali Awet 1, Emergency Kit 1, AKOwned 1, AKSlot1 true, slot kedua Handgun. Stok dapat dipakai seperti biasa dan direset saat Play berikutnya. Tidak mengubah profil akun asli.
- LeaderboardManager: memakai jalur offline selama mode ini aktif, sehingga hasil tes tidak ditulis ke ranking persisten.

Source asli dari Studio dicocokkan penuh setelah normalisasi LF/trimEnd dengan mirror sebelum edit. Salinan source asli ada dalam `baseline/`. Ketiga source sesudah edit dicocokkan penuh dengan mirror. Hash dan hasil runtime tersimpan dalam [results.json](results.json).

## QA

Windows Studio Solo, satu pemain Fikki2621. Ketiga source lolos compile. DataReady true; stok masing-masing 1 dan slot AK pertama true. Percobaan fixture pertama gagal mengukur gerak karena boarding belum selesai; laporan gagal tetap disimpan. Fixture kedua menunggu boarding, warp ke 1500 km, meng-anchor/membawa avatar untuk pengukuran 0,3 detik. Hasil: naik 69,07 km/dtk (target 66,67), horizontal 124,33 stud/dtk (target 120); selisih pengambilan sampel frame dalam toleransi 12,5%. Empat percobaan damage (Collision, SelfShot, WildBird, Tornado) ditolak, holes tetap 0. Console hanya menampilkan pesan mock, tanpa error.

Ini pemeriksaan terkontrol, bukan QA perjalanan alami penuh atau perangkat fisik. Angka pengukuran tidak mengubah pengali kode yang tepat 4. Play sudah dihentikan: Edit, 0 pemain, runtime fixture terhapus; flag Edit sengaja tetap true agar pengguna bisa mengetes. Viewport Edit tidak diubah melalui alat.

## Rollback setelah pengguna selesai

1. Hentikan Play. Ambil ulang source Studio dan mirror, bandingkan dengan hash patched di results.json; pertahankan perubahan lain jika sudah ada pekerjaan lanjutan.
2. Hapus attribute Workspace `FlyHighUserTest` (kembalikan nil). Restart Play diperlukan karena flag dibaca saat script mulai.
3. Jika source belum berubah lagi, pulihkan tiga source dari baseline/ ke Studio dan mirror. Jika berubah, balik hanya patch bertanda TEMP USER TEST: guard damage, pengali speed/steer, baris offline kedua manager, serta seed stok offline; jangan menimpa pekerjaan baru.
4. Verifikasi source, stok normal/profil asli, kecepatan dan damage kembali normal. Perbarui TEST-01 di PROGRESS dan catatan HANDOVER. Jangan mengubah inventory persisten untuk mencabut item mock.

Pengguna sudah memberi tahu tes selesai dan meminta rollback; prosedur di atas sudah dilaksanakan. Jangan memasang kembali atau mempublikasikan override sebagai balancing produksi.

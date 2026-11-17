# Bahasa Fly High

Sumber yang diedit: [id-en.json](id-en.json). Katalog ini berisi 493 pasangan Indonesia–English, termasuk 55 format dinamis. Jangan mengedit `LocalizationCatalog.luau` atau CSV hasil build secara terpisah.

Jalankan `node tools/build-localization.cjs` dari akar repo setelah mengubah katalog. Generator memeriksa sumber duplikat dan jumlah parameter. Urutan menentukan key `flyhigh_0001` dst.; tambahkan entri di akhir agar key lama tetap stabil. `%s`, `%d` dan format angka menjadi capture Luau serta `{arg1}` dst. di CSV. Pertahankan markup dan parameter; nama pemain pada label peran memakai capture mentah.

Setelan → BAHASA/LANGUAGE menyediakan Auto (Roblox), Bahasa Indonesia dan English. Auto memilih Indonesia untuk locale `id*`, English untuk locale lain. Pilihan berlaku pada klien untuk sesi berjalan, termasuk respawn; belum disimpan antar-sesi. Chat, nama pemain dan input teks tidak diterjemahkan.

`LocalizationController` memasang tabel native kecil hanya pada UI milik Fly High, papan lobby/istana dan overhead bertag. `Text` asli tetap Indonesia karena parser HUD lama membacanya; hasil render diterjemahkan melalui `RootLocalizationTable`. Untuk QA, lihat render/screenshot atau translator tabel, bukan menganggap `Text`/`ContentText` pasti berubah. Gambar dengan tulisan Indonesia memakai teks UI yang sudah tersedia saat English; ikon/bingkai tidak diganti.

`LocalizationService.FlyHighTranslations` dalam place berisi seluruh katalog. CSV cloud menggunakan kolom `en`; tabel runtime memakai locale `en-us` dan locale aktual klien. Tabel dalam game bekerja tanpa menunggu terjemahan cloud.

## Status Dashboard 17 November 2026

Kedua universe `10773510320` dan `10776821830`: source Indonesian, supported English; auto translation untuk Experience Strings & Products serta Experience Information aktif. Kode game belum dipublish pada pekerjaan ini.

Impor CSV penuh ke universe utama dua kali melaporkan `upstream request timeout`. Ekspor ulang terakhir menunjukkan 70 dari 490 key, dengan 70 nilai English cocok; 420 key belum ada. Persentase Dashboard 100% hanya mencerminkan sumber yang sudah masuk, bukan seluruh katalog. Universe privat belum menerima impor manual CSV. Ini pekerjaan cloud tersisa, bukan katalog lokal yang hilang. [Bukti dan batas QA](../../audit/localization-2026-11-17/README.md).

Jika mengulang impor, unduh tabel terbaru dahulu, strip UTF-8 BOM pada header, lalu bandingkan key/sumber/nilai `en`. Gunakan batch kecil jika layanan tetap timeout; periksa preview penghapusan = 0 dan jangan menghapus entri lain. Preview saja dan angka persentase tidak membuktikan impor berhasil. Simpan ekspor serta hasil perbandingan baru, tanpa menimpa bukti gagal.

# Terjemahan kalimat gabungan dan prompt touch — 18 November 2026

## Pengarsipan checkpoint

Implementasi, file place dan bukti run ini disertakan dalam commit yang memuat pembaruan dokumentasi 18 November. Nilai `committed: false` dalam JSON dan kalimat belum commit/push di catatan run merekam keadaan saat QA, bukan pemeriksaan Git setelahnya. Raw JSON tetap dipertahankan. Perapian dokumentasi tidak menjalankan Playtest baru atau Publish; hasil Git dilaporkan setelah commit/push diperiksa.

[Pemeriksaan sebelum commit](commit-preflight.json): generator 500/59 berhasil, 64 hash source masih cocok snapshot QA, tautan lokal delapan dokumen valid, draft Description 655 unit UTF-16 dan hash place tetap sama. Ini pemeriksaan file, bukan QA gameplay baru.

## Build dan perubahan

Dasar HEAD `1388ace3267c3231b29cfdcf9e1f4fce43fd777f`, working tree awal bersih. Studio privat universe `10776821830`, place `97043730132219`, sesi `99650554-bdcb-4c14-a8e9-8c4a9c4bf809`. Persetujuan: dua annotation pengguna berisi enam kelompok teks dan rencana prompt touch. [Desain disetujui](../../design/features/localization/design.md).

- Katalog 493 → **500 entri / 59 format**. Tujuh tambahan: fragmen target/menurun/notice bioma; `ZONA %d`; `Puncak ke-%d`; pembungkus `⚡ %s` dan `⚠ %s`. Format pembungkus menerjemahkan isi lewat mekanisme capture yang sudah ada; tidak melakukan penggantian kata bebas. Key lama dipertahankan, JSON/CSV/Luau dibangun bersama.
- `HUDInteractionPrompts`: touch tinggi 52→56, lingkaran 40→44, kotak teks tengah 32×20 dengan batas 9–11 px. TextScaled hanya pada label token touch. Transparansi, anchor, hold/progress dan eligibility server tetap sama. Desktop/gamepad tidak masuk cabang perubahan.
- Tabel `LocalizationService.FlyHighTranslations` ditambah tujuh entry; kini 500. Tidak mengimpor CSV ke Dashboard atau mengubah pengaturan cloud bahasa.
- Dua pesan Player:Kick native yang disebut saat audit tidak termasuk enam kelompok yang dipilih pengguna. Tetap pekerjaan terpisah; bukan dinyatakan sudah terlokalisasi.

## Bukti source dan penyimpanan

[Before parity](before-parity.json): ketiga source terkait sama dengan mirror sebelum edit. Snapshot `.before.luau` menormalkan newline akhir. Produksi hanya `LocalizationCatalog` dan `HUDInteractionPrompts` yang diedit; `Localization` tidak diubah.

[Manifest akhir](final-studio-manifest.json), [parity SHA-256](source-parity.json): 64/64 script compile dan cocok mirror setelah CRLF→LF/trimEnd. Probe hash mengikuti audit sebelumnya; rolling checksum hanya pelengkap. Cloud **v44** tersimpan tanpa Publish. File `Fly High.rbxl` disalin melalui Download a Copy setelah cleanup; [parse binary/hash](binary-source-report.json) mencatat 64 source binary cocok mirror. Binary belum dibuka ulang; tidak mengklaim seluruh properti place sama dari kecocokan source.

## QA yang benar-benar dijalankan

Play Solo Windows satu klien, locale akun en-us, PreferredTextSize Medium. Emulator iPad Pro M5 (13in) landscape viewport **1373×1030**, iPhone 17 Pro landscape **749×381**, desktop setelah menghentikan simulator **984×448,8**. Tidak mengubah preferensi ukuran teks akun.

1. [18 kasus string](strings-edit.json): enam kelompok, delapan kombinasi ikon/pesan buff, nama peran mentah, timer, harga dan daily; semua pass, versi Indonesia tidak berubah. Termasuk `Zone 1 · Reach Cloud Palace`, `Zone 2 · Descending!`, `✦ New biome · 2000 km`, `ZONE 1 · CLEAR SKIES`, dan `10,000 km · Summit #3 · 10:30`.
2. [Renderer native](native-rendered-examples.json): enam source contoh dipasang pada TextLabel tersembunyi di FlyHighHUD dan ditangani LocalizationController produksi, lalu diperiksa lewat translator RootLocalizationTable. Original Text tetap sumber; bukan mengubah parser gameplay. Ini fixture rendering, bukan perjalanan/cutscene natural.
3. iPad [English idle](tablet-en-idle.json), [hold](tablet-en-hold.json), [completion](tablet-en-complete.json), [Indonesia idle](tablet-id-idle.json). HOLD/TAHAN muat, TextScaled=true, lingkaran 44/tinggi 56, batas geometris teks+stroke berada di dalam radius lingkaran. [Gambar progress](tablet-en-hold.jpg).
4. Phone [Indonesia](phone-id-idle.json), [English](phone-en-idle.json), [hold/cancel/complete Indonesia](phone-id-states.json). Seluruh sampel muat dan aman dalam lingkaran; progress muncul saat hold/complete dan reset sesudah cancel. [Gambar Indonesia](phone-id.jpg).
5. [Desktop keyboard](desktop-keyboard-en.json): setelah input K yang tidak terikat gameplay dan prompt dibuat ulang, huruf E, lingkaran 34, tinggi 50, font 17, TextScaled=false — sesuai baseline cabang keyboard. Menghentikan simulator saja sempat tetap memakai input touch yang terakhir; hasil touch itu tidak dilabeli lulus keyboard.
6. [Console akhir](console.txt) kosong pada run terakhir. Fixture client `LocalizationTouchQA` (Part tak terlihat/ProximityPrompt RepairRopePrompt) dan `_QALocalizationSamples` dibuang sebelum stop. HoldDuration fixture 1,2/4 detik, memakai InputHoldBegin/End; tidak menjalankan reparasi server, pembelian, inventory, hadiah atau rekor.

Screenshot iPad diperkecil oleh tool capture (viewport aktual tercatat pada JSON), bukan screenshot perangkat fisik. Posisi prompt fixture berada dekat spawn, bukan balon terbang. Hanya keluarga RepairRopePrompt dipakai dalam runtime; token dan cabang touch merupakan renderer bersama, tetapi seluruh keluarga lain belum diuji satu per satu. Tidak mengklaim simulasi membuktikan iPad fisik atau ukuran teks akun Large sudah selesai.

## Percobaan dan batas

Percobaan awal [snapshot](prompt-attempt1.luau) dan [probe](touch-attempt1.json): TextWrapped=false setelah TextScaled=true menonaktifkan scaling. Ditemukan saat QA lalu dihapus; semua bukti final di atas berasal dari restart dengan versi yang dikoreksi. Error parsing respons node ketika menyiapkan patch terjadi sebelum edit Studio; patch berikutnya berhasil. Bukti awal tidak dipakai sebagai hasil final.

Pemakaian TextScaled membatasi label token tetap di ruang yang tersedia; dokumentasi resmi menyatakan TextScaled tidak mengikuti PreferredTextSize: [aksesibilitas Roblox](https://create.roblox.com/docs/production/publishing/accessibility). Ini dipakai khusus token singkat di lingkaran; bukan mematikan aksesibilitas seluruh HUD. Penyebab spesifik screenshot perangkat pengguna belum direproduksi pada iPad fisik.

Cleanup: Edit / IsRunning=false / default device / fixture bersih; Test/satu pemain tidak diubah. Belum commit/push atau Publish. Berikutnya: review fisik iPad, native disconnect localization, serta sisa impor CSV Dashboard yang sudah terbuka sebelum perbaikan ini.

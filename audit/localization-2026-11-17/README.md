# L10N-01 — Indonesia / English, 17 November 2026

## Checkpoint Git setelah QA

Commit yang memuat pembaruan dokumentasi ini mengarsipkan implementasi dan bukti di bawah. Sebutan belum commit/push pada run merupakan status historis ketika QA dilakukan. Tidak ada Publish atau Playtest baru pada checkpoint Git.

File lokal tersimpan ulang pada 17 November pukul 21:39 WIB: **3.523.944 B**, SHA-256 **1f2c35212637459699b53ba92a2da9616d9be77418eef6a7203729f61e779c16**. [Parse binary terbaru](commit-check/binary-source-report.json) menemukan 64 source cocok isi mirror dan checksum Studio QA, tanpa path hilang. Binary terbaru belum dibuka ulang; penyebab selisih 1.109 B belum diketahui. Manifest pembukaan ulang dan hasil runtime di bawah tetap mengacu pada binary `c5c1845c…`, bukan semua properti binary tersimpan ulang. File terbaru dipertahankan. Impor cloud tetap 70/490 utama dan belum manual pada privat; tidak diulang pada checkpoint ini.

## Build dan implementasi

Dasar Git `e8d5a43596903a119713688b1f8bbf35eaf9fe95`, working tree belum commit. Enam source baru/diubah: `Localization`, `LocalizationCatalog`, `LocalizationController`, `HUDImageAssets`, `HUDLayout`, `ShopClientController`. Tiga yang pertama baru. Katalog final 490 pasangan/55 format; 61 source produksi menjadi 64. [Desain disetujui](../../design/features/localization/design.md), [pemeliharaan katalog](../../assets/localization/README.md).

Pilihan Auto/id/en berada di header Setelan, langsung berlaku lokal. Auto mengikuti locale Roblox dengan fallback English. Nama/chat/input dikecualikan; Text sumber tetap utuh untuk parser legacy. Pilihan hanya sepanjang sesi. Tidak ada perubahan authority gameplay, checkout, grant inventory atau reward claim.

## QA runtime tersimpan

| Run | Lingkungan / fixture | Hasil / bukti |
| --- | --- | --- |
| Final 490 phone | Play Solo universe privat `10776821830`, iPhone 17 Pro landscape, viewport 749×381. Popup dibuka lewat fixture visibilitas, pilihan bahasa lewat input mouse tool pada tombol asli. | Lima popup tanpa `TextFits` gagal: [log](final-490-phone-modals-en.json). [English](final-490-phone-en.json), [Indonesia](final-490-phone-id.json), [gambar EN](final-490-phone-en.jpg), [gambar ID](final-490-phone-id.jpg). Kontrol picker 244×44; tombol header 98×44. |
| Final 490 prompt | Fixture lokal `workspace.LocalizationPromptQA` memunculkan custom repair prompt dalam emulasi touch. Tidak menjalankan repair server. | [Log](final-490-touch-prompt.json): TAHAN → HOLD, TAMBAL BALON → PATCH BALLOON dan detail diterjemahkan, muat. Fixture dihapus sebelum stop. Angka koma tetap dipertahankan (`0,4 sec`), belum diformat ulang menurut locale. |
| Final 490 reopened tablet | File lokal dibuka ulang, Play Solo GameId=0/data mock terisolasi, iPad Pro M5 (13in), viewport 1375×1030. Pilihan English melalui tombol asli; lima popup bergantian lewat fixture visibilitas. | [Lima popup](final-490-tablet-modals-en.json): issues kosong; [gambar Setelan](final-490-tablet-en.jpg). DataReady=true, tanpa pembelian/klaim. |
| Final 490 reopened desktop | Run lokal yang sama, device simulation dihentikan, viewport aktual 1066,4×536. | [Lima popup](final-490-desktop-modals-en.json): issues kosong. [Console](final-490-reopened-console.txt) hanya info data mock; tidak ada error game pada run ini. Desktop memiliki bukti layout numerik; screenshot final desktop tidak diekspor. |
| Pass 488 | Build antara sebelum dua entri terakhir TALI/Memuat… ditambahkan; layout/controller sama dengan final. | [Kasus dinamis, nama dan day code](final-488-cases.json), [1.000 update timer](final-488-lifecycle.json): tabel 176 sebelum/sesudah, satu entry pada objek timer. Bukti ini historis 488, bukan hasil run ulang semua kasus pada 490. |
| Pass 485 | Build awal sebelum lima entri tambahan. | `phone-landscape-*.json`, `tablet-*.json`, `desktop-en.json`, `portrait-stress-en.json`. Portrait hanya stress fixture 401×777; produksi tetap LandscapeSensor. Gambar pass awal yang hanya ada di chat tidak dipakai sebagai gambar final. |

Tidak menguji perjalanan penuh, transaksi nyata, perangkat fisik, semua frame hasil/cutscene, atau dua klien dengan bahasa berbeda. Auto locale id/fr dan override manual diperiksa melalui fungsi Resolve pada file dibuka ulang; locale akun Roblox tidak diubah untuk QA. Native-rendered screenshot final berasal dari akun locale en-us.

## Source dan checkpoint file

- [Manifest final](final-490-source-manifest.json) dan [parity SHA-256](final-490-source-parity.json): 64/64 class/path/hash normalized cocok mirror, 64 compile. Normalisasi CRLF→LF dan trimEnd. Luau SHA-256 probe melewati vektor abc/kosong, hash mirror dihitung terpisah oleh Node crypto; [probe](source-manifest-probe.luau). Hash rolling hanya pendamping.
- Studio cloud privat semula: `6adda177-a720-40b7-a9ae-95cace503005`. Save tool melaporkan TeamCreate/NotNeeded; tidak membuat versi/publish baru lewat tool itu. Salinan diambil melalui File → Download a Copy, mengganti file proyek lokal yang sudah ada.
- `Fly High.rbxl`: **3.522.835 B**, SHA-256 **c5c1845c15ff66c98c96dcbb1acc924bffc36f94cfa86ddebe3e5167c44a0e12**. [Hash setelah QA](checkpoint/file-after-qa.json).
- [Parse binary](checkpoint/binary-source-report.json): 64 source binary cocok mirror dan checksum Studio, tanpa path hilang.
- File tersebut **dibuka ulang** sebagai Studio lokal `3d87f210-d978-4073-b590-9a62f48007fb`. [Manifest](checkpoint/reopened-studio-manifest.json), [hasil perbandingan](checkpoint/reopen-report.json): 64 hash/class/path sama, semua compile, table 490/source id, default device, tanpa fixture. [Tabel dan fallback](checkpoint/reopened-table.json) mengonfirmasi sampel HOLD/Loading…/Choose a dock. Ini tidak membuktikan seluruh properti Terrain/dunia identik; tidak ada edit dunia dalam fitur ini.
- Commit/push belum dilakukan untuk lokalisasi; kode belum Publish ke pemain di kedua universe.

## Dashboard: konfigurasi selesai, impor manual belum lengkap

- Universe utama `10773510320`: [state bahasa](cloud-primary-language-final.txt): Indonesian + English, auto Strings & Products On, auto Information On.
- Universe privat `10776821830`: [state bahasa](cloud-private-language-final.txt): pengaturan sama, tidak mengubah visibility.
- CSV penuh: [attempt 1](cloud-import-attempt1.json) memakai header en-us, [attempt 2](cloud-import-attempt2.json) memakai en; keduanya `upstream request timeout`. Penyebab backend belum ditetapkan; tidak menyimpulkan header sebagai penyebab.
- [Ekspor pertama](cloud-primary-export.csv) hanya 50 key; [ekspor sesudah retry](cloud-primary-export-after-retry.csv), [verifikasi final](cloud-primary-final-verification.json): **70 key, 70 nilai en cocok, 420 key belum ada**. Parser membuang BOM sebelum mencari header Key. Angka 100% di UI tidak mewakili denominator 490.
- Percobaan preflight 50 entri berikutnya menunjukkan Added 0 / Modified 0 / Deleted 0 di sesi dan dibatalkan; tidak mengirim ulang no-op. `cloud-50-preflight.txt` hanya URL karena fokus UI, bukan log angka tersebut. Batch part1–5 tidak diunggah dan masih memakai header percobaan en-us; jangan menganggapnya hasil sukses.
- Universe privat: belum mengimpor CSV manual. Katalog lokal penuh tidak bergantung pada mirror cloud; lanjutkan impor batch kecil dan ekspor ulang saat layanan stabil jika ingin mirror manual lengkap pada keduanya.

## Riwayat kendala dan cleanup

Rekonsiliasi setelah sesi terputus: [snapshot](resumed-before/) dan [diff katalog](catalog-reconciliation.json) menunjukkan 485 entri lama tetap sama; dua patch milik pekerjaan ini diterapkan secara terarah, source lain dipertahankan. Error fixture `loadstring` client dicatat di [attempt 1](fixture-attempt1.txt), kemudian probe di-embed langsung. Pencarian path AlertFrame salah adalah error alat pada run antara, bukan produksi.

Panggilan native EncodingService.ComputeStringHash untuk abc tidak kembali dan cell dihentikan; diganti probe hash read-only di atas. Percobaan membaca binary terlalu cepat setelah dialog Save masih menangkap binary lama: [hasil gagal disimpan](checkpoint/binary-source-attempt-before-save-settled.json), diulang setelah mtime/ukuran berubah dan lulus. Cleanup sempat mencoba SetOrientationAsync saat device sudah default (ditolak API karena bukan mobile); ulang StopSimulationAsync dan pengecekan read-only lulus.

[Cleanup final](final-cleanup.json): Edit, IsRunning=false, 0 pemain lokal, device default, tanpa LocalizationPromptQA, tabel tetap 490/id. Mode Test/satu pemain tidak diubah selama QA ini. Tidak ada fixture produksi baru yang disimpan. Binary-source dump sementara dihapus setelah pemeriksaan; manifest/hash/raw hasil tetap disimpan.

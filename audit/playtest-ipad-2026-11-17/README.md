# Perbaikan playtest iPad — 17 November 2026, ±22:50 WIB

Laporan pengguna dari iPad (4 screenshot) berisi enam bug. Semua perubahan ada di Studio place cloud `97043730132219` (sesi `Fikki2621's Place: 11152026_1`). Place **belum disimpan** (tidak ada save cloud/lokal dari sesi ini), **belum commit/push/Publish**.

## Perubahan

| # | Masalah | Penyebab | Perbaikan | File |
|---|---|---|---|---|
| 1 | HUD kosong di atas saat mati; ping saat mati tidak jelas | `SpotHazardButton` dan raster panel `GhostSpotterFrame` sama-sama ZIndex 1. Raster dibuat belakangan sehingga menutupi tombol, dan panel terlihat kosong. Ping kru (QuickPing) dari arwah ditolak server tanpa umpan balik. | Tombol ZIndex 4. Ditambah strip penjelasan `GhostSpotHint` di bawah panel. Tombol PING / tombol V / D-pad saat arwah langsung menandai bahaya (GhostSpot), dengan umpan balik "Bahaya ditandai!" dan jeda 2 dtk. Banner ping bergeser 30 px. | `WeaponClientController`, `HUDLayout` |
| 2 | Teks ping keluar bingkai | Baris pengirim menempel di tepi atas (`topPad` = 17% tinggi) dan pesan memenuhi sisa tinggi, sehingga keduanya menabrak rim art 9-slice. | Blok dua baris dipusatkan di dalam rim (20% tinggi). Pengirim memakai `fitLine`. Tinggi banner 52/56 → 58/62. | `HUDTheme`, `HUDLayout` |
| 3 | Teks aksi custom keluar bingkai; progress tidak terlihat | Lebar kapsul tetap 196 px, tidak mengikuti teks (font/terjemahan di iOS lebih lebar). Progress hanya bar 2 px di bawah teks. | Lebar kapsul dihitung dari `TextBounds` judul/hint (min 150). Lingkaran tombol (TAP/TAHAN/huruf keyboard) kini menjadi gauge: isi teal naik dari bawah + ring teal selama menahan, dan kilat penuh saat terpicu. Bar 2 px dihapus. | `HUDInteractionPrompts` |
| 4 | Balon kena damage tabrakan padahal masih jauh | Kontak memakai silinder tetap 60 stud horizontal / 64 vertikal antar root. | `FlightSpace.Profile` mengukur siluet bagian terlihat per pita 4 stud dalam 16 arah sekali per penerbangan. `ContactDistance` menjumlah jangkauan kedua balon di sepanjang garis antar keduanya untuk pita yang tingginya tumpang tindih. Clamp dan damage memakai jarak ini. Hasil template: 37–47 stud (sebelumnya 60). Contoh Dawn↔Dawn: sejajar X 37,3; diagonal 40,4; beda tinggi 50 → 29,9; beda tinggi 60 → tidak bersentuhan. | `FlightSpace`, `BalloonManager` |
| 5 | Pemain jatuh saat balon bergerak (melompat / di atas balon) | Di lantai, humanoid mengikuti basket secara kinematik (kecepatan dunianya ≈0). Di udara tidak ada yang membawanya, sehingga balon bergeser 7–12 stud selama satu lompatan. | Client `PreSimulation`: saat Jumping/Freefall/GettingUp/FallingDown di dekat balon sendiri (radius 36, tinggi −8..72), karakter digeser sebesar kecepatan horizontal balon × dt. Dipakai kecepatan replikasi yang halus, bukan CFrame replikasi yang patah-patah. | `BalloonFleetAnimator` |
| 6 | Tombol LANGUAGE berantakan | Tombol 98×44 menimpa baris judul dan pil inventaris. | Tombol pindah ke baris preferensi sebagai tombol ke-4 ("Bahasa / Language"); otomatis 2×2 jika lebar < 380. Picker membuka ke atas, rata kanan dengan tombol. Judul memakai lebar penuh. | `HUDLayout`, `ShopClientController` |

Lokalisasi: 3 teks baru (hint arwah, jeda, konfirmasi tanda) ditambah ke `assets/localization/id-en.json` (key `flyhigh_0491..0493`). `LocalizationCatalog` dibangun ulang dengan `node tools/build-localization.cjs` (CSV dikembalikan ke LF seperti HEAD). `LocalizationService.FlyHighTranslations` di place ditambah 3 entri yang sama (493). Tiga entri baru ini belum diimpor ke cloud.

## QA (Play Solo Windows, Studio viewport 984×391, locale English, 1 klien)

- **Ping / arwah / setelan sebelum perbaikan:** [01](01-ghost-before.jpg), [02](02-ping-before.jpg), [03](03-settings-before.jpg).
- **Prompt:** kapsul menyesuaikan teks [04](04-prompt-autowidth.jpg). Progress tahan terlihat pada lingkaran, awal [05](05-prompt-hold-start.jpg) dan tengah [06](06-prompt-hold-mid.jpg). Fixture: prompt `RepairRopePrompt` buatan klien, HoldDuration 12, `InputHoldBegin`, lalu dihapus.
- **Banner ping** di dalam bingkai: [07](07-ping-after.jpg). Pengirim di y=13 dari tinggi 58.
- **Setelan:** 4 tombol satu baris [08](08-settings-after.jpg), picker bahasa [09](09-settings-language-picker.jpg).
- **Arwah:** panel "MARK DANGER" terbaca, strip penjelasan, dan banner arwah di bawahnya [10](10-ghost-after.jpg). Fixture: atribut klien `InFlight`/`FlightGhost` dan atribut banner diisi manual. Pengiriman GhostSpot ke server tidak diuji dalam penerbangan nyata.
- **Lompat di balon bergerak:** driver server menggeser `targetPosition` ±30 stud/s zig-zag (X tiap 1,2 dtk, Z tiap 2,1 dtk) pada ±400 stud, dengan pemain di BasketFloor dan `FlightJumpAllowed=true`. Drift take-off→mendarat:
  - sebelum: 5,0–9,2 stud (10 lompatan), satu kasus 26,6 stud dan pemain jatuh keluar;
  - sesudah: 0,2–2,5 stud (10 lompatan), pemain tetap di keranjang.
- **Catwalk:** berdiri di `Walkway8` selama kemudi zig-zag dan miring 4,5°, deviasi maks 1,9 stud. Proses panjat tali (winch) tidak teruji: solo pilot tidak bisa memasang tali.
- **Kontak balon:** dihitung dari template 5 skin (tabel di atas, Edit, clone sementara dihapus). Tabrakan dua balon nyata **belum** diuji karena butuh 2 pemain.
- Console server/klien: 0 error. 64 script compile. Tanpa `_QA*` di Edit. Mode Edit / 0 pemain.

## Parity source

Studio = mirror `audit/sources` (len + FNV-1a, normalisasi LF/trimEnd):

| Script | Len | FNV |
|---|---|---|
| HUDInteractionPrompts | 11826 | 84ce75eb |
| HUDLayout | 41182 | ba55355d |
| HUDTheme | 84671 | 5ee6751d |
| WeaponClientController | 48524 | be64d9ca |
| ShopClientController | 23177 | df336261 |
| BalloonFleetAnimator | 11466 | 81bbc140 |
| FlightSpace | 7254 | 9ce1670b |
| BalloonManager | 32005 | c083ec2a |
| LocalizationCatalog | 47393 | cc49a679 |

`Fly High.rbxl` lokal belum diperbarui. Simpan dulu lewat File → Save to File sebelum commit.

## Terbuka

- iPad/phone fisik: lebar prompt dan banner hanya diuji di viewport Studio. Font iOS bisa berbeda.
- Tabrakan dua balon nyata dan proses panjat tali pada balon yang bergerak (multi-pemain).
- Impor 3 key baru ke tabel cloud.

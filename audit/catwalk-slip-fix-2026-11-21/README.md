# Pemain terpeleset jatuh dari catwalk atas balon — 21 November 2026, ±01:15–03:00 WIB

Laporan pengguna: dengan karakter bertinggi normal atau cukup tinggi, pemain bisa terpeleset dan jatuh dari bagian atas balon (catwalk `EnvelopeRing`) saat berjalan untuk menambal lubang.

## Lingkungan

- Studio `3e658147-…`, place dibuka dari file lokal `Fly High.rbxl` (disimpan pengguna 20 Nov 22:04 WIB; sudah memuat perbaikan awan "es" dan air terjun yang dipulihkan). HEAD `d90e0e0`.
- Parity sebelum mulai: 67/67 source Studio = `audit/sources` (len + FNV-1a ternormalisasi).
- Play Solo Windows, 1 pemain, data mock. Fixture server sementara `_QA_Driver` (hanya di DataModel Play): pause obstacle, gas otomatis, kebal, lubang lewat `ApplyPuncture`, durabilitas tali tak habis, log posisi relatif balon per frame. Naik ke catwalk lewat `TetherEvent` `Attach` → `Climb` asli.
- Avatar: avatar pengguna (R15, HipHeight 4,46, tinggi ±9,8 stud) dan avatar blok R15 standar (HipHeight 2,0) lewat `ApplyDescription`.
- Input: `Humanoid:MoveTo` dan input keyboard sungguhan (W/A/S/D lewat ControlModule, kamera menghadap garis singgung ring).

## Penyebab

Catwalk adalah ring 16 papan (`EnvelopeRing.Walkway*`, r 14,5–17,5). Pagar pengamannya `BambooRigging.BambooGuard` adalah 16 dinding tak terlihat setinggi **2,5 stud** di r 17,3.

1. **Pagar lebih rendah dari pinggul avatar.** Kaki R15 tidak ber-collision. Sensor lantai Humanoid menganggap puncak pagar sebagai lantai bila berada dalam jangkauan HipHeight. Avatar pengguna (HipHeight 4,46) yang berjalan lurus otomatis naik ke atas pagar, lalu jatuh ke luar ring. Reproduksi: `MoveTo` searah garis singgung → HRP naik 28,77 → 30,55 (puncak pagar + pinggul), Freefall, `Hanging`.
2. **Balon miring ke arah engineer.** `engineerTilt` (r 16 → ±4,6°, ditambah kemudi pilot sampai ±10,3°) membuat muka dalam pagar condong ke luar. Sensor lantai lalu membaca muka itu sebagai pijakan dan "memanjat"-nya. Avatar blok standar terangkat sampai di atas pagar lalu jatuh, meskipun pagar sudah ditinggikan 10 stud. Pada kemiringan ≥6,8° avatar tinggi bahkan terangkat tanpa input. Tanpa kemiringan (orientasi dikunci di fixture) efek ini hilang: y tetap 25,7.
3. **Berjalan lurus di ring selalu bergeser ke luar**, menekan ke pagar dan memicu kedua mekanisme di atas.

`MaxSlopeAngle=40` saat di catwalk juga sudah dicoba, tetapi **tidak menghentikan** pengangkatan, sehingga tidak dipakai.

## Perbaikan (source, belum di-save/commit)

- **`ServerScriptService.FlyHighServer.TetherManager`:** `raiseCatwalkGuards(b)` dipanggil di `SetupBalloonTethers` saat launch, untuk semua varian balon. Setiap `BambooGuard` dibuat setinggi 10 stud dan berdiri di atas deck catwalk. WeldConstraint dimatikan sesaat agar hanya pagar yang bergeser, bukan seluruh assembly balon. Pagar tetap tidak terlihat, `CanQuery=false`, sehingga raycast senjata tidak terhalang. Template di ReplicatedStorage tidak diubah.
- **`StarterPlayer.StarterPlayerScripts.BalloonFleetAnimator`** (hanya aktif saat tahap tali = `Catwalk`):
  - **Pemandu input:** `BindToRenderStep` sesudah ControlModule. Di luar r 16,2, komponen input yang mengarah ke luar dibuang sehingga pemain mengikuti lengkung ring.
  - **Penahan:** di `Heartbeat`, HRP ditahan maksimal 0,6 stud di atas tinggi berdiri (deck + HipHeight + ½ HRP) dan r ≤ 16,9. Kecepatan relatif balon yang naik atau keluar dibuang. Jika HRP sudah >3 stud di bawah tinggi berdiri (jatuh sungguhan), penahan tidak ikut campur dan logika hang/rescue server tetap berjalan.
  - Penerbangan menonaktifkan lompat (JumpHeight 0), jadi di catwalk tidak ada gerakan naik yang sah.
  - Tinggi berdiri cadangan diambil dari payload `winchLanded="Catwalk"` (`localOffset.Y`).

Parity sesudah edit: 67/67 source Studio = mirror. `TetherManager` 27.433 B `de08cc38`, `BalloonFleetAnimator` 17.337 B `7572a9cb`.

## QA (Play Solo)

| Skenario | Sebelum | Sesudah |
|---|---|---|
| Avatar tinggi, `MoveTo` searah garis singgung (tilt 4,7°) | Jatuh di langkah pertama (naik ke puncak pagar 2,5) | 8 arah singgung + 4 dorongan keluar + 6 jalan antar-lubang: 0 jatuh |
| Avatar blok, dorong keluar (tilt 4,7°, pagar 10) | Memanjat muka pagar sampai y 35,4 lalu jatuh | — |
| Avatar tinggi, W ditahan (keyboard asli, tilt 4,7°) | — | Mengikuti ring −90° → −2°, r ≤ 16,75, y 28,0–29,2 |
| Sama, pemandu dimatikan sementara (hanya pagar 10) | — | Tidak jatuh, tetapi macet menekan pagar dan terangkat +1,4 |
| Avatar tinggi, tilt dinaikkan 4,7 → 10,3° tanpa input | Terangkat ke y 35 (berdiri di muka/puncak pagar) | y maks 29,1, r ≤ 16,85 |
| Avatar tinggi, tilt 10,3°, W/D/W+D/S/A/W+A ±31 dtk | Jatuh (versi tanpa penahan) | Keliling ring, r ≤ 16,84, y stabil, 0 jatuh |
| Avatar blok, tilt 10,3°, urutan input yang sama | — | Keliling penuh ring, r ≤ 16,55, y 24,8–26,1, 0 jatuh |
| Tambal lubang lewat `PatchPrompt` | — | Prompt aktif dari ring (jarak ±4,3), lubang tertambal (avatar tinggi dan blok) |
| `Descend` ke keranjang, `Detach` | — | Mendarat di keranjang (r 2,5) |

Console: tidak ada error skrip game. Pemulihan: Edit, 0 pemain, `TestService.NumberOfPlayers=1`, 0 instance/atribut `_QA*`. Template `BambooGuard` tetap 2,5 (diubah saat runtime saja).

## Batas

- Kemiringan 10,3° diuji dengan memaksa target `AlignOrientation` (fixture), bukan dengan pilot sungguhan. Belum ada uji 2+ klien, latensi, atau perangkat sentuh (thumbstick). Pemandu bekerja pada `MoveDirection`, jadi input sentuh dan gamepad melewati jalur yang sama, tetapi belum dicoba di iPad.
- Avatar yang diuji: avatar pengguna (HipHeight 4,46) dan blok standar (2,0). Avatar ekstrem (HipHeight >9) belum diuji; penahan tinggi tetap berlaku untuk semua avatar.
- Balon yang diuji: tema Pod_A. Varian lain memakai `EnvelopeRing`/`BambooGuard` dengan geometri relatif yang sama (dicek dari template).

## Checkpoint Git (ditambahkan 21 Nov 16:40 WIB)
Status di atas adalah status pada waktu run. Setelahnya, `Fly High.rbxl` lokal (`3.590.804` B) disimpan pengguna 21 Nov 16:16 WIB, SHA-256 `120a7ad6…71b59432`; parser offline: 67/67 source sama persis dengan mirror setelah normalisasi (LF, spasi akhir), objek/model belum dibuka ulang. Laporan ini dikonsolidasikan ke commit & push `main` 21 Nov.

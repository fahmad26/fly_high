# Jari viewmodel, AK-47 uji, HUD senjata, pulau kecil (21 November 2026, 15:56 WIB)

Permintaan pengguna (screenshot `01`–`03`):
1. "Tangannya sudah oke, tapi jarinya malah jadi aneh."
2. "Tolong kasih saya 1 AK-47 agar bisa saya testing."
3. HUD Reload/Release muncul tanpa senjata; HUD lain juga diaudit.
4. "Pulau-pulau kecil di pulau utama tampak terlihat aneh."

## 1. Jari (WeaponPresentation, `viewProfiles`)
- Penyebab: rantai jempol kedua tangan mengarah ke atas sehingga ujung jempol mencuat seperti cakar di tampilan 1P. Kamera 1P di-zoom dengan FOV 32 dari posisi mata yang sama (`10`, `12`):
  - Pistol: jempol kanan di kiri slide, jempol kiri di atas tangan kiri.
  - AK: jempol kanan mencuat dari bawah.
- Perbaikan:
  - Arah `thumbChain` keempat jempol dicari dengan grid search (3 segmen).
  - Syarat: tidak masuk mesh senjata (distance field) maupun jari tangan lain, ujung jempol ke depan (−Z), dan sedikit naik-turun.
  - Hasilnya: jempol rebah sejajar rangka (thumbs-forward). Pistol: kanan di sisi kiri frame, kiri di bawahnya. AK: kanan di sisi kiri receiver, kiri di bawah handguard.
- Hasil ukur: Pistol bad=2 inside=0, AK bad=0 inside=0. Tekuk pergelangan tidak berubah (Pistol R/L 34/30°, AK 30/35°).
- Bukti: `11`, `13`, Play Solo `14`.

## 2. AK-47 untuk pengujian
- Diberikan ke akun pengguna (Fikki2621, 8635452105) lewat jalur pembelian resmi: `DataManager.GrantReceipt(p, "QA_StudioGrant_AK47_20261121", "AK47Upgrade")`.
  - Dijalankan di Play Studio. Place sudah dipublikasikan, jadi DataStore yang dipakai adalah DataStore asli.
  - AKOwned 0 → 1. Receipt ID-nya sengaja diberi nama yang mudah dilacak.
- Slot 1 diatur ke AK-47 (`SetWeaponSlot(p, 1, "AK47")`) supaya langsung bisa diuji. Bisa diganti di Settings → Senjata.
- Diuji end-to-end di flight Play Solo:
  - Rak 1 menampilkan "Ambil AK-47".
  - Ambil → role Gunner, viewmodel muncul.
  - Tembak 30 → 29, reload kembali ke 30, drop → senjata kembali ke rak.

## 3. HUD Reload/Release tanpa senjata
- Penyebab (`StarterPlayerScripts.WeaponClientController`):
  - `onCharacter` dipanggil di baris 510, sebelum `isGhostNow` di-assign (baris 741).
  - Pemanggilan nil itu mematikan script: `WeaponClientController:500: attempt to call a nil value` di LogService client.
  - Akibatnya render step `FlyHighWeaponAim` tidak pernah terpasang, sehingga Reload/Drop (label RELEASE) tetap pada Visible bawaan = true. Ghost-spot arrows dan tombol tali (Attach/Pull/Detach/Climb/Descend) juga tidak pernah dibuat.
  - Bug ini hanya terjadi saat karakter sudah ada ketika script mulai (race).
- Perbaikan: guard `if not (isGhostNow and isGhostNow())`.
- Audit Play Solo setelah perbaikan, satu klien. LogService client tanpa error.

| Keadaan | HUD yang tampil |
|---|---|
| Lobby | Altimeter, Daily, Audio, Shop, Settings, Jump |
| Flight tanpa peran | + Status, EmergencyKit, Turbo, Rope, Ping, GroundedCountdown, ServerAltitudeTracker. Reload/Drop tersembunyi |
| Dekat stasiun tali | + AttachButton |
| Gunner (AK-47) | + Reload, Release, WeaponFrame, Reticle, Shoot |
| Setelah drop | Reload/Release/WeaponFrame tersembunyi lagi |
| Pilot | + Gas, AutoGas, ReleaseHelm, Jump tersembunyi (duduk). Reload/Drop tersembunyi |

Belum dicek: Ghost dan phone/tablet.

## 4. Pulau kecil (BiomeScenery, `CoastalIslet` di DawnArchipelago)
- Penyebab (`30`):
  - Kepala pulau dari IslandKit (batu + turf berbibir menggantung) berdiri 6–7 stud di atas laut.
  - Kepala itu duduk di atas `BeachMound` pipih (tinggi 3,2, puncak 1,95 stud di atas air y = 0).
  - Hasilnya terlihat seperti potongan pulau melayang yang diletakkan di atas piring pasir.
- Perbaikan:
  - `kitTopSwap` menerima `beachRise`. Islet memanggilnya dengan puncak turf `2.6 + width × 0.025` (±3,5–4,1 stud) dan `beachRise = 3`.
  - Kubah pasir kini berpusat di garis air, tinggi 6, lebar 1,35× tapak, sehingga naik landai dari laut sampai tepat di bawah tepi rumput.
  - Headland (`DawnHeadland`) tidak berubah.
- Bukti: `31` (dekat) dan `32` (dari pantai pulau utama).

## Status
- Parity Studio = mirror 67/67. Perubahan dibanding sesi sebelumnya:

| Script | len | FNV |
|---|---|---|
| WeaponPresentation | 71623 | `7b6a2b40` |
| WeaponClientController | 53280 | `6c76d08d` |
| BiomeScenery | 153863 | `cb6d5272` |

- Cleanup: Edit mode, `_QA_*` = 0, FOV kamera Studio kembali 70.
- Studio belum di-save/publish oleh Claude. Belum commit.
- Data akun pengguna berubah (AKOwned +1, slot 1 = AK-47) atas permintaan pengguna.

## Checkpoint Git (ditambahkan 21 Nov 16:40 WIB)
Status di atas adalah status pada waktu run. Setelahnya, `Fly High.rbxl` lokal (`3.590.804` B) disimpan pengguna 21 Nov 16:16 WIB, SHA-256 `120a7ad6…71b59432`; parser offline: 67/67 source sama persis dengan mirror setelah normalisasi (LF, spasi akhir), objek/model belum dibuka ulang. Laporan ini dikonsolidasikan ke commit & push `main` 21 Nov.

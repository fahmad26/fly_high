# Cutscene Istana Awan Fly High

Tanggal: 16 November 2026, Asia/Jakarta. **Status: konsep disetujui pengguna (23:29 WIB), belum diimplementasikan.** Status implementasi dan QA mengikuti baris CINE-01 di [PROGRESS](../../../PROGRESS.md). Aturan kemenangan tim yang mendasari ada di [flight-arrival](../flight-arrival/design.md).

## Keputusan pengguna

- Tiga cutscene: tiba di Istana Awan, kebangkitan kru yang gugur, dan turun lewat portal ke Pulau Awal.
- Durasi: tiba sekitar 8 detik, turun sekitar 6 detik.
- **Tidak ada versi singkat** (23:35 WIB). Setiap tayangan memakai versi lengkap.
- Kru yang gugur tetap seperti sekarang: dapat puncak (`AddSummit`), tidak dapat koin kedatangan `PALACE_ARRIVAL`.
- Cutscene turun memakai montase lima zona.

## Kondisi saat dokumen ditulis

Hasil inspeksi source Studio, read-only:

- **Tiba:** `BalloonManager.EndFlight(victory)` memanggil `PalaceArrival.Enqueue`. Antrean FIFO menggerakkan balon ke `CloudHavenDock` dalam tiga langkah (0,8 + 1 + 1 detik). Kru diturunkan di dermaga dan atribut `PalaceArrival` diisi, lalu balon naik 180 stud dalam 1,4 detik. Balon membawa atribut `ArrivalState` = `Queued` / `Docking` / `Departing`. Di klien, `PalacePresentation` langsung memindahkan kamera ke belakang pemain. `MusicController` memutar `PalaceIntro` lalu `PalaceLoop`.
- **Kru gugur:** selama terbang berstatus `FlightGhost`. Saat docking, server memanggil `LoadCharacterAsync` dan memindahkan karakter langsung ke dermaga tanpa transisi visual.
- **Portal:** `PalaceManager.ReturnPrompt` (tahan 0,3 detik) langsung memindahkan karakter ke `LobbySpawn`, mereset atribut, dan mengirim `FlightStateSyncEvent` altitude 0.
- `workspace.StreamingEnabled = true`.

## 1. Tiba di Istana Awan (sekitar 8 detik)

| Waktu | Adegan | Kamera dan efek |
| --- | --- | --- |
| 0–2 dtk | Menembus awan | Balon keluar dari lapisan awan terakhir; sudut rendah memperlihatkan istana utuh; musik `PalaceIntro` mulai |
| 2–5 dtk | Mendekat | Kamera mengikuti balon ke dermaga sambil berputar pelan; judul "ISTANA AWAN · 10.000 km" |
| 5–7 dtk | Mendarat | Balon menyentuh dermaga: kepulan awan, kelopak, bunyi lonceng; kru melangkah turun |
| 7–8 dtk | Penutup | Kartu ringkasan (waktu terbang, rekor, koin bila ada); kamera turun mulus ke belakang pemain, menggantikan snap `PalacePresentation` |

- **Saat `ArrivalState = Queued`:** kamera berputar mengelilingi istana sampai giliran tiba. Layar tidak boleh terlihat beku.
- **Sinkronisasi:** adegan 2–7 detik mengikuti `ArrivalState = Docking` dan posisi balon asli, bukan timer terpisah. Kartu penutup muncul setelah atribut `PalaceArrival` pemain terisi.
- **Selama cutscene:** HUD disembunyikan dan ada bar sinematik di atas dan bawah layar. Kontrol sudah dikunci oleh docking server.

## 2. Kru yang gugur bangkit di Istana

- Kru yang gugur (ghost) menonton cutscene tiba yang sama.
- Pada adegan mendarat, kolom cahaya emas dan bulu phoenix muncul dari keranjang. Karakternya terbentuk dari kabut awan di samping temannya.
- Teks: "Kru bangkit — kamu ikut sampai!"
- Kartu penutup pemain ini menyebut bahwa puncak tetap tercatat, tanpa menampilkan baris koin kedatangan.
- Efek kebangkitan terlihat oleh semua pemain di sekitar, bukan hanya di layar pemain yang gugur. Pemicunya kemunculan karakter baru yang berstatus bangkit, misalnya atribut `ArrivalRevived` dari server.
- Aturan hadiah tidak berubah.

## 3. Portal turun ke Pulau Awal (sekitar 6 detik)

| Waktu | Adegan | Isi |
| --- | --- | --- |
| 0–1 dtk | Masuk portal | Kamera mundur, awan berpusar, karakter larut menjadi cahaya |
| 1–4 dtk | Jatuh pulang (montase lima zona) | Menembus kosmik → senja → badai → langit → laut, masing-masing sekitar 0,6 detik, sebagai rekap perjalanan |
| 4–6 dtk | Mendarat | Tiba di dek kompas spawn dengan kepulan awan; kamera menukik dari atas lalu kembali ke belakang pemain; kontrol kembali |

- **Teleport sebenarnya:** terjadi di awal montase, tertutup kilatan putih. Server memuat area `LobbySpawn` lebih dulu (`RequestStreamAroundAsync`), lalu memindahkan karakter. Atribut dan sinkronisasi altitude tetap sama seperti `ReturnPrompt` sekarang.
- **Montase:** memakai latar warna/langit tiap zona (preset dari `BiomeLightingController`) dan lapisan awan atau partikel yang lewat. Tidak memuat ulang scenery penuh, agar ringan di ponsel.
- **Pemain lain:** di istana melihat kilatan portal; di lobby melihat pemain turun dengan kepulan awan.
- **Musik:** keluar dari fase istana mengikuti logika `MusicController` yang ada (posisi pemain di bawah `LOWER_WORLD_Y`).

## Aturan bersama

- **Tidak bisa dilewati** (keputusan pengguna 23:37 WIB). Di SETELAN ada sakelar **Cutscene Nyala / Mati**, bawaan Nyala. Kalau Mati, pemain langsung masuk ke kondisi akhir: kamera di belakang pemain di dermaga, atau langsung di lobby setelah portal. Tidak ada mode singkat.
- Kamera dan kontrol selalu dikembalikan bila cutscene error, pemain mati, koneksi putus, atau melewati batas waktu (durasi + 4 detik).
- Server tetap pemilik posisi, antrean dan hadiah. Cutscene hanya tampilan di klien: tidak menahan antrean `PalaceArrival` dan tidak dapat dipakai untuk curang.
- Di ponsel atau grafis rendah, jumlah partikel dikurangi dan bar sinematik dibuat lebih tipis.
- Suara cutscene (desir awan, lonceng, pusaran portal, pendaratan) masuk grup SFX. Musik tetap di `MusicController`.

## QA yang dibutuhkan

- Play Solo dan 2–3 pemain:
  - satu tim tiba;
  - dua tim antre bersamaan;
  - satu anggota gugur lalu bangkit;
  - pemain keluar di tengah cutscene.
- Sakelar SETELAN Nyala/Mati, kedua kondisi; pemulihan kamera dan kontrol pada setiap jalur gagal.
- Portal: karakter mendarat di dek kompas, lobby sudah ter-stream, musik berganti, pemain lain melihat efeknya.
- Perangkat mobile: frame rate selama montase dan ukuran teks kartu penutup.

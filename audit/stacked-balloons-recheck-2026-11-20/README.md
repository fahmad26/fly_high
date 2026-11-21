# Cek ulang bug balon bertumpuk — 20 November 2026, ±21:00 WIB

Pertanyaan pengguna: apakah bug ini masih terjadi? Bug: dua balon dekat atau hampir menempel atas–bawah, lalu pemain ngeglitch, tidak bisa jalan bebas, memegang kemudi, atau naik ke balon lewat tali. Perbaikannya dilaporkan di [five-bugs-fix](../five-bugs-fix-2026-11-20/README.md) (Bug 1).

Run ini **QA saja**: tidak ada perubahan source produksi, tidak ada save, commit, atau Publish.

## Lingkungan

- Studio `d297a000-…`, place dibuka dari file lokal `Fly High.rbxl`, HEAD `d90e0e0`.
- Parity: 67/67 source Studio = `audit/sources` (len + FNV-1a ternormalisasi).
- Play Solo Windows, 1 pemain (`Fikki2621`), data mock (place tidak terpublikasi). Obstacle dan LargeChallenge di-pause.

## Fixture

- **Balon tetangga B:** di-launch normal dari Pod_B, lalu krunya dilepas: koneksi Died/CharacterAdded diputus, `players={}`, status boarding dibekukan. B tetap ada di `activeFlights`, sehingga `CrewAccessGuard`, `ClampMovement`, dan barrier klien `Barrier_<balon>` tetap aktif terhadapnya. Barrier terverifikasi `CanCollide=true`.
- **B bergerak** secara kinematik dengan `PivotTo`: mengembara ±18/±12 stud horizontal dan ±3–4 stud vertikal, maksimal sekitar 16 stud/dtk, meniru kru lain yang mengemudi.
- **Balon pemain A:**
  - di atas B: target turun 4,2 stud/dtk, menekan B;
  - di bawah B: target naik 4,2 stud/dtk (laju gas asli).
  - Keduanya ditahan clamp server. Jarak tumpuk teramati dy 50–56 stud, yaitu atap menempel dasar keranjang.
- **Input pemain:** `Humanoid:MoveTo` ke titik keranjang dan ring catwalk. `HelmPrompt` dipicu lewat `InputHoldBegin`. Tali lewat `TetherEvent` `Attach` → `Climb` → (lap catwalk) → `Descend`.
- **Monitor teleport:** server mencatat lompatan posisi pemain >4 stud relatif balon A per frame.

## Hasil

| Skenario | Jalan di keranjang | Kemudi | Tali naik/catwalk/turun | Teleport server |
|---|---|---|---|---|
| A di atas, B diam (dy 52,4) | 6/6 titik tercapai, langkah maks 0,87 | duduk `HelmSeat` | Basket→Climbing→Catwalk | 0 |
| A di atas, B mengembara di bawah (dy 50,0–58,3) | 6/6, langkah maks 2,37 | duduk | Climbing→Catwalk, jalan ring, Descending→Basket, HP 100 | 0 |
| A di atas menekan turun, B mengembara (dy 50,4–54,5) | 4/4, langkah maks 2,47 | duduk | 1 lap penuh catwalk (20 langkah), 0 macet, relY 24,5–24,7, turun ke keranjang | 0 |
| A di bawah, B diam di atas (dy 60,4) | 4/4 | duduk | Basket→Climbing→Catwalk→Descending→Basket | 0 |
| A di bawah naik menekan, B mengembara di atas (dy 50,2–55,7) | — | — | >1 lap catwalk tanpa macet. Berakhir `Broken` di 16,4 dtk karena keausan tali di luar keranjang (mekanik normal), bukan karena B | — |

**Kesimpulan:** dalam fixture ini bug tidak lagi tereproduksi untuk pemain di balon atas maupun bawah.

## Catatan fixture

Satu run awal memakai target A yang langsung diset 30 stud di bawah B setiap frame. Akibatnya A melonjak ±12 stud saat B bergeser, pemain terlempar dari catwalk, lalu tergantung tali. Lonjakan seperti itu tidak terjadi di game (target hanya bertambah sesuai laju gas dan disetel ulang ke posisi clamp), jadi hasil ini dibuang dan diganti run berlaju realistis di atas. Run lain gagal respawn karena fixture B masih memegang koneksi `CharacterAdded` pemain; driver lalu diperbaiki dengan memutus koneksi tersebut.

## Batas

- Balon tetangga digerakkan kinematik tanpa kru dan klien kedua sungguhan. Belum ada uji 2 klien (StudioTestService), latensi jaringan, atau perangkat sentuh.
- Kemiringan balon tetangga akibat kemudi pilot nyata tidak disimulasikan.
- Temuan sampingan: dengan bahasa English, status kebal di panel kondisi masih tampil "KEBAL SERANGAN …" (Indonesia). Ini terlihat karena fixture kebal permanen; belum diperiksa lebih lanjut.

## Cleanup

Edit, 0 pemain, `TestService.NumberOfPlayers=1`, 0 instance/atribut `_QA*`. Source tidak berubah.

## Checkpoint Git (ditambahkan 21 Nov 16:40 WIB)
Status di atas adalah status pada waktu run. Setelahnya, `Fly High.rbxl` lokal (`3.590.804` B) disimpan pengguna 21 Nov 16:16 WIB, SHA-256 `120a7ad6…71b59432`; parser offline: 67/67 source sama persis dengan mirror setelah normalisasi (LF, spasi akhir), objek/model belum dibuka ulang. Laporan ini dikonsolidasikan ke commit & push `main` 21 Nov.

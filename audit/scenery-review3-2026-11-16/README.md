# Scenery round 3 — 16 November 2026, 20:06–20:20 WIB

Lanjutan dari [round 2](../scenery-review2-2026-11-16/README.md). Pengguna: "Oke bisa lanjut" untuk tiga sisa: jembatan dan gerbang lonceng Sunset, tumpukan awan di kanan Gateway, dan model kapal.

## Perubahan

### Gerbang lonceng (`ChimeGate`)
- Gaya torii: dua pilar bulat bernis merah, kasagi melengkung dengan ujung naik, shimaki, nuki, tiang tengah, alas batu, dan ujung kuningan.
- Menggantikan pilar, kapital, balok dan finial dari part dasar di `buildWindChimeRuin`. Bila template ada, lonceng digantung dari shimaki (Y 26, sebelumnya 24,2).
- Plinth, lentera dan lonceng tetap.

### Jembatan patah (`BridgeHalf`)
- Satu mesh setengah bentang: dek berlapis batu, balustrade dengan tiang dan baluster, cornice, cincin voussoir, spandrel, pier, dan ujung patah.
- Direntangkan sepanjang Z mengikuti `segLen` tiap sisi. Part dek, parapet, finial, voussoir, pier, relief dan batu jatuh yang lama dilewati.
- Strip emas jalan tetap dipertahankan.
- `EmbeddedApproach` dan `EmbeddedCliffButtress` dihapus pada versi mesh. Batu `ChasmRubble` di ujung juga dihilangkan, karena terlihat seperti kubus melayang.

### Pulau jangkar jembatan
- Pulau digeser 22 stud ke luar ujung jembatan. Sebelumnya pulau berpusat tepat di ujung, sehingga dek melintasi rumput dan menembus sakura.

### Awan Gateway
- `GoldenCloudTerrace` sekarang diberi jarak sudut emas (2,4 rad). Sebelumnya putarannya seperempat lingkaran per teras, sehingga tiap tier menumpuk jadi empat kolom.
- Menara awan di kanan jalur terbang hilang.

### Kapal langit v2 (CloudSailer, CloudKetch, CloudCutter)
- Lambung papan melengkung dengan lunas, haluan bowsprit, dek dan gunwale, serta kabin buritan.
- Tiang, yard dan boom, ditambah tali shroud dan forestay.
- Layar mengembung: layar kotak untuk Sailer, gaff untuk Ketch dan Cutter, serta jib.
- Lentera dan pita kuningan, plus bendera pada Sailer.
- Nama part dipertahankan: `SkyHull`, `SkyHullLight`, `SkySail`, `SkySailShade`, `SkyBrass`, `SkyPennant`. WorldPivot di origin dan warna disalin dari v1.
- Template lama disimpan di `ServerStorage.BiomeLandmarkMeshes_Legacy`.
- Perahu laut Dawn memakai template yang sama (skala 0,24).

## Aset dan generator

| Model | Aset | Generator |
|---|---|---|
| ChimeGate + BridgeHalf | 112587462648702 | `tools/build_sunset_kit2.py` |
| Kapal v2 | 90982189004528 | `tools/build_sky_ships.py` |

Semua aset Approved. Saat dipasang, tiap part diletakkan di pusat autornya lalu di-flip yaw 180°, sesuai catatan di `build_creatures.py`.

## Verifikasi

- **Fixture Edit:**
  - Kelima zona di-build tanpa error: 1.675 / 782 / 1.610 / 1.153 / 1.035 instance.
  - 4 perahu Dawn terbuat.
  - Fixture dibersihkan dengan 0 sisa, Lighting dikembalikan ke nilai file.
- **Play Solo:**
  - FlightStateSyncEvent 500→9.990 km tanpa error script.
  - Console menampilkan peringatan engine `No asset content representation` untuk dua image tertanam milik template `StormZone2` (TextureID 108393120847173 dan 85039044500479). Kedua image Approved dan berasal dari Batch 1 (15 Nov), jadi bukan dari perubahan putaran ini. Perlu ditindaklanjuti terpisah.
- **Penyimpanan:**
  - `save_place` pertama gagal karena koneksi (Target is not reachable). Pemanggilan kedua menjawab NotNeeded, lokasi **Cloud**. Studio kali ini dibuka dari Roblox, jadi perubahan masuk ke versi Cloud.
  - Pengguna lalu menjalankan File → Save to File (13:28 UTC). `Fly High.rbxl` kini 3.075.745 B, SHA-256 `84592554…61f45`.
- **Paritas Studio = file = mirror:** BiomeScenery 142517/`0b20587a`, BiomeLightingController 12590/`6e3839eb`. ObstacleArt dan ObstacleVisuals tidak berubah.
- **Belum diuji:** ponsel dan grafik rendah.

## Screenshot

- **Sunset:** `sunset_overview.jpg`, `sunset_chime_gate.jpg`, `sunset_bridge.jpg`, `sunset_bridge_before_anchor_fix.jpg`
- **Gateway:** `gateway_overview.jpg`, `gateway_ship.jpg`
- **Pratinjau kit:** `kit_gate_bridge_preview.jpg`

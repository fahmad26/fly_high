# Perbaikan temuan playtest — 17 November 2026

Laporan pengguna (10:56 WIB):
- pelindung Emergency Kit tidak pas di beberapa balon ([foto](00-report-shield.png));
- kapal bisa bertabrakan dengan balon ([foto](00-report-ship.png));
- rumput liar berantakan ([foto](00-report-grass.png)).

## Perubahan

| Temuan | Penyebab | Perbaikan |
|---|---|---|
| Pelindung tidak pas | `BalloonVFX` membuat `ShieldShell` sebagai Part `Ball`. Ball selalu bola sempurna, jadi tinggi kubah diabaikan: bola 44 stud memotong puncak amplop. Ukurannya juga diambil dari part `Envelope` tersembunyi, bukan skin yang terlihat (lotus/koi/saturn). | Shell sekarang Part Block + `SpecialMesh` Sphere (ellipsoid). Pas dengan geometri yang terlihat: titik ellipsoid-dalam untuk mesh bulat, sudut kotak untuk part block (keranjang/pagar). Margin 6% horizontal / 4% vertikal. Atribut `ShieldFit` mencatat ukuran. |
| Kapal menabrak balon | Rute `CloudKetch` di Gerbang Surgawi (±9.280 km) berpusat di (181, 118). Dengan lambung ±55 stud dan ayunan 36–44 stud, kapal masuk koridor terbang (\|x\|,\|z\| ≤ 120 + lebar balon). | Pusat rute digeser +100 stud di sumbu X → (281, 118). Jarak bebas sumbu X 181 stud dari batas koridor (sudah termasuk lambung + ayunan + margin 45). Kelima kapal lain sudah di luar koridor atau di atas plafon terbang. |
| Rumput berantakan | 16 petak Grass round 6 menumbuhkan rumput dekoratif tinggi yang menembus dek Pod dan jalan. | Petak dikembalikan ke LeafyGrass (507 voxel). Termasuk 24 voxel Grass asli yang kebetulan berada di dalam petak, jadi kini LeafyGrass. [Sesudah](06-lobby-grass-reverted.jpg) |

## QA

- **Pelindung:** Play Solo, 1 klien, driver sementara `_QA_ShieldDriver` (sudah dihapus). Kelima Pod diuji pada 600 km dengan `ShieldActive`/`ShieldUntil`; pelindung menyelimuti amplop, cincin dan keranjang: [A](01-shield-podA.jpg), [B lotus](02-shield-podB.jpg), [C koi](03-shield-podC.jpg), [D saturnus](04-shield-podD.jpg), [E lentera](05-shield-podE.jpg).
- **Kapal:** dicek secara numerik di Edit dengan scene Gateway dibangun (posisi, ukuran lambung, ayunan). Belum ada capture penerbangan nyata di 9.280 km.
- **Console:** LogService server dan klien 0 error/warning.
- **Edit:** 57 script lolos `loadstring`. 0 instance `_QA_*`. Kembali ke Edit / 0 pemain.

## Penyimpanan dan parity

- **Simpan:** Studio dibuka dari Roblox kali ini, jadi `save_place` menyimpan ke **Cloud versi 22**. File lokal `Fly High.rbxl` **belum** berisi perbaikan ini.
- **Mirror:** diperbarui dengan edit yang sama dan cocok dengan Studio:
  - BalloonVFX 43435 `511aada3`
  - BiomeScenery 153464 `7f08a6d5`
- **Perubahan non-script (Terrain):** hanya ada di Cloud v22 sampai file lokal disimpan ulang.

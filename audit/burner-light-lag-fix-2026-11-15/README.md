# QA Perbaikan Cahaya Api & Partikel Balon Tertinggal (`GAME-02` — 15 November 2026)

## Ringkasan akar masalah
Reproduksi langsung di Studio `Play Solo` (`Pod_C` / `SkyKoi`, `ClockTime = 0`, `Brightness = 0`) menunjukkan dua penyebab utama laporan pengguna (baik dengan maupun tanpa buff):
1. **`Lighting.LightingStyle` bernilai `Enum.LightingStyle.Soft`:** Evaluasi `PointLight` melalui voxel lighting throttle menjatuhkan/meninggalkan cahaya `Burner.BurnerLight` di belakang lantai keranjang ketika balon bergerak horizontal (`~20–30 stud/s`). Mengubah ke `Enum.LightingStyle.Realistic` menstabilkan `QualityLevel.Automatic`, **tetapi** saat `QualityLevel.Level01` (simulasi profil rendah iPad/mobile), Roblox tetap menjatuhkan/menggeser `PointLight` voxel ke sudut belakang saat bergerak.
2. **Emitter buff tanpa `LockedToPart = true`:** `TurboCoreJet`, `TurboEmberSparks`, `TurboIgnitionBurst`, `ShieldIdleMotes`, dan `KitPatchBurst` di `BalloonVFX` sebelumnya tidak mengunci partikel ke part, sehingga tertinggal di belakang balon saat bermanuver.

## Perubahan yang dipasang
1. **`Lighting.LightingStyle` -> `Enum.LightingStyle.Realistic`:** Diubah pada tempat `Fly High.rbxl` dan diverifikasi di Edit serta Play Solo siang/senja/malam.
2. **`ReplicatedStorage.FlyHigh.Modules.BalloonVFX` (`35.389` B disk / `35.388` B Studio, SHA-256 `0B884858D13BF6BC2143DB19B9FF5C898EAEDB2CAF94FDF0BAF03C9C01E24761`):**
   - Menambahkan overlay pendaran radial lantai keranjang berbasis geometri+UI sisi klien (`createDeckGlow` / `DeckBurnerGlowPlate`, `Size.Y = 0.01`, non-fisik `CanCollide/CanTouch/CanQuery/CastShadow = false`, terlas via `WeldConstraint` ke `RootPart` pada offset `basketTopY + 0.035` di atas seluruh papan lantai `0.629..0.630`).
   - Memakai `SurfaceGui` `NormalId.Top` (`LightInfluence = 0`, `AlwaysOnTop = false`, `ZOffset = 0.02`, `18` lapisan radial `GlowRing1..18`) terpusat di posisi `(X, Z)` relatif `Burner`, digerakkan oleh `BurnerActive`, `TurboActive`, serta bobot pencahayaan ambien (`Lighting.Brightness`) di `updateDeckGlow`.
   - Mengunci `LockedToPart = true` pada `ShieldIdleMotes`, `KitPatchBurst`, `TurboCoreJet`, `TurboEmberSparks`, dan `TurboIgnitionBurst` (tetap membiarkan `TurboWindStream` tidak terkunci agar garis angin tetap mengalir ke belakang).
   - Menambahkan culling client-side `PointLight` statis jauh (`FlyHighLobby.MatchmakingPods` & `CloudPalace`, radius `380` stud, refresh `0.5 dtk`) beserta `restoreStaticLights()` saat `BalloonVFX.Detach` mengosongkan tracker.

## Hasil QA pasca-edit final
- **Sinkronisasi source & kompilasi:** Mirror `audit/sources/` berjumlah `52` file (termasuk `BalloonVFX.luau` `35.389` B disk / norm `35.388` B == Studio `35.388` B) & `Play Solo` Windows `0` error runtime/kompilasi di `get_console_output`.
- **Verifikasi Lobby Edit (`LightingStyle = Realistic`):** [01-lobby-realistic-edit.jpg](01-lobby-realistic-edit.jpg) — pencahayaan laut, pulau, dan dermaga seimbang tanpa over-exposure.
- **Verifikasi `SkyKoi` (`Pod_C`) tanpa buff:**
  - Malam `QualityLevel.Automatic` bergerak `W` (`vel.Z = +19.38`): [02-skykoi-night-auto-moving-w.jpg](02-skykoi-night-auto-moving-w.jpg) (`14`-layer pass awal; pasca-revisi `18`-layer diuji lengkap pada `Level01`).
  - Malam `QualityLevel.Level01` bergerak `W` (`vel.Z = +19.38`): [03-skykoi-night-level01-aligned-moving-w.jpg](03-skykoi-night-level01-aligned-moving-w.jpg) — meski voxel `PointLight` pada `Level01` tidak menerangi lantai dari atas, lantai keranjang tetap diterangi pendaran hangat halus tepat di bawah burner (`GlowRing18` di `{0.389, 0}, {0.511, 0}`) tanpa cincin patah.
- **Verifikasi `SkyKoi` dengan buff (`ShieldActive` + `TurboActive`):**
  - Malam `QualityLevel.Level01` bergerak `A` (`vel.X = +19.42`): [04-skykoi-night-level01-buffs-moving-a.jpg](04-skykoi-night-level01-buffs-moving-a.jpg) — pendaran biru-cyan turbo di lantai tetap stabil di tengah keranjang di bawah kubah `ShieldShell`.
  - Siang `QualityLevel.Automatic` bergerak `S`: [05-skykoi-day-auto-buffs-moving-s.jpg](05-skykoi-day-auto-buffs-moving-s.jpg) — verifikasi `LockedToPart`: `TurboCoreJet = true`, `TurboEmberSparks = true`, `TurboIgnitionBurst = true`, `ShieldIdleMotes = true`, `KitPatchBurst = true`, `TurboWindStream = false`.
- **Verifikasi `PalaceLantern` (`Pod_E`) & walkability:**
  - Senja `QualityLevel.Level01` berdiri/berjalan di pusat lantai (`hrpFootY = 1.6`, `CanCollide/Query/Touch = false`): [06-palacelantern-dusk-level01-walk.jpg](06-palacelantern-dusk-level01-walk.jpg) — `0` Z-fighting, kaki/bayangan rapi di atas papan.
  - Senja `QualityLevel.Level01` naik `+19.4 km/s` bergerak `W`: [07-palacelantern-dusk-level01-moving-w.jpg](07-palacelantern-dusk-level01-moving-w.jpg).
- **Batasan & QA tersisa:**
  - Pengujian dilakukan di Windows Roblox Studio `Play Solo` (`1` klien `Fikki2621`, `PlaceId = 0`); belum diuji langsung di perangkat fisik iPad/mobile nyata atau multiplayer `2–3` pemain.
  - Pengujian culling `> 380` stud untuk `CloudPalace` pada ketinggian ekstrem terpotong oleh tarikan posisi balon ke server di skrip uji (verifikasi jarak `<= 263` stud serta pemulihan penuh `10/10` lampu dermaga dan `13/13` lampu istana sudah dikonfirmasi).
  - Status file tersimpan: [`Fly High.rbxl`](../../Fly%20High.rbxl) (`1.914.733` B, `2026-11-15T03:59:48+07:00`, SHA-256 `B656F2EFDE661B6C2A5F607331C750223DA3B61C9238D62ED0372CD5F27B37D0`, isi binary belum dibuka ulang; belum di-commit/push).

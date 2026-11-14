# Audit Motif Dinding Dalam Keranjang & Konsistensi Tema (14 November 2026)

## Identitas Build & Lingkup

- **Tanggal:** 14 November 2026 (Asia/Jakarta)
- **Git HEAD:** `f5aa15d` (working tree kotor; perubahan belum di-commit atau di-push)
- **Berkas tersimpan:** `Fly High.rbxl` (`1.740.880` byte, SHA-256 `F192F0B157747403DD08A9E06BB88EB1DB8376FD2E64D54BB28FD8AFAE1B7B05`)
- **Perubahan script:** `0` (`script_grep` memastikan `RailingNorth`, `GondolaCraft`, `WovenPanel`, `WoodPlanks`, `WaveTrim`, dan `GondolaDecor` tidak direferensikan langsung oleh script gameplay)
- **Cakupan template Studio (`ReplicatedStorage.FlyHigh.Templates`):**
  1. `HotAirBalloon`
  2. `BalloonVariants.DawnExplorer`
  3. `BalloonVariants.FloatingGarden`
  4. `BalloonVariants.SkyKoi`
  5. `BalloonVariants.SaturnVoyager`
  6. `BalloonVariants.PalaceLantern`

## Akar Masalah Sebelumnya

1. Konstruksi `GondolaCraft` (`audit/basket-polish-2026-11-11/build-baskets.luau`) hanya menempatkan motif (`WickerStrand`, `AccentRibbon`, `LeatherBinding`, `BindingStud`) ke sisi luar (`+LookVector`), meninggalkan sisi dalam (`-LookVector`) flat tanpa detail pada seluruh `6` template.
2. Pada `4` template (`HotAirBalloon`, `SkyKoi`, `SaturnVoyager`, `PalaceLantern`), kotak kolider `RailingNorth/South/East/West` masih berstatus `Transparency = 0` (`WoodPlanks` setebal `1.00` di `±13.00..±14.00`), sehingga menenggelamkan dinding oktagonal `GondolaCraft` (`±13.50..±13.88`) dan membiarkan `WaveTrim` (`SkyKoi`, menjorok hingga `Z = +13.30`) serta `Star` (`SaturnVoyager`, `Z = -14.10`) terlepas dari bidang dinding oktagonal.

## Implementasi yang Diterapkan

1. **Penyatuan visibilitas dinding oktagonal (`6/6` template):**
   - Menyetel `RailingNorth/South/East/West.Transparency = 1` sambil menjaga `CanCollide = true` di posisi `±13.00..±14.00` agar batas fisika pemain tidak berubah.
   - Menyelaraskan `LowerFrame` (`Z = 0.56` simetris di `depth = 0`) menjadi lis bawah di kedua sisi dinding.
2. **Motif dinding bagian dalam simetris & konsisten dengan isi keranjang (`116` part `Inner*` per template):**
   - `InnerWickerStrand` (`48` part: 6 baris horizontal di semua 8 sisi oktagonal pada `depth = -0.19`).
   - `InnerAccentRibbon` (`8` part pada `y = 3.75`, `depth = -0.21`) menggunakan warna aksen tiap varian agar serasi dengan `CompassRay` lantai dan aksen luar.
   - `InnerLeatherBinding` (`20` part: 5 sabuk vertikal pada 4 dinding panjang `24` stud di `x ∈ {-8, -4, 0, 4, 8}`, `depth = -0.23`), seirama dengan rangka kayu `WeaponRack1/2` dan tiang sudut.
   - `InnerBindingStud` (`40` part paku keling kuningan `0.11×0.11×0.11` pada `depth = -0.25`), menyambung aksen kuningan `DeckBorder`, `CompassRing`, `MastFerrule`, `WeaponRack`, `Wheel`, serta 4 lentera sudut.
3. **Harmonisasi material/warna & dekor tematik per varian:**
   - `HotAirBalloon` & `DawnExplorer`: mempertahankan anyaman hangat `Fabric (143,94,57)` + aksen oranye bakar `(211,133,73)`.
   - `FloatingGarden`: mempertahankan anyaman olive `(124,114,72)` + pita merah muda `(199,144,173)` selaras dengan bunga sudut dan `CompassRay`, dipadu sabuk cokelat & keling kuningan.
   - `SkyKoi`: panel `WoodPlanks (98,74,56)` & rusuk `Wood (130,96,66)` senada kursi helm/spool kenari gelap `(86,66,53)` dan dek jati; `22` `WaveTrim` luar dipendekkan/ditengahkan ke `Z = [-11.40..11.40]` (`X = ±13.94`) agar tidak melampaui sudut `CornerStile`, serta dicerminkan sebagai `22` `InnerWaveTrim` di `X = ±13.34` (bebas di belakang `WeaponRack1/2` `±12.14`).
   - `SaturnVoyager`: panel `WoodPlanks (46,56,94)` & rusuk `Wood (78,88,136)` senada helm, spool, teleskop, dan lantai biru malam `(42,50,86)` + pita periwinkle `(157,161,223)`; 2 model `Star` utara dipusatkan simetris ke `X = ±6.00, Y = 2.38, Z = -13.85`, ditambah 2 `Star` luar selatan (`Z = +13.85`) dan 4 `InnerStar` kuningan pada dinding dalam utara (`Z = -13.45`) serta selatan (`Z = +13.45`, bebas dari `Telescope` `X = 7.60..8.40` dan `Wheel` `X = ±1.17`).
   - `PalaceLantern`: panel `WoodPlanks (113,48,58)` & rusuk `Wood (148,70,78)` senada paviliun, helm, dan spool merah istana `(113,48,58)` dengan pita emas `(220,177,84)` senada lis paviliun dan lentera.
4. Seluruh part dekor baru (`Inner*`, `WaveTrim`, `Star`) memakai `Massless = true`, `Anchored = false`, `CanCollide = false`, `CanTouch = false`, `CanQuery = false`, `CastShadow = false`, serta `WeldConstraint` aktif ke `RootPart`.

## Hasil Verifikasi

### 1. Audit Struktural Mode `Edit` (`6/6` Template)
- `HotAirBalloon`: `inner=116, total=392, badF=0, badW=0`
- `DawnExplorer`: `inner=116, total=392, badF=0, badW=0`
- `FloatingGarden`: `inner=116, total=392, badF=0, badW=0`
- `SkyKoi`: `inner=138, total=414, badF=0, badW=0` (`WaveZ=[-11.40..11.40]`, sisi terdalam `InnerWaveTrim` di `±13.26` vs kolider `±13.00` dan `WeaponRack` `±12.14`)
- `SaturnVoyager`: `inner=120, total=396, badF=0, badW=0` (`InnerStar` di `X=[±5.19..±6.81]`, `Y=[1.61..3.15]`, `Z=±13.40..±13.50`, bersih dari `Telescope` `X=[7.60..8.40], Z=[-13.21..-9.79]`)
- `PalaceLantern`: `inner=116, total=392, badF=0, badW=0`

### 2. Pengujian Runtime & Visual `Play Solo` (`Pod_A` s.d. `Pod_E`)
- **Lingkungan:** `Play Solo` 1 pemain (`Fikki2621`) di Roblox Studio pada PC Windows, spawn melalui `FloorPad` + `StartPrompt`.
- **Hasil Server & Visual:**
  - `Pod_B` (`FloatingGarden`): `InnerCnt=116, BadFlag=0, BadWeld=0, RootY=12.50` — [Interior Fwd](PlaySolo_PodB_FloatingGarden_IntFwd.jpg), [Interior Back](PlaySolo_PodB_FloatingGarden_IntBack.jpg), [Exterior](PlaySolo_PodB_FloatingGarden_Ext.jpg)
  - `Pod_C` (`SkyKoi`): `InnerCnt=138 (ExtWave=22, IntWave=22), BadFlag=0, BadWeld=0, RootY=12.50` — [Interior Fwd](PlaySolo_PodC_SkyKoi_IntFwd.jpg), [Interior Back](PlaySolo_PodC_SkyKoi_IntBack.jpg), [Exterior](PlaySolo_PodC_SkyKoi_Ext.jpg)
  - `Pod_D` (`SaturnVoyager`): `InnerCnt=120 (IntStar=4), BadFlag=0, BadWeld=0, RootY=12.50` — [Interior Fwd](PlaySolo_PodD_SaturnVoyager_IntFwd.jpg), [Interior Back](PlaySolo_PodD_SaturnVoyager_IntBack.jpg), [Exterior](PlaySolo_PodD_SaturnVoyager_Ext.jpg)
  - `Pod_E` (`PalaceLantern`): `InnerCnt=116, BadFlag=0, BadWeld=0, RootY=12.50` — [Interior Fwd](PlaySolo_PodE_PalaceLantern_IntFwd.jpg), [Exterior](PlaySolo_PodE_PalaceLantern_Ext.jpg)
  - `Pod_A` (`DawnExplorer`): `InnerCnt=116, BadFlag=0, BadWeld=0, RootY=12.50` — [Interior Fwd](PlaySolo_PodA_DawnExplorer_IntFwd.jpg), [Exterior](PlaySolo_PodA_DawnExplorer_Ext.jpg)
- **Console Output (`get_console_output` saat Play Solo):** `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.` (`0` error gameplay).

### 3. Batas Verifikasi
- Template dasar `HotAirBalloon` diverifikasi pada data model `Edit` (tidak di-spawn di dermaga karena ke-5 dermaga memetakan `Pod_A..Pod_E`).
- Pengujian dilakukan dalam fixture 1 pemain desktop Windows; belum mencakup uji 3 pemain serentak maupun perangkat mobile/tablet.
- Place tersimpan ke `Fly High.rbxl` via `save_place`; file `.rbxl` hasil simpan belum dibuka ulang di sesi Studio terpisah, dan perubahan belum di-commit/push ke Git.

## Cleanup & Status Akhir

- `start_stop_play(is_start=false)` dijalankan: mode kembali ke `Edit`, `LingeringBalloons=0`, kamera dipulihkan ke `(0,48,25) -> (0,12,-55)` ([Edit_Cleanup_Final.jpg](Edit_Cleanup_Final.jpg)).
- `save_place` sukses (`Saved to the local place file`, `1.740.880` byte, SHA-256 `F192F0B157747403DD08A9E06BB88EB1DB8376FD2E64D54BB28FD8AFAE1B7B05`).

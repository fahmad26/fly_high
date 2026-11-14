# QA Report — Fix Lentera 4 Sudut Keranjang Balon (`14 November 2026`)

## 1. Identitas
- **Tanggal:** 14 November 2026 (WIB / Asia/Jakarta)
- **Lingkup:** Perbaikan lampu lentera (`Lantern*`) pada `GondolaCraft` di seluruh 6 template balon berukuran penuh agar terpasang simetris di keempat sudut tiang dan tidak lagi menembus/tumpang tindih dengan `SupportPole1..4`.
- **Perubahan:** 0 perubahan script Luau (template/model data saja dalam `Fly High.rbxl`):
  - `ReplicatedStorage.FlyHigh.Templates.HotAirBalloon`
  - `ReplicatedStorage.FlyHigh.Templates.BalloonVariants.DawnExplorer`
  - `ReplicatedStorage.FlyHigh.Templates.BalloonVariants.FloatingGarden`
  - `ReplicatedStorage.FlyHigh.Templates.BalloonVariants.SkyKoi`
  - `ReplicatedStorage.FlyHigh.Templates.BalloonVariants.SaturnVoyager`
  - `ReplicatedStorage.FlyHigh.Templates.BalloonVariants.PalaceLantern`
  - Miniatur dermaga `Workspace.FlyHighLobby.MatchmakingPods.Pod_A..Pod_E.DockDecor.PreviewBalloon` tidak diubah (`craft=0`; `Pod_E.PreviewBalloon` memiliki `lantern=4` dekorasi atap paviliun bawaan).

## 2. Build
- **Git `HEAD`:** `f5aa15d` (`working tree` kotor dengan perubahan sesi aktif yang belum di-commit/push).
- **Place tersimpan (`save_place` → `LocalFile`):** `Fly High.rbxl` (`1.738.843` B, SHA-256 `0F1749F68988B83EA8EE5EF5FA24F495CF3D5459B0ACF2D30E5244EA7A55BC76`).
- **Status binary:** Sudah disimpan dari Roblox Studio ke `Fly High.rbxl`, **belum dibuka ulang** ke sesi Studio baru; **belum commit / push**.

## 3. Lingkungan
- **Host:** Roblox Studio lokal (`studio_id=2aa6cbef-a4c5-43f8-a312-6b3f42eedd2d`, desktop viewport default).
- **Verifikasi model & geometri:** Mode `Edit` (`execute_luau`) pada seluruh 6 template balon.
- **Verifikasi runtime:** `Play Solo` (`Server` + `Client`, pemain tunggal `Fikki2621`) pada `Pod_A` (`DawnExplorer`), `Pod_B` (`FloatingGarden`), dan `Pod_E` (`PalaceLantern`).

## 4. Skenario
1. **Audit penyebab awal (`Edit`):**
   - Sebelumnya hanya ada 2 set lentera (`16` part `Lantern*`) di sudut belakang `(±11.90, 5.63, +12.00)` yang menembus langsung batang `SupportPole3` & `SupportPole4` (`0.60×10.00×0.60` di `(±12.00, 5.00, +12.00)`), sedangkan dua sudut depan `(±12, ?, -12)` kosong.
2. **Pembaruan 4 lentera sudut pada 6 template (`Edit`):**
   - Dihapus `16` part `Lantern*` lama per template (`totalCraft` turun sementara menjadi `236`) dan dibangun `40` part `Lantern*` baru (`totalCraft=276`), masing-masing `10` part di 4 sudut `(sx*12, sz*12)` dengan `sx, sz ∈ {-1, +1}`:
     - `LanternMountBand` (`0.76×0.16×0.76` di `(sx*12.00, 6.95, sz*12.00)` — cincin kuningan memeluk tiang sudut)
     - `LanternArm` (`1.16×0.11×0.11` Cylinder memanjang horizontal di `y=6.95` sepanjang bidang dinding samping `x=sx*12.00` menuju `z=sz*10.48`)
     - `LanternHanger` (`0.32×0.09×0.09` Cylinder vertikal `y=6.96..6.64` di `(sx*12.00, 6.80, sz*10.60)`)
     - `LanternGlass` (`0.60×0.80×0.60` Neon `(255, 224, 160)` di `(sx*12.00, 6.10, sz*10.60)`)
     - `LanternCap` × 2 (`0.88×0.18×0.88` di `y=5.63` dan `y=6.57`)
     - `LanternFrame` × 4 (`0.86×0.07×0.07` Cylinder di 4 sisi rangka lentera)
   - Seluruh `40` part `Lantern*` bersifat `Massless=true`, `Anchored=false`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `CastShadow=false`, serta di-weld aktif (`WeldConstraint` valid ke `RootPart`).
3. **Play Solo live (`Pod_A`, `Pod_B`, `Pod_E`):**
   - Pemain `Fikki2621` berjalan ke `FloorPad` masing-masing dermaga (`Pod_A`, `Pod_B`, `Pod_E`) dan menahan `StartPrompt` (`InputHoldBegin`/`0.45 dtk`/`InputHoldEnd`) hingga `Balloon_Fikki2621` ter-spawn, lalu diperiksa di `Server` dan ditangkap kamera interior/eksterior via `screen_capture`.

## 5. Fixture
- **Fixture uji:** Akun tester tunggal `Fikki2621` + pemindahan posisi & `Humanoid:MoveTo` ke `FloorPad` tiap dermaga serta aktivasi `StartPrompt` secara terprogram pada `Play Solo` (`Server` + `Client`).
- Tidak meninggalkan script sementara atau instance fixture di `Workspace`/`ReplicatedStorage` setelah selesai.

## 6. Bukti
- [play_podA_inside_wall.jpg](play_podA_inside_wall.jpg) — Interior `Pod_A` (`DawnExplorer`), memperlihatkan lentera sudut gantung bersih di samping `SupportPole` dan di atas `WeaponRack1`.
- [play_podA_both_wall.jpg](play_podA_both_wall.jpg) — Interior sisi berseberangan `Pod_A` (`DawnExplorer`).
- [play_podA_4corners_ext.jpg](play_podA_4corners_ext.jpg) — Tampak eksterior `Pod_A` (`DawnExplorer`), memperlihatkan beberapa sudut dengan lentera menggantung bersih pada lengan kuningan tanpa tumpang tindih dengan tiang/tali.
- [play_podB_interior_rear.jpg](play_podB_interior_rear.jpg) — Interior belakang `Pod_B` (`FloatingGarden`), kedua lentera sudut belakang terlihat simetris dan bersih.
- [play_podB_corner_closeup.jpg](play_podB_corner_closeup.jpg) — Tampak dalam `Pod_B` (`FloatingGarden`), 3 sudut terlihat jelas di atas ukiran bunga (`PetalCorolla`) tanpa tabrakan dengan bunga, tiang, rak senjata, kemudi, maupun tali suspensi.
- [play_podE_4corners_ext.jpg](play_podE_4corners_ext.jpg) — Tampak diagonal `Pod_E` (`PalaceLantern`), keempat lentera sudut terlihat bersamaan bersih di dalam keranjang.
- [play_podE_corner_closeup.jpg](play_podE_corner_closeup.jpg) — Close-up sudut `Pod_E` (`PalaceLantern`), cincin `LanternMountBand` + `LanternArm` + badan lentera bersih di bawah `PavilionCornice` tanpa menyentuh tiang, ring kuningan, tali, ataupun `LanternTassel`.

## 7. Hasil
- **Audit geometri & properti pasca-edit di `Edit` (`6/6` template):**
  - Seluruh 6 template (`HotAirBalloon`, `DawnExplorer`, `FloatingGarden`, `SkyKoi`, `SaturnVoyager`, `PalaceLantern`): `craft=276`, `lantern=40`, `glass=4`, `band=4`, `arm=4`, `badFlag=0`, `badWeld=0`.
  - Clearance badan lentera gantung (`LanternHanger`, `LanternGlass`, `LanternCap`, `LanternFrame`) terhadap tiang (`SupportPole1..4`), tali (`BasketSuspension`), dan dekorasi keranjang pada `y=2..10`:
    - `HotAirBalloon`: `bodyMinPole=0.660`, `bodyMinRope=0.813`, `bodyMinExtra=1.181`
    - `DawnExplorer`: `bodyMinPole=0.660`, `bodyMinRope=0.728`, `bodyMinExtra=1.181`
    - `FloatingGarden`: `bodyMinPole=0.660`, `bodyMinRope=0.692`, `bodyMinExtra=0.408`
    - `SkyKoi`: `bodyMinPole=0.660`, `bodyMinRope=0.275`, `bodyMinExtra=1.181`
    - `SaturnVoyager`: `bodyMinPole=0.660`, `bodyMinRope=0.427`, `bodyMinExtra=1.181`
    - `PalaceLantern`: `bodyMinPole=0.660`, `bodyMinRope=0.519`, `bodyMinExtra=0.735`
  - Catatan pemasangan: `LanternMountBand` memang membungkus `SupportPole` di sumbu sudut `(±12.00, 6.95, ±12.00)`, sehingga pada `PalaceLantern` cincin tersebut juga sejajar dengan bagian tengah `PavilionPost` (`±12, 4.75, ±12`) dan titik ujung bawah `LanternTassel` (`±12, 6.60, ±12`); badan lentera tetap menggantung bebas jauh dari dekorasi sudut.
- **Verifikasi `Play Solo` (`Server` + visual `read_file`):**
  - `Pod_A` (`DawnExplorer`): ter-spawn (`SPAWNED=Balloon_Fikki2621 glass=4 band=4 arm=4`), 3 screenshot interior/eksterior terverifikasi bersih.
  - `Pod_B` (`FloatingGarden`): ter-spawn (`craft=276 lanternParts=40 glass=4 band=4 arm=4 badLanternFlag=0 flowerParts=8`), 2 screenshot interior/sudut terverifikasi bersih di atas ukiran bunga.
  - `Pod_E` (`PalaceLantern`): ter-spawn (`SERVER_POD_E craft=276 lanternParts=40 glass=4 band=4 arm=4 badLanternFlag=0 cornice=4 tassel=4`), 2 screenshot eksterior 4 sudut + close-up sudut terverifikasi bersih.
  - **Console output (`Pod_E`):** `get_console_output` pasca-run bersih dari error/warning gameplay (`[DataManager] Unpublished Studio: isolated mock data; checkout disabled.` saja).

## 8. Batas
- Uji runtime `Play Solo` dilakukan pada `Pod_A` (`DawnExplorer`), `Pod_B` (`FloatingGarden`), dan `Pod_E` (`PalaceLantern`). Varian `HotAirBalloon` (template dasar tanpa pod dermaga langsung), `Pod_C` (`SkyKoi`), dan `Pod_D` (`SaturnVoyager`) baru terverifikasi pada level geometri, weld, dan flag `BasePart` di mode `Edit` (belum di-spawn live pada sesi ini).
- Pengujian dilakukan dalam sesi 1 pemain di Roblox Studio viewport desktop (belum uji multi-pemain 3 orang / perangkat phone & tablet fisik).
- File `Fly High.rbxl` sudah disimpan ke disk, tetapi belum dibuka ulang dari file untuk validasi reload binary.

## 9. Cleanup
- `start_stop_play(is_start=false)` dijalankan; `list_roblox_studios` mengonfirmasi mode kembali ke `Edit`.
- Pemeriksaan pasca-stop mengonfirmasi `LINGERING_BALLOONS=0` serta `PreviewBalloon` di `Pod_A..Pod_E` tidak tersentuh (`craft=0`).
- Kamera `Edit` dipulihkan ke `(0, 48, 25)` menghadap `(0, 12, -55)` dan diverifikasi secara visual.
- `save_place` dijalankan dan mengembalikan `status="Saved"` untuk `E:/Antigravity/Fly High/Fly High.rbxl`.

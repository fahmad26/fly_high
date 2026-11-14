# Laporan QA Revamp 5 Popup UI Sky Adventure (Anti-Penyok & Desain Konsisten)

## Ringkasan Pekerjaan

- **ID fitur/temuan:** `UI-01` / `UI-02` — Revamp konsisten seluruh 5 popup Fly High (`ShopModal`, `WeaponSettingsModal`, `AudioSettingsModal`, `TacticalPingWheel`, `HUDFlightResult`)
- **Tanggal/waktu/timezone:** `2026-11-14T19:54:17+07:00` (`Asia/Jakarta`)
- **Commit dasar & working tree:** `main` @ `f5aa15dc846f5ca842d1f5e22af0b7645fc4beca` (dirty files lokal termasuk pekerjaan sesi sebelumnya dan 7 script + 11 tekstur UI baru pada tugas ini; belum di-commit/push)
- **Place tersimpan:** [`Fly High.rbxl`](../../Fly%20High.rbxl) (`1.864.970` byte, SHA-256 `4D35210DF759E8FC99F43159B528FF7037197BDAECE17171472F48E1264445CB`); disimpan lewat `save_place`; binary `.rbxl` belum dibuka ulang untuk pembandingan pasca-tutup Studio.

## Aset Tekstur Baru (`11` Upload Studio RGBA Transparan)

Seluruh `11` PNG 2× diekspor tanpa kompresi ke [`assets/ui/sky-adventure/generated/popups/`](../../assets/ui/sky-adventure/generated/popups/) dan diunggah ke server aset Roblox melalui `Roblox_Studio:upload_image`, dicatat di [`roblox-texture-ids.json`](../../assets/ui/sky-adventure/roblox-texture-ids.json), serta dimuat di [`HUDAdventureCatalog.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDAdventureCatalog.luau) (`ContentProvider:PreloadAsync`: `11/11` ter-preload):

| Kunci Katalog | Ukuran (px) | Asset ID Roblox | Peran |
| --- | --- | --- | --- |
| `modal_frame_9slice` | `320×320` | `rbxassetid://128520511538894` | Bingkai modular 9-slice (`SliceCenter=(88,84,232,236), SliceScale=0.5`) untuk 4 popup utama + Banner Victory |
| `modal_frame_crimson_9slice` | `320×320` | `rbxassetid://92140063584149` | Bingkai modular 9-slice crimson untuk Banner `GAME OVER` |
| `btn_close_v2` | `104×104` | `rbxassetid://135218470357614` | Tombol tutup seragam `44×44` di sudut kanan atas semua modal (`x=mw-40, y=-2`) |
| `art_shop_kit_v2` | `280×208` | `rbxassetid://127952228739198` | Ilustrasi kartu `Emergency Kit` di `ShopModal` |
| `art_shop_ak_v2` | `280×208` | `rbxassetid://100335780143414` | Ilustrasi kartu `AK-47 Permanen` di `ShopModal` |
| `crest_shop` | `408×168` | `rbxassetid://132703168027932` | Top Crest medallion melayang (`408:168`, rasio terkunci) untuk `ShopModal` |
| `crest_weapon` | `408×168` | `rbxassetid://119885716932475` | Top Crest medallion melayang untuk `WeaponSettingsModal` |
| `crest_audio` | `408×168` | `rbxassetid://116191139616419` | Top Crest medallion melayang untuk `AudioSettingsModal` |
| `crest_ping` | `408×168` | `rbxassetid://110295344239333` | Top Crest medallion melayang untuk `TacticalPingWheel` |
| `crest_victory` | `408×168` | `rbxassetid://89497309661961` | Top Crest medallion melayang untuk `HUDFlightResult` (`TIBA DI ISTANA AWAN!`) |
| `crest_gameover` | `408×168` | `rbxassetid://112714743057777` | Top Crest medallion melayang untuk `HUDFlightResult` (`GAME OVER`) |

## Implementasi & Sinkronisasi Source (`45` source produksi)

Seluruh `45` script pada ketiga akar produksi Studio lolos kompilasi `loadstring` (`scriptCount=45, compileFail=[]`) pasca-edit final. Ketujuh script yang diubah cocok identik antara Studio `Edit` dan mirror `audit/sources/`:

| Script | Class | Panjang Studio (B) | Adler-32 Studio | SHA-256 Disk (LF) | Kecocokan Studio ↔ Disk |
| --- | --- | ---: | ---: | --- | --- |
| [`HUDAdventureCatalog.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDAdventureCatalog.luau) | `ModuleScript` | `4.626` | `457426601` | `467c62dd5c9f3e8045012a0c70a7a427b224d96937d588d085493d0c4e2ee37c` | Identik penuh (`EXACT_LF`) |
| [`HUDAdventureArt.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDAdventureArt.luau) | `ModuleScript` | `4.997` | `1972006524` | `e690be45a771efe8b67b2c59f2e59872c5083eadf5d1b9114631cc52d1078beb` | Identik penuh (`EXACT_LF`) |
| [`HUDMotion.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDMotion.luau) | `ModuleScript` | `53.668` | `3152839898` | `a57d9bf186a8679c79684b0ab3f943e186aa0e6ff0fbe75808a57ad437fc16d2` | Identik penuh (`EXACT_LF`) |
| [`AudioSettingsModal.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/AudioSettingsModal.luau) | `ModuleScript` | `14.903` | `1940369445` | `f471f17162b53596e6c06b8e03584b80e7635b21d31d2aebf5276ce4da70c381` | Identik pasca-trim 1 trailing newline (`TRIM_NL`; disk `14.904` B / `602255407`) |
| [`HUDLayout.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau) | `ModuleScript` | `25.707` | `3665907942` | `918e59f3ac2046f955661ed3d9c24c19d0fc92cdad0e51d936896fbafefab471` | Identik penuh (`EXACT_LF`) |
| [`HUDTheme.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau) | `ModuleScript` | `75.717` | `160631245` | `ea89a37f7177833c4c7d8a35d2c0a4e54a22759732fb378552e528aea9e290bc` | Identik penuh (`EXACT_LF`) |
| [`ShopClientController.luau`](../sources/StarterPlayer/StarterPlayerScripts/ShopClientController.luau) | `LocalScript` | `19.405` | `2019533385` | `a6838420e7542760da6673260065f4ac0f539ab56567b183c65398251a1dca65` | Identik penuh (`EXACT_LF`) |

## Ringkasan Desain & Perbaikan Akar Masalah

1. **Penghapusan Distorsi / Penyok (`HUDAdventureArt`, `HUDLayout`, `HUDTheme`):** Mengganti latar gambar tunggal penuh (`shop_panel` / `ping_panel`) pada popup dengan `modal_frame_9slice` / `modal_frame_crimson_9slice` (`ImageRectSize = Vector2.zero`, `ScaleType = Slice`, `SliceCenter = Rect.new(88, 84, 232, 236)`, `SliceScale = 0.5`) melalui helper `placeModalFrame` (`HUDLayout`) dan `applyModalChrome` (`HUDTheme`), sehingga sudut bezel gold-cyan dan lengkungan bawah tidak pernah meregang gepeng pada rasio layar apa pun. Top Crest medallion (`408:168`, rasio terkunci) dan `btn_close_v2` (`44×44` straddling top-right bezel) seragam di semua popup.
2. **Perbaikan Akar Masalah Visual Audio & Fill Tombol (`AudioSettingsModal`, `HUDTheme`):**
   - Menghapus bitmap `progress_track`/`progress_fill` yang membocorkan tepi kuning pada `Music Volume`; menggantinya dengan track vektor bersih `#061632` + `FILL_GRADIENTS` (`Master`/`Music`/`SFX`/`MUTED`) + ikon merah mute (`BISU`) + `AudioFooterHint`.
   - Memindahkan fill & gradient tombol pembelian `ShopModal` (`BuyEmergencyKitButton`, `BuyAK47Button`) ke child Frame `HUDCtaFill` dan kartu baris `Ping1..5` ke child Frame `HUDPingFill` di dalam `HUDMotionVisual` agar tidak tertimpa `HUDMotion.Capture()` (`r.host.BackgroundTransparency = 1`), serta mengubah `HUDCardBadge` menjadi `Frame` + `HUDCardBadgeText` agar border pill dan teks badge tetap tajam.
3. **Banner Victory & Game Over (`HUDTheme`, `HUDMotion`):** Mengupgrade `HUDFlightResult` dengan `modal_frame_9slice` + `crest_victory` (`TIBA DI ISTANA AWAN!` + pill `✓  PENERBANGAN SUKSES`) dan `modal_frame_crimson_9slice` + `crest_gameover` (`GAME OVER` + pill `BALON HANCUR  ·  COBA LAGI`), serta memperbarui pencocokan di `HUDMotion` menjadi case-insensitive `:lower():find("istana awan", 1, true)` agar burst bintang & chime tetap menyala.

## Hasil QA

| Cek / Run | Status Terhadap Edit Final | Lingkungan & Fixture | Hasil Aktual | Bukti |
| --- | --- | --- | --- | --- |
| **Boot & Console Play Solo** | Pasca-edit final | Play Solo Windows `1` klien (`2090×694`) | **PASS** — Hanya `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.` (`0` error/warning gameplay) | Log Studio `get_console_output` |
| **Popup `ShopModal` (Desktop)** | Pasca-edit final | Play Solo `1` klien (`2090×694`) | **PASS** — `shop=(600×468)`, `crest=(165×68)` proporsional, `fill1_bgT=0` (tombol emerald glossy), `badge1_bgT=0, TextFits=true` (`SEKALI PER TERBANG` / `PERMANEN · RAK SETELAN`), `art_shop_kit_v2`/`art_shop_ak_v2` tajam, jarak bawah bersih | [qa_shop_desktop.jpg](qa_shop_desktop.jpg) |
| **Popup `TacticalPingWheel` (Desktop)** | Pasca-edit final | Play Solo `1` klien (`2090×694`) | **PASS** — `ping=(460×476)`, `pfill_bgT=0` (`Ping1..5` bergradient biru dongker utuh + label Indonesia lengkap + ikon warna + shortcut `[1]..[5]` + footer) | [qa_ping_desktop.jpg](qa_ping_desktop.jpg) |
| **Popup `WeaponSettingsModal` (Desktop Default)** | Pasca-edit final | Play Solo `1` klien (`2090×694`, Lobby) | **PASS** — `500×448`, `InventoryCount` `13px`, `Rak 1`/`Rak 2` (`✓ Handgun` emerald vs `AK-47` slate), `Nama: Tampil` + `Animasi: Penuh` cobalt, footer berjarak aman | [qa_weapon_desktop.jpg](qa_weapon_desktop.jpg) |
| **Popup `AudioSettingsModal` (Desktop Default 100%/60%/100%)** | Pasca-edit final | Play Solo `1` klien (`2090×694`) | **PASS** — `Master 100%`, `Music 60%`, `SFX 100%`, zero artefak ujung kuning di track slider, `AudioFooterHint` `12px` | [qa_audio_desktop.jpg](qa_audio_desktop.jpg) |
| **Banner `HUDFlightResult` Victory & Game Over** | Pasca-edit final | Play Solo `1` klien (`2090×694`), fixture `StatusFrame.HolePenalty.Text` `"Tiba di Istana Awan!"` lalu `"GAME OVER"` (dibersihkan setelah uji) | **PASS** — `TIBA DI ISTANA AWAN!` (`crest_victory` + `modal_frame_9slice`) & `GAME OVER` (`crest_gameover` + `modal_frame_crimson_9slice`), tanpa tabrakan crest/teks/pill | [qa_result_victory_desktop.jpg](qa_result_victory_desktop.jpg), [qa_result_gameover_desktop.jpg](qa_result_gameover_desktop.jpg) |
| **Bus AudioMixer & Scrim Guard Penuh** | Pasca-edit final | Play Solo `1` klien (`2090×694`) | **PASS** — `Master=0.30, Music=0.20, SFX=0.50` menghasilkan bus `(0.300, 0.060, 0.150)`; mute Music -> `0.000`; dipulihkan ke `(1.000, 0.600, 1.000)`; keempat popup memunculkan `HUDModalScrim` `2090×752` di `y=-58` & tombol close `44×44` | Output sesi Play Solo |
| **Evaluasi Geometri Multi-Viewport** | Pasca-edit final | Simulasi metrik layout dari formula `HUDLayout` di Play Solo untuk Desktop (`2090×694`), Tablet (`1024×768`), Phone Portrait (`390×844`), Phone Landscape (`844×390`) | **PASS** — `issues=[]` pada ke-4 viewport; Phone Portrait `ShopModal` beralih ke `vertical_stack` (`366×492`, card `326×161`, btn `h=44`); Phone Landscape `TacticalPingWheel` beralih ke `2col` (`620×344`, `btnH=54`) | Output sesi Play Solo |
| **`WeaponSettingsModal` Locked InFlight & `AudioSettingsModal` Muted (`BISU`)** | Pra-final edit visual non-audio/non-lock (`HUDTheme` minor patch sesudahnya tidak mengubah alur ini) | Play Solo `1` klien sebelum edit terakhir `HUDTheme` (`InFlight=true, ReduceHUDMotion=true`; `AudioMixer.SetMuted Music=true`) | **PASS (sesi sebelum edit minor akhir)** — `🔒✓ Handgun`, `Animasi: Ringan`, catatan `"Senjata terkunci saat terbang."`, serta bar `Music` abu-abu + tombol crimson + teks `BISU` tampil bersih | [qa_weapon_locked_desktop.jpg](qa_weapon_locked_desktop.jpg), [qa_audio_muted_desktop.jpg](qa_audio_muted_desktop.jpg) |
| **Pemulihan Edit, Parity `45/45` & `save_place`** | Pasca-edit final | `Edit` mode, `Fly High.rbxl` | **PASS** — `playersInEdit=0, sgCount=0, leftover=[], compileFail=[], camPos=[0,48,25]`; `45/45` script kompilasi OK; `7/7` file ubahan cocok Studio ↔ mirror (`6` exact LF, `AudioSettingsModal` match trim trailing `\n`); tempat tersimpan `1.864.970` B (`4D3521...5CB`) | [qa_edit_clean.jpg](qa_edit_clean.jpg) |

## Batas QA & Pekerjaan Tersisa

- Input sentuh fisik pada Tablet/Phone nyata (serta preview live Device Emulator native saat jendela berdimensi `390×844` / `844×390`) dan aliran transaksi Robux sungguhan belum diuji (`DEFER-01` & `OPEN-04`); evaluasi multi-viewport pada run akhir memakai perhitungan langsung dari formula `HUDLayout` beserta uji klon visual sebelumnya.
- `qa_weapon_locked_desktop.jpg` (`InFlight=true`) dan `qa_audio_muted_desktop.jpg` (`BISU`) difoto tepat sebelum edit terakhir `HUDTheme` (`HUDCtaFill`/`HUDPingFill`/`HUDCardBadge`/`InventoryCount` `13px`), sedangkan popup default keempatnya, kedua banner hasil, `AudioMixer`, `HUDModalScrim`, kompilasi `45/45`, dan pemulihan Edit seluruhnya diverifikasi **pasca-edit final**.
- `Fly High.rbxl` telah disimpan (`1.864.970` B, `4D35210DF759E8FC99F43159B528FF7037197BDAECE17171472F48E1264445CB`); binary `.rbxl` belum dibuka ulang dan perubahan belum di-commit/push.

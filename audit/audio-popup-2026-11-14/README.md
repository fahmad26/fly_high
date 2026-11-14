# Laporan QA Popup Pengaturan Suara (`SUARA`), Mixer Audio 3-Kanal & Sistem Musik Latar

## Ringkasan Pekerjaan

- **ID fitur/temuan:** `UI-01` / Audio Settings Popup, 3-Channel Audio Mixer & Multiplayer-Safe Music System (Fase 1 + Fase 2 selesai terimplementasi & QA)
- **Tanggal/waktu/timezone:** `2026-11-14T15:20:47+07:00` (`Asia/Jakarta`)
- **Commit dasar & working tree:** `main` @ `f5aa15dc846f5ca842d1f5e22af0b7645fc4beca` (dirty files lokal termasuk perubahan sebelumnya, `8` source Fase 1, serta `AudioMixer` + `MusicController` baru pada Fase 2; belum di-commit/push)
- **Place tersimpan:** [`Fly High.rbxl`](../../Fly%20High.rbxl) (`1.829.167` byte, SHA-256 `231AA316E175A4FEC5CFAFBF0F78BB592040B514D5C4DDACDD2D2139F4E8BC12`); binary `.rbxl` belum dibuka ulang untuk verifikasi pasca-tutup Studio.

## Implementasi & Sinkronisasi Source (`45` source produksi)

Seluruh `45` source pada ketiga akar produksi (`14` di `ReplicatedStorage/FlyHigh/Modules`, `19` di `ServerScriptService/FlyHighServer`, `12` di `StarterPlayer/StarterPlayerScripts`) diperiksa via `ScriptEditorService:GetEditorSource` (`edDiff=0`) dan dikompilasi via `loadstring` (`compileFail=0`) setelah edit final. Pada Fase 2 (`AudioMixer` & `MusicController`), keduanya cocok identik byte-per-byte (`len`, `Fletcher-32 c1=0,c2=0`, dan SHA-256) antara Studio dan mirror `audit/sources/`:

| Script | Class | Panjang (B) | Checksum | SHA-256 (normalisasi LF) |
| --- | --- | ---: | --- | --- |
| `ReplicatedStorage/FlyHigh/Modules/AudioMixer` *(Fase 1 + Fase 2)* | `ModuleScript` | `6.992` | `0xf3c5f9ac` *(Fletcher-32)* | `c19b1971a783714511e2ed2a1eb9753a57c880d8e21d6684cb113d9ced40c90b` |
| `StarterPlayer/StarterPlayerScripts/MusicController` *(baru, Fase 2)* | `LocalScript` | `14.289` | `0x5d3626ed` *(Fletcher-32)* | `3c3683460263a0ee6f24f6effe0f8e6ca9f6aeb715b65e06d2a7d31bab31d40f` |
| `ReplicatedStorage/FlyHigh/Modules/AudioSettingsModal` *(baru, Fase 1)* | `ModuleScript` | `14.470` | `0xfe273120` *(Fletcher-32)* | `1feead9e1841c25e614ae902591430a645d5d3fab554625495223fed1395af1c` |
| `ReplicatedStorage/FlyHigh/Modules/HUDLayout` | `ModuleScript` | `22.571` | `0xca617957` *(Fletcher-32)* | `2e7003b97ef2cf1461806163102b526f12a18b5701f1a87691b82c036f597494` |
| `ReplicatedStorage/FlyHigh/Modules/HUDMotion` | `ModuleScript` | `53.641` | `0x1d9e7831` *(Fletcher-32)* | `c152aca93573011016f76153edd3b77bf5a61964add879687e7f8a1ce645340f` |
| `ReplicatedStorage/FlyHigh/Modules/HUDTheme` | `ModuleScript` | `58.799` | `0x97d55593` *(Fletcher-32)* | `fa3c4bd2c5a581ac2ac596edfe108894e33204c88035c49fc17c77fbd9b966f3` |
| `ReplicatedStorage/FlyHigh/Modules/WeaponPresentation` | `ModuleScript` | `12.219` | `0xf96b3d57` *(Fletcher-32)* | `4fb071927e8dee558982f752d0f86d7a2a2186a6dc5898d866dd7fa50d0a8907` |
| `StarterPlayer/StarterPlayerScripts/WarningAudioController` | `LocalScript` | `7.794` | `0xcf94dd9c` *(Fletcher-32)* | `decf140af84e05d6a0246d6080e35706440c2cad796aeeca7f40f4e93b0f20a5` |
| `StarterPlayer/StarterPlayerScripts/WeaponClientController` | `LocalScript` | `43.706` | `0x2ef17616` *(Fletcher-32)* | `be3859ce32e6275c2ebd77840d1dcf470ae6ba2f344fba79828155decd421391` |

*(Catatan baseline: 6 file lain di `audit/sources/` yang tidak disentuh di Fase 2 memiliki selisih 1 trailing newline antara Studio dan mirror, namun identik byte-per-byte setelah normalisasi `rstrip("\n")` / LF.)*

## Ringkasan Desain & Perilaku

1. **Mixer & Bus Audio (`AudioMixer`):**
   - Membuat `SoundService.FlyHighAudioMixer` berisi tiga `SoundGroup`: `Master`, `Music`, dan `SFX`.
   - Mengelola atribut pemain: `AudioMasterVolume` (default `1`), `AudioMasterMuted`, `AudioMusicVolume` (default `0.60` agar nyaman multiplayer), `AudioMusicMuted`, `AudioSFXVolume` (default `1`), `AudioSFXMuted`, serta kompatibilitas mundur `WarningAudioMuted`.
   - Memasang pengaman audio langsung pada `SoundService.FlyHighAudioMixer.Music`: `MusicSafetyLimiter` (`CompressorSoundEffect`: `Threshold=-18`, `Ratio=5`, `Attack=0.015`, `Release=0.28`, `GainMakeup=0`, `Priority=1`) untuk mencegah lonjakan mendadak, dan `MusicVoicePocketEQ` (`EqualizerSoundEffect`: `LowGain=-1.0`, `MidGain=-2.5`, `HighGain=-2.0`, `Priority=0`) untuk menyisakan ruang kejernihan suara pemain lain.
   - Skala efektif: `GetMusicScale = Master * Music` dan `GetSFXScale = Master * SFX`; `IsOverallMuted` bernilai `true` hanya ketika `MusicScale <= 0 and SFXScale <= 0`.
2. **Popup & Aset (`AudioSettingsModal`, `HUDTheme`, `HUDLayout`, `HUDMotion`):**
   - Menggunakan aset Sky Adventure yang sudah ada (`ping_panel`, `close_normal`, `sound_on`/`sound_off`, `progress_track`/`progress_fill`).
   - Memuat 3 baris seragam (`Master Volume`, `Music Volume`, `Sound Effect`), masing-masing dengan slider drag/tap (`SliderHit` tinggi `44px`) dan tombol mute/unmute (`AudioMute*` ukuran `44×44` dengan ikon `36×36`).
   - `WarningAudioToggleButton` (`SUARA`/`BISU`) kini tampil dan dapat diklik baik di **Lobby** maupun **InFlight**.
   - Klik area non-tombol (`AudioTitle`, latar modal, `HUDModalScrim` `0..-58` penuh layar `ZIndex=20`) **tidak menutup** popup dan **tidak menembakkan senjata**. Hanya `AudioCloseButton` (`Close`) yang menutup saat scrim aktif.
3. **Kabel Konsumen SFX (`HUDMotion`, `WarningAudioController`, `WeaponPresentation`, `WeaponClientController`):**
   - `UIGroup` (`SoundService.FlyHighUIAudio_*`) mengikuti `GetSFXScale(player)`; `ping`/`pingGhost` dibisukan saat `GetSFXScale <= 0`.
   - `Warnings` (`WarningAudioController.FlyHighWarningAudio.Warnings`) terskala oleh `config.VOLUME * GetSFXScale(p)` (`0.400` pada `100%/100%`, `0.060` pada `Master 30% * SFX 50%`).
   - `WeaponReload` (`1/1`) dan seluruh pool `ShotEmitter.Gunshot` (`8/8`) terhubung ke `SoundService.FlyHighAudioMixer.SFX`.
   - `AudioSettingsModal` ditambahkan ke `MODAL_BLOCKER_NAMES` di `WeaponClientController` sehingga tembakan dan panah ghost tertahan saat modal terbuka.
4. **Sistem Musik Latar 8 Track & Perlindungan Multiplayer (`MusicController`):**
   - Mengelola dual crossfade deck (`DeckA`, `DeckB` di `SoundService.FlyHighMusic`) melalui `AudioMixer.GetGroup("Music")` dengan preload latar belakang `ContentProvider:PreloadAsync` (`8/8` `IsLoaded=true`, `0` error).
   - Pemetaan 8 track Creator Store (`APMOfficial`) dengan cap `gain <= 0.24` (`~0.114..0.144` di default slider `60%`) meski slider ditarik ke `100%`:
     - **Daratan Awal (Lobby):** `Walking On The Beach` (`rbxassetid://1845913205`, loop, `gain=0.24`, `fade=2.4s`)
     - **Ketinggian 1 (`0 – 2.000 km`):** `Into the Blue Sky (b 60)` (`rbxassetid://1842008726`, loop, `gain=0.22`, `fade=2.2s`)
     - **Ketinggian 2 (`2.000 – 4.000 km`):** `Rising Anguish 60 B` (`rbxassetid://9043165011`, loop, `gain=0.19`, `fade=2.0s`)
     - **Ketinggian 3 (`4.000 – 6.000 km`):** `Soft Memories` (`rbxassetid://1842237732`, loop, `gain=0.22`, `fade=2.2s`)
     - **Ketinggian 4 (`6.000 – 8.000 km`):** `Dreaming of the Stars (a 60)` (`rbxassetid://1838007258`, loop, `gain=0.22`, `fade=2.2s`)
     - **Ketinggian 5 (`8.000 – 10.000 km`):** `A Place for Hope Part 3` (`rbxassetid://1837460339`, loop, `gain=0.19`, `fade=2.0s`)
     - **Istana Awan (`10.000 km`) — Tiba:** `Jubilation (b)` (`rbxassetid://1841079605`, `Looped=false`, `gain=0.20`, `fade=1.1s`)
     - **Istana Awan (`10.000 km`) — Seterusnya:** `Happy Ending (a)` (`rbxassetid://1841070706`, `Looped=true`, `gain=0.20`, `fade=1.6s`) via `Sound.Ended` + pengaman near-end (`TimeLength - 0.35s`) / stall guard hingga `ReturnPrompt` membawa pulang ke Lobby.
   - Histeresis turun `HYSTERESIS_KM = 80` mencegah lagu berganti-ganti di perbatasan ketinggian; jeda docking Istana (`InFlight=false` saat `ArrivalPending=true`) dijaga agar musik tidak sempat berkedip ke Lobby; peringatan (`FlyHighWarningAudio.ActiveWarning` / `AlertBanner.HUDAlertActive`) secara halus me-duck musik ke `0.58×` dengan snap presisi ke `0.580`/`1.000`.

## Hasil QA Pasca-Edit Final

| Run / Cek | Lingkungan & Fixture | Target | Hasil Aktual | Bukti |
| --- | --- | --- | --- | --- |
| **Desktop Lobby Default & Toggle** | Play Solo `1` klien Windows (`2090×694`, scrim `2090×752` di `(0,-58)`), input mouse `user_mouse_input` | Klik `SUARA` buka popup default `100%/75%/100%`, ikon/teks `SUARA`, tanpa overlap | **PASS** — `toggleVis=true`, `Master=1.00`, `Music=0.75`, `SFX=1.00`, gap knob-mute `7px` (`track=881..1149`, `mute=1167..1211`) | [qa_desktop_lobby_default.jpg](qa_desktop_lobby_default.jpg) |
| **Non-Button & Scrim Guard** | Play Solo `1` klien, klik `AudioTitle`, panel kosong `(860,350)`, dan scrim `(200,300)` | Modal & scrim tetap terbuka | **PASS** — `afterNonBtnModal=true`, `afterNonBtnScrim=true` | Sesi + log run |
| **Slider Drag & Bus Matematika** | Play Solo `1` klien, drag pointer nyata `Music -> 20%`, `Master -> 30%`, `SFX -> 50%` | `Music = 0.060`, `SFX = 0.150`, `UIGroup = 0.150` | **PASS** — `M=0.30, Mu=0.20, S=0.50`, `sgM=0.300`, `sgMu=0.060`, `sgS=0.150`, `ui=0.150` | [qa_desktop_dragged_30_20_50.jpg](qa_desktop_dragged_30_20_50.jpg) |
| **Mute Per-Kanal vs Mute Master** | Play Solo `1` klien, klik `AudioMuteMusic` lalu `AudioMuteMaster` | Mute Music menjaga SFX aktif; Mute Master membisukan seluruh bus + label `BISU` | **PASS** — Mute Music (`sgMu=0.000, sgS=0.150`); Mute Master (`sgM=0.000, sgMu=0.000, sgS=0.000, ui=0.000, HUDCaption=BISU`) | [qa_desktop_master_muted_bisu.jpg](qa_desktop_master_muted_bisu.jpg) |
| **Tutup via Close Button & Toggle** | Play Solo `1` klien, klik `AudioCloseButton` & klik `SUARA` buka/tutup | `AudioCloseButton` menutup modal + scrim; klik `SUARA` buka/tutup ulang | **PASS** — `closedByCloseBtn=true` | Sesi |
| **InFlight + Pistol + Warnings + Gun SFX** | Play Solo `1` klien (`Pod_A` tahan `E` -> `AutoGasButton` -> `ReleaseHelmButton` -> `y=65.9, InFlight=true, 464 km` -> ambil Pistol & tembak 1x -> buka `SUARA` -> klik `AudioTitle` & scrim `(200,300)`) | `SUARA` tampil InFlight; `8/8` `Gunshot` + `1/1` `WeaponReload` ke `SFX`; `Warnings` `0.400 -> 0.060`; Pistol tidak menembak saat klik non-tombol di modal (`8 / ∞` tetap) | **PASS** — seluruh kondisi lulus; `afterNonBtnModalVis=true`, `ammoAfterClicks=8 / ∞` | [qa_desktop_inflight_active.jpg](qa_desktop_inflight_active.jpg) |
| **Responsif Tablet & Phone (Engine Render)** | Klon `AudioSettingsModal` dirender Roblox UI engine pada kontainer `1024×768` (Tablet), `390×844` (Phone Portrait), `667×375` (Phone Landscape) dalam Play Solo (`__TempResponsiveQA`, dibersihkan sesudahnya) | `issues=[]`, `TextFits=true`, semua target tombol/slider `>= 44×44` (atau tinggi `44`), bebas klip & overlap | **PASS** — `Tablet` (`468×404`), `PhonePortrait` (`366×404`), `PhoneLandscape` (`468×359`): semua `issues=[]`, `titleFits=true`, `subFits=true`, `hit=268×44`/`192×44`, `mute=44×44`, `gap=18px` | [qa_responsive_tablet_phone_cards.jpg](qa_responsive_tablet_phone_cards.jpg) |
| **Console Boot Bersih & Pemulihan Edit (Fase 1)** | Reboot Play Solo bersih -> buka & tutup `SUARA` -> Stop -> cek `Edit` camera `(0,48,25)->(0,12,-55)` & zero stray fixtures -> `save_place` | 0 error gameplay; Studio kembali ke `Edit`, 1 pemain, kamera default, 0 fixture tersisa | **PASS** — Console: `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.` (0 error/warning); Edit `playersInEdit=0, ssCount=0, sgCount=0, stray=[]` | [qa_edit_default_clean.jpg](qa_edit_default_clean.jpg) |
| **Fase 2 (Pra-Snap Fix): Slider Music `60%`/`100%` Cap & Mute** | Play Solo `1` klien Lobby (`2090×694`): cek default `60%`, drag slider `100%`, klik `AudioMuteMusic` mute & unmute, drag balik `60%` | Default `60%`, saat `100%` raw `DeckB.Volume` tetap `<= 0.2400`, mute membisukan `Music` bus (`0.000`) | **PASS** — Default `60%`; saat `Music=1.00, musicSG=1.000` raw `DeckB.Volume=0.2400`; mute (`sg=0.000`), unmute (`sg=0.600`), tutup via `AudioCloseButton` | [qa_music_lobby_popup_60.jpg](qa_music_lobby_popup_60.jpg) |
| **Fase 2 (Pra-Snap Fix): Pod Launch `Biome1`, Bioma `2..5`, Histeresis, Palace & Return** | Play Solo `1` klien: launch nyata `Pod_A` (`E`) -> `Helm` + `AutoGas` (`Y=70.07`), lalu fixture `Anchored` + `ArrivalProtected` sweep ketinggian `2000`, `1990`, `1900`, `4500`, `6500`, `8500`, lalu `10000 km` memicu `PalaceArrival.Enqueue` nyata -> maju `TimePosition` `TimeLength - 1.2s` -> `ReturnPortal.ReturnPrompt` (`E`) | `Biome1` (`1842008726`) saat lepas landas; `Biome2..5` tepat ID; `1990 km` menahan `Biome2` & `1900 km` kembali `Biome1`; `PalaceIntro` (`1841079605`, `Looped=false`) -> `PalaceLoop` (`1841070706`, `Looped=true`) -> `ReturnPrompt` kembali `Lobby` (`1845913205`) tanpa kedipan Lobby saat docking | **PASS** (dengan temuan minor pra-fix: `DuckMultiplier` tertahan ~`0.592`/`0.961..0.982` karena epsilon `> 0.001` pada FPS tinggi; `DeckB`/`DeckA` seluruh zone & transisi lulus bersih) | [qa_music_palace_intro.jpg](qa_music_palace_intro.jpg) |
| **Fase 2 (Pasca-Edit Final): Boot Lobby `8/8`, Limiter+EQ, Ducking Snap `0.580`/`1.000`, Console Bersih & Edit** | Dua run Play Solo `1` klien **setelah edit final 4-baris snap ducking** di `MusicController`: (#1) boot Lobby + pulse `AlertBanner:SetAttribute("HUDAlertActive", true/false)` lalu (#2) boot bersih tanpa menyentuh apa pun + `get_console_output` -> Stop -> reset kamera `(0,48,25)->(0,12,-55)` -> `save_place` | `8/8` asset `Loaded`, `Music=0.600` (`DeckB=0.2400`), `MusicSafetyLimiter` + `MusicVoicePocketEQ` aktif, ducking snap presisi `1.000 -> 0.580 -> 1.000`, `0` error console, `Edit` bersih tersimpan | **PASS** — `zone=Lobby, asset=1845913205, loaded=8, musicSG=0.600, DeckB=0.2400, lim=(-18.0, 5.0), eq=(mid=-2.5, hi=-2.0), duck0=1.000 -> duckDown=0.580 -> duckUp=1.000`; boot bersih Console hanya `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.`; `Edit` `players=0, strayBalloons=[], cam=(0,48,25)` | [qa_music_edit_clean.jpg](qa_music_edit_clean.jpg) |

## Batas QA & Pekerjaan Tersisa

- Uji responsif Phone/Tablet (Fase 1) memakai kontainer dimensi viewport di dalam client desktop (`1` pemain), belum input sentuh fisik di iPad/Phone nyata.
- Pengujian perpindahan zona `2.000–8.500 km` & Istana dilakukan sebelum 4-baris perbaikan epsilon ducking (yang hanya menyentuh blok `DuckMultiplier`, dan jalur `DuckMultiplier` sudah diverifikasi ulang pasca-edit), memakai fixture `Anchored` + `ArrivalProtected` serta percepatan `TimePosition`; perjalanan alami terus-menerus `0 -> 10.000 km` belum dijalankan.
- Kejernihan suara pemain lain (`voice chat` + beberapa klien + SFX bersama) belum diuji manusia pada sesi multiplayer multi-klien nyata.
- Place lokal telah disimpan (`1.829.167` B, `231AA316E175A4FEC5CFAFBF0F78BB592040B514D5C4DDACDD2D2139F4E8BC12`); binary `.rbxl` belum dibuka ulang dan perubahan belum di-commit/push.

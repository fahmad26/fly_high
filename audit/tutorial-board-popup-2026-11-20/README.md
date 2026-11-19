# QA Papan Tutorial Spawn & Popup 3-Tab Bilingual (`UI-01` / `WORLD-01` / `L10N-01`)

Tanggal: **20 November 2026 (03:00 WIB)** — Studio `c3777d67-8edf-4329-8e0d-c6eb7688e8ef` (`Fly High.rbxl` lokal, `placeId = 97043730132219`, `universeId = 10776821830`, base commit Git `bb8a63f`). **Belum di-commit, belum di-push, dan belum di-Publish.**

## Ringkasan Implementasi

Memakai **100% aset UI & ikon Sky Adventure yang sudah ada** (tanpa unggah gambar baru) untuk menghadirkan panduan bermain interaktif langsung di dekat spawn:

1. **Papan Panduan di Lobby (`Workspace.FlyHighLobby.WelcomeSign`):**
   - Diperbarui di [`WorldUISkins.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/WorldUISkins.luau) (`styleWelcomeSign`: judul `FLY HIGH`, ringkasan 3 langkah `WelcomeInstructions`, petunjuk interaksi `WelcomePromptHint`) dan ditambah `ProximityPrompt` `"TutorialPrompt"` (`ActionText = "Cara Bermain"`, `ObjectText = "Papan Panduan"`, `E` / `ButtonX`, `MaxActivationDistance = 14`, `Style = Custom`) bersama [`HUDInteractionPrompts.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDInteractionPrompts.luau) (`"CARA BERMAIN"` / `"HOW TO PLAY"`).
2. **Popup 3 Tab Interaktif ([`TutorialModal.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/TutorialModal.luau)):**
   - **Tab 1 (`DASAR` / `BASICS`):** 1. Masuk Dermaga (`master_crest`), 2. Capai Istana Awan 10.000 km (`goal_marker`), 3. Waspadai 5 Lubang Balon (`ping_danger`).
   - **Tab 2 (`PERAN` / `ROLES`):** Pilot (`gas_normal`), Gunner (`art_shop_ak_v2`), Engineer (`ping_repair`).
   - **Tab 3 (`BERTAHAN` / `SURVIVAL`):** Dinding Badai & Lompat (`jump_normal`), Emergency Kit & Clutch Save (`art_shop_kit_v2`), Mode Arwah Spotter (`ping_normal`).
   - Terintegrasi ke [`ShopClientController.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/ShopClientController.luau) (`TutorialModal.Ensure`), [`WeaponClientController.luau`](../../audit/sources/StarterPlayer/StarterPlayerScripts/WeaponClientController.luau) (`MODAL_BLOCKER_NAMES`), [`HUDMotion.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDMotion.luau) (mutual exclusion antar-modal), [`HUDTheme.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau) (`modal_frame_9slice`, `crest_victory`, `TutorialCloseButton`), dan [`HUDLayout.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau) (tata letak responsif 5 viewport).
   - **Temuan & Perbaikan Saat QA Visual:** Pada run pertama, penamaan `Card1..Card3` bertabrakan dengan aturan skinning kartu Toko di `HUDTheme.luau:697`, menyebabkan `HUDCardStage` menutupi `IconSlot`. Diperbaiki dengan mengganti nama kartu menjadi `TutCard1..TutCard3` di `TutorialModal.luau` & `HUDLayout.luau` serta mengecualikan `TutorialModal` di `HUDTheme.luau`, kemudian seluruh `02`–`06` & matriks `30` sel diverifikasi ulang pasca-edit final.
3. **Lokalisasi Bilingual `ID` / `EN` (`542` entri, `59` templat):**
   - Ditambahkan `28` kunci papan & tutorial di [`id-en.json`](../../assets/localization/id-en.json), [`id-en.csv`](../../assets/localization/id-en.csv), dan [`LocalizationCatalog.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/LocalizationCatalog.luau) (dibangun via Python mengikuti logika [`build-localization.cjs`](../../tools/build-localization.cjs) karena `node` CLI tidak terpasang di `PATH` host).

## Hasil QA `Play Solo`

- **Lingkungan & Fixture:** Studio Windows `Play Solo` (`1` pemain `Fikki2621`), penulisan `DataManager` di-stub di memori oleh `_QA_TutServer`, serta simulasi viewport menggunakan atribut `QA_ViewportSize`/`QA_Touch` pada `FlyHighHUD` untuk matriks responsif & screenshot ponsel/tablet.
- **Parity & Compile (`Edit` pasca-edit final):** **`67/67`** skrip compile (`0` gagal), **`67/67`** cocok Adler-32 & panjang ternormalisasi antara Studio `Edit` dan `audit/sources/` (`0` mismatch).
- **Akses Papan & Bilingual `WelcomeSign`:** Jalan ke `WelcomeSign` (`reached = true`, `distToBoard = 5.53` stud, `hasPrompt = true`), verifikasi `TutorialPrompt` + `SurfaceGui` pada `"en"` (`HOW TO PLAY`, `fits = true`) & `"id"` (`CARA BERMAIN`, `fits = true`).
- **Interaksi Popup, 9 Ikon & Perilaku:**
  - `keyPress E` membuka `TutorialModal` (`visible = true`, `scrimVisible = true`, `activeTab = "basics"`, `hudCardStageCount = 0`, `frameLoaded = true`, `crestLoaded = true`, `closeLoaded = true`).
  - Klik mouse nyata pada `TabRolesButton` (`activeTab = "roles"`, `scrollCanvasPos = [0, 0]`) dan `TabSurvivalButton` (`activeTab = "survival"`, **`all9IconsLoaded = true` (`9/9`)** setelah 3 tab dibuka).
  - Eksklusivitas modal: `open_shop` menutup `TutorialModal` (`shopVisible = true`, `tutorialVisible = false`, `shopCard1StageExists = true` memastikan kartu Toko tidak rusak).
  - Auto-close `InFlight`: `InFlight = true` menutup popup (`tutVisible = false`, `scrimVisible = false`).
  - Klik `TutorialCloseButton` menutup popup & scrim (`tutVisible = false`, `scrimVisible = false`).
- **Matriks Responsif `5 × 3 × 2` (`30` Sel):** **`30/30 PASS` (`failures = []`)** mencakup `1920×1080`, `1366×768`, `1024×768`, `844×390`, `390×844` × `3` tab × `ID`/`EN` (`LocalizedText`, `TextFits = true`, bebas clip/overlap, `IsLoaded = true`).
- **Console:** **`0`** error runtime skrip game (`1` info `[BadgeManager]` standar Studio).

## Screenshot & Log Terverifikasi

| Bukti | Berkas |
| --- | --- |
| Papan `WelcomeSign` & Prompt `[E] CARA BERMAIN` | [01-welcome-board-and-prompt.jpg](01-welcome-board-and-prompt.jpg) |
| Tab 1 `DASAR` (`ID`, pasca-fix ikon) | [02-tutorial-tab1-basics-id.jpg](02-tutorial-tab1-basics-id.jpg) |
| Tab 2 `PERAN` (`ID`, pasca-fix ikon) | [03-tutorial-tab2-roles-id.jpg](03-tutorial-tab2-roles-id.jpg) |
| Tab 3 `BERTAHAN` (`EN`, konfirmasi terjemahan live) | [04-tutorial-tab3-survival-en.jpg](04-tutorial-tab3-survival-en.jpg) |
| Simulasi Phone Portrait `390×844` (`EN`) | [05-tutorial-phone-portrait-en.jpg](05-tutorial-phone-portrait-en.jpg) |
| Simulasi iPad `1024×768` Tab `PERAN` (`ID`) | [06-tutorial-ipad-roles-id.jpg](06-tutorial-ipad-roles-id.jpg) |
| Pemulihan Mode `Edit` & Kamera Default | [edit-restored.jpg](edit-restored.jpg) |
| Log QA JSON Lengkap | [qa-results.json](qa-results.json) |
| Laporan Pemeriksaan Biner `.rbxl` (`67/67`) | [binary-source-report.json](binary-source-report.json) |

## Pemulihan, Save Place & Batas Pengujian

- Studio pulih ke `Edit`, `TestService.NumberOfPlayers = 1`, `leftoverCount = 0`, `WelcomeSign.TutorialPrompt` utuh (`ActionText = "Cara Bermain"`, `ObjectText = "Papan Panduan"`), dan kamera default `[0, 48, 25] -> [0, 12, -28]`.
- `save_place` menulis langsung ke berkas lokal [`Fly High.rbxl`](../../Fly%20High.rbxl) (**`3.547.491` B**, `2026-11-20T03:00:06.5856161+07:00`, SHA-256 `f17d2986fc85dbcd2d3303f1797d9485c8902574b12092ae37256557afdb77b9`).
- Pemeriksaan parser biner `.rbxl` (`inspect_rbxl.py`, **tanpa membuka ulang `.rbxl` di sesi Studio baru**) mengonfirmasi `binaryScripts = 67`, `mirrorScripts = 67`, `mismatches = []`, `qaNames = []`, `TestService.NumberOfPlayers = [1]`, `_has_QA_attr = false`.
- **Sisa / Batas:** Uji langsung di perangkat **Phone/iPad fisik** (tap sentuh & keyboard/gamepad nyata), sinkronisasi ke **Cloud Team Create** jika diperlukan (saat ini tersimpan di `.rbxl` lokal), dan buka ulang `.rbxl` di sesi Studio baru.

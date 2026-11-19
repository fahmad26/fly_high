# Audit & QA: Pengecilan Lebar Pill Title & Audio/VFX Tracer Peluru (19 November 2026)

## Ringkasan Perubahan

1. **Pengecilan & Penjagaan Responsif `CosmeticTitlePill` ([`OverheadManager.luau`](../sources/ServerScriptService/FlyHighServer/OverheadManager.luau)):**
   - Menambahkan peta lebar kompak `TITLE_PILL_WIDTHS`:
     - `faithful_explorer`: `126 px` (`labelWidth = 110 px`)
     - `cloud_conqueror`: `134 px` (`labelWidth = 118 px`)
     - `prince_of_sky`: `164 px` (`labelWidth = 118 px`, ruang kiri `RoyalCrest` `16×16` di `x=6` & kanan `RoyalSparkle` `11×11` di `x=-7`)
     - `princess_of_sky`: `174 px` (`labelWidth = 128 px`, ruang `RoyalCrest` & `RoyalSparkle`)
   - Pill tetap dipusatkan (`AnchorPoint = (0.5, 0)`, `Position = (0.5, 0, 0, 37/38)`) di dalam `BillboardGui` berukuran offset tetap `220 × 84/92` agar proporsional di semua resolusi (Desktop, Phone, iPad) dengan `TextScaled = true` dan `UITextSizeConstraint.MinTextSize = 8`.

2. **Efek Suara Tembakan & Dampak Unik Per-Tracer pada Rintangan Shootable ([`WeaponPresentation.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/WeaponPresentation.luau)):**
   - **Audio Pool Preloaded (`SFX` SoundGroup):** `8 ShotEmitter` (`56/56` sound `IsLoaded = true`) dan `6 ImpactEmitter` (`84/84` sound `IsLoaded = true`) melalui `WeaponAudioPool`.
   - **Suara Tembakan & Impact Berlapis per Tracer:**
     - `default`: `Gunshot`; `Hit` (`HitTickSFX,HitPunchSFX`); `Kill` (`KillBoomSFX,KillChimeSFX`).
     - `cyan_sky`: `Gunshot + CyanShotZapSFX + CyanShotZipSFX`; `Hit` (`+ CyanImpactZapSFX, CyanImpactShatterSFX`); `Kill` (`+ CyanKillZapSFX, CyanImpactShatterSFX`).
     - `dawn_gold`: `Gunshot + GoldShotBlazeSFX + GoldShotSwishSFX`; `Hit` (`+ GoldImpactBlazeSFX, GoldImpactChimeSFX`); `Kill` (`+ GoldKillBoomSFX, GoldImpactBlazeSFX`).
     - `aurora_violet`: `Gunshot + VioletShotWhompSFX + VioletShotBeepSFX`; `Hit`/`Kill` (`+ VioletImpactWhompSFX, VioletImpactPixiesSFX`).
     - `Immune` (rintangan kebal): tetap `ImmunePingSFX,ImmuneClankSFX` + `WeaponImmuneShieldDisc`/`WeaponRicochetBolt` tanpa efek kosmetik tracer agar pemain langsung membedakan target kebal vs shootable.
   - **VFX Dampak Unik & Cincin Terbang:**
     - Selama terbang kosmetik (`distance >= 24`, non-reduced-motion), tracer memancarkan hingga 2 `TracerPulseRing`.
     - `cyan_sky` (`Hit`/`Kill`): cincin plasma, 4/6 petir patah 3-segmen (`WeaponTracerArc`), dan serpihan prismatik (`TracerImpactShard` / `TracerImpactKillShard`).
     - `dawn_gold` (`Hit`/`Kill`): *sunburst cross flare* 4/6-sinar (`TracerImpactStarRay` / `TracerImpactKillStarRay`), cincin oranye-emas, nova, dan bara melesat (`TracerImpactEmber` / `TracerImpactKillDebris`).
     - `aurora_violet` (`Hit`/`Kill`): 2/3 cincin kosmik miring yang berputar (`TracerImpactRiftRing` / `TracerImpactKillGyroRing`), nova ungu, dan kristal wajik 45° berputar (`TracerImpactCrystal` / `TracerImpactKillCrystal`).

## Hasil Verifikasi

- **Parity & Compile (`Edit` mode):** `66/66` skrip Studio terkompilasi `0` error (`shaSelfTest = ok`, `TestService.NumberOfPlayers = 1`), `66/66` cocok SHA-256 UTF-8 ternormalisasi (`LF` + trim trailing newline). `WeaponPresentation.luau` cocok byte-per-byte raw SHA-256 (`71071` B); `OverheadManager.luau` identik isi setelah trim trailing `\n` (`Studio = 12160 B`, mirror disk `12161 B`).
- **Suite A — Overhead Pill × 4 Gelar × ID/EN (`Play Solo`, [`qa-results.json`](qa-results.json)):**
  - `8/8` kombinasi lulus `TextFits = true`, `TitleFits = true`, `NameFits = true`, tidak menabrak `RoyalCrest` (`gapCrestToLabel = 2 px`) atau `RoyalSparkle` (`gapLabelToSparkle = 4 px`), dan memiliki margin horizontal **`14.4% – 50.8%`**:
    - `faithful_explorer` (`126 px`): ID `"★ Penjelajah Setia"` (`94/110 px`, margin `14.5%`), EN `"★ Loyal Explorer"` (`86/110 px`, margin `21.8%`).
    - `cloud_conqueror` (`134 px`): ID `"★ Penakluk Awan"` (`94/118 px`, margin `20.3%`), EN `"★ Cloud Conqueror"` (`101/118 px`, margin `14.4%`).
    - `prince_of_sky` (`164 px`): ID `"Pangeran Langit"` (`87/118 px`, margin `26.3%`), EN `"Prince of the Sky"` (`90/118 px`, margin `23.7%`).
    - `princess_of_sky` (`174 px`): ID `"Putri Langit"` (`63/128 px`, margin `50.8%`), EN `"Princess of the Sky"` (`102/128 px`, margin `20.3%`).
- **Suite B — Audio & VFX Impact Unik (`Play Solo` via `WeaponFireEvent` & fixture `DataManager` stub):**
  - Seluruh kasus `default`, `cyan_sky`, `dawn_gold`, dan `aurora_violet` (`Hit` & `Kill`) serta regresi `Immune` menghasilkan atribut `WeaponAudioPool` dan komponen VFX unik sesuai tabel di [`qa-results.json`](qa-results.json).
  - Leftover VFX pasca `1,6 dtk`: `0`. Error runtime skrip game di `get_console_output`: `0`.
- **Bukti Screenshot:**
  - [`impact-cyan-sky-hit-kill.jpg`](impact-cyan-sky-hit-kill.jpg)
  - [`impact-dawn-gold-hit-kill.jpg`](impact-dawn-gold-hit-kill.jpg)
  - [`impact-aurora-violet-hit-kill.jpg`](impact-aurora-violet-hit-kill.jpg)
  - [`edit-restored.jpg`](edit-restored.jpg)

## Penyimpanan, Cleanup & Batas Pengujian

- **Edit Mode & Place Lokal:** Studio kembali ke `Edit`, `0` pemain, `TestService.NumberOfPlayers = 1`, `qaLeftovers = 0`, kamera `[0, 48, 25] -> [0, 12, -28]`, tersimpan lokal ke `E:/Antigravity/Fly High/Fly High.rbxl` (`3.540.071` B, `2026-11-19T21:16:53.9326375+07:00`, SHA-256 `db3c5c7aa73a66f34995dfa051d72deac175052afc5846da67d941b841e9ab8a`). Binary `.rbxl` **belum dibuka ulang**, **belum commit/push Git**, dan **belum publish ke Cloud**.
- **Batas QA yang masih terbuka:** Tool `screen_capture` MCP Studio tidak merender `BillboardGui` sehingga tampilan visual pill overhead tidak tercetak di tangkapan gambar MCP (layout/ukuran teks diukur langsung dari properti runtime klien); selain itu uji dengar speaker nyata di klien Roblox live, tampilan visual fisik Phone/iPad (`OverheadGui` + VFX tracer), serta multiplayer `2–3` klien nyata tetap menjadi QA lanjutan.

# QA Daily Login (7-Hari Non-Reset), Ekonomi Sky Coins, Toko 3-Tab & Audit Responsif

- **ID Run:** `daily-login-shop-2026-11-14`
- **Tanggal/Waktu/Timezone:** 14–15 November 2026 (update pasca-polesan UI final: `2026-11-15T00:40:46+07:00`, Asia/Jakarta)
- **Build:** Base commit `f5aa15d` (`main`), dirty working tree + `14` PNG 2× RGBA [`assets/ui/sky-adventure/generated/daily-shop/`](../../assets/ui/sky-adventure/generated/daily-shop/) (`34` kunci ID di [`roblox-texture-ids.json`](../../assets/ui/sky-adventure/roblox-texture-ids.json)), mirror [`audit/sources/`](../sources/) `49/49` identik terhadap Studio `Edit` pasca-normalisasi StripBOM/LF/TrimEnd (UTF-8 byte length + FNV-1a-32 + DJB2-32; `0` error `loadstring`), place tersimpan [`Fly High.rbxl`](../../Fly%20High.rbxl) (`1.893.898` B, `2026-11-15T00:40:46+07:00`, SHA-256 `04EF01A363C8DC96B972DC1F005A7F729369AF92E42540EE63D508086CAFB5A6`, isi binary belum dibuka ulang).
- **Lingkungan:** Roblox Studio Windows (`Edit` & `Play Solo` `1` klien, viewport Play `2090×694` / Edit `2090×752`), DataStore mock offline (`[DataManager] Unpublished Studio: isolated mock data; checkout disabled.`), simulasi `4` viewport via atribut `QA_ViewportSize`/`QA_Touch` pada `FlyHighHUD` (`PhonePortrait` `390×844` `touch=true`, `PhoneLandscape` `844×390` `touch=true`, `Tablet` `1024×768` `touch=true`, `Desktop` `1280×720` `touch=false`).

## Cakupan Pemeriksaan & Batas Pembaruan

### 1. Pasca-Edit Final (`HUDAdventureCatalog` `ef8faf9b_404d1e11`, `DailyAndShopCatalog` `4ef2c9d3_38522657`, `DailyLoginModal` `879776d4_f83854f0`, `HUDLayout` `799ae93a_fed3fe0e`)
- **Sinkronisasi & Kompilasi (`Edit`):** `49/49` script di ketiga akar produksi identik dengan mirror [`audit/sources/`](../sources/) dan seluruh `49/49` lulus `loadstring` (`compileErrorCount=0`). Katalog terverifikasi: `catalogDaily=7`, `catalogSupplies=2`, `catalogCosmetics=7`, `advKeys=79`, `roblox-texture-ids=34`.
- **Aset Ikon Kosmetik Varian Warna (Tab 3 `KOSMETIK`):** Menambahkan `4` PNG 2× RGBA (`art_cosmetic_frame_teal.png` -> `rbxassetid://129766939872535`, `art_cosmetic_tracer_gold.png` -> `rbxassetid://117771567556069`, `art_cosmetic_tracer_violet.png` -> `rbxassetid://125330903488863`, `art_cosmetic_title_cyan.png` -> `rbxassetid://96050086697784`) sehingga ke-`7` kosmetik tampil unik sesuai warna temanya; `ContentProvider:PreloadAsync(imgInsts)` pada `Play Solo` Client lulus `7/7` `Enum.AssetFetchStatus.Success` & sapuan scroll `CosmeticsScroll` (`Y=0 -> 320`) mengonfirmasi `ThumbImage.IsLoaded == true` untuk `7/7` item.
- **Audit Geometri 4 Viewport & Spacing `DayPill`–`StatusTag` (`Play Solo` Client langsung pada `FlyHighHUD`):** Memeriksa elemen aktual tanpa skip (`DailyToggleButton`, `WarningAudioToggleButton`, `ShopToggleButton`, `SettingsToggleButton`, `DailyLoginModal` `DayCard1..7`, `SupplyCard_*` `ArtStage`/`StockBadge`/`Title`/`Desc`/`BuyCoin_*`, `CosmeticRow_*` `ThumbStage`/`ThumbImage`/`ItemTag`/`ItemTitle`/`ItemDesc`/`ActCosmetic_*`):
  - `PhonePortrait` (`390×844`, `touch=true`): `issueCount=0` (`docks=4 days=7 supplies=2 cosmetics=7`), `DayCard1..6` memakai pil `30.6 px` bertuliskan `"H1".."H6"` + jarak aktual `4.08 px` sebelum `StatusTag` (`SIAP!`/`TERKUNCI`), `DayCard7` `"HARI 7"` (`57.1 px`) + `4.08 px` -> `"GRAND"`, seluruh `TextFits=true`.
  - `PhoneLandscape` (`844×390`, `touch=true`): `issueCount=0` (`docks=4 days=7 supplies=2 cosmetics=7`), `DayCard1..7` `"HARI 1".."HARI 7"` + jarak aktual `4.08 px`.
  - `Tablet` (`1024×768`, `touch=true`): `issueCount=0` (`docks=4 days=7 supplies=2 cosmetics=7`), `DayCard1..7` `"HARI 1".."HARI 7"` + jarak aktual `4.08 px`.
  - `Desktop` (`1280×720`, `touch=false`): `issueCount=0` (`docks=4 days=7 supplies=2 cosmetics=7`), `DayCard1..7` `"HARI 1".."HARI 7"` + jarak aktual `4.08 px`.
- **Screenshot Visual Pasca-Edit Final (`v3`):**
  - [`11_shop_tab3_kosmetik_top_v3.jpg`](11_shop_tab3_kosmetik_top_v3.jpg) (Desktop Tab 3 `KOSMETIK` atas: menampilkan `Bingkai Awan Emas` emas, `Bingkai Aurora Langit` aurora teal, `Tracer Cyan Langit`, & `Tracer Emas Fajar` emas fajar).
  - [`12_shop_tab3_kosmetik_bottom_v3.jpg`](12_shop_tab3_kosmetik_bottom_v3.jpg) (Desktop Tab 3 `KOSMETIK` scroll bawah: menampilkan `Tracer Emas Fajar`, `Tracer Ungu Aurora` ungu plasma, `Gelar: Penjelajah Setia` emas, & `Gelar: Penakluk Awan` cyan kristal).
  - [`13_phone_portrait_390x844_v3.jpg`](13_phone_portrait_390x844_v3.jpg) (`PhonePortrait 390×844` 4-panel: Daily Login `"H1".."H6"` berjarak `4 px` + `"HARI 7"`, `BEKAL`, `KOSMETIK` atas & `KOSMETIK` bawah).

### 2. Pengujian Fungsional & Visual Sebelum Polesan Ikon Kosmetik & `H1..H6`
*(Logika server `DataManager`, `BalloonManager`, `TetherManager`, `OverheadManager`, `ShopManager`, `WeaponManager`, dan aturan gameplay `DailyAndShopCatalog` tidak diubah setelah sesi pengujian fungsional berikut; hanya visual ikon kosmetik + tata letak label `DayPill`/`QA_ViewportSize` yang dipoles di Tahap 1.)*

- **Daily Login Non-Resetting & UTC+7 (`DataManager` clone sementara di server):**
  - Verifikasi batas hari UTC+7 (`before=20041 -> at=20042, delta=1, remBefore=1, remAt=86400`), blokir klaim ganda (`dupOk=false`, `"Hadiah hari ini sudah diklaim!"`).
  - Simulasi lompat 4 hari (`D2_AFTER_4_MISSED_DAYS: ok=true, dayClaimed=2, progAfter=3, coins=125, rope=1`) tanpa hangus progres.
  - Uji masa aktif trial kosmetik (D3 Tracer Cyan 3 hari kedaluwarsa saat D5 `eqT=none`; D5 Bingkai Awan 7 hari aktif `eqF=gold_cloud`) serta Hari ke-7 loop `7 -> 1`: klaim pertama (`coinsDelta=350, dup=false, kits=1, eqF=gold_cloud`), klaim duplikat (`coinsDelta=600, dup=true`, `"+1 Emergency Kit, Bingkai Awan Emas Permanen & +350 Sky Coins (+250 Koin duplikat kosmetik!)"`).
- **Toko 3-Tab (`ROBUX` / `PERBEKALAN` / `KOSMETIK`):**
  - Pembelian supply `ShopCoinFunction:InvokeServer("BuySupply", "tali_awet")` (`ok=true`, `coins: 2430 -> 2330`, `RopeBuffStock: 0 -> 1`).
  - Pembelian & pasang/lepas kosmetik (`gold_cloud`, `cyan_sky`, `faithful_explorer`): `"Gelar: Penjelajah Setia"` `UnequipCosmetic("title")` (`attr=none, vis=false`) -> `EquipCosmetic("title", "faithful_explorer")` (`attr=faithful_explorer, vis=true`, `coins=1180`).
- **Penerbangan Live, Tracker V2 Aura & Buff/Coin Cap:**
  - Launch `Pod_A`: `DailyToggleButton` tersembunyi (`dailyToggle=false`), `TurboGasButton`/`RopeBuffButton`/`ServerAltitudeTracker` tampil (`true`).
  - `ServerAltitudeTracker` mempertahankan desain V2 tanpa kotak latar (`FlightRow_1 bgTrans=1`), tanpa pil kiri, dengan lingkaran `CosmeticAuraHalo` (`bgTrans=0.62`, warna emas).
  - `Turbo Gas`: `UseBuffEvent:FireServer("turbo_gas")` (`spd=2->1, rem=60s`, `[HUDTurboText=⚡ 60s;]`), menolak aktivasi saat masih aktif, `rate=92, light=5.5`, kecepatan naik `+25.4%` (`ratio=1.2541`, holes=0) & kendali `+25.1%` (`steerRatio=1.251`), serta menolak pemakaian ke-3 per penerbangan (`used=2, ok=false`).
  - `Tali Awet`: aktif (`ok1=true`, `-30% pengikisan tali luar keranjang`), menolak duplikat (`ok2=false`), pengikisan tali terukur `3.502 HP/s` (`99.31 -> 92.89` dalam `1.83s`).
  - Ekonomi Koin penerbangan: tembak balon sendiri `dCoins=0`, hancurkan rintangan `dCoins=10`, batas cap aksi `60 Koin/penerbangan` (`rescue=10, capOverflow=50, totalAction=60`), milestone bioma anti-yo-yo `2k/4k/6k/8k` (`d4200=50, afterYoyo=50, d6200=90, d8100=140`), tiba `10.000 km` (`victory=true, coins 980->1130 (+150), summit=0->1, maxAlt=8100->10000`), kembali lobi (`inFlight=false, dailyToggle=true, turboBtn=false, ropeBtn=false`).
  - Tracer peluru kosmestik `cyan_sky` (`56, 189, 248`) pada `WeaponMuzzleFlash` & `FlyingBullet`.

## Bukti Screenshot Tersimpan
| File | Keterangan | Waktu Pengambilan |
| --- | --- | --- |
| [`01_daily_unclaimed_desktop.jpg`](01_daily_unclaimed_desktop.jpg) | Modal Daily Login Desktop (Hari 1 siap klaim) | Pra-edit minor UI |
| [`02_daily_claimed_desktop.jpg`](02_daily_claimed_desktop.jpg) | Modal Daily Login Desktop sesudah klaim | Pra-edit minor UI |
| [`03_shop_tab1_robux_desktop.jpg`](03_shop_tab1_robux_desktop.jpg) | Toko Tab 1 ROBUX Desktop | Pra-edit minor UI |
| [`04_shop_tab2_perbekalan_desktop.jpg`](04_shop_tab2_perbekalan_desktop.jpg) | Toko Tab 2 PERBEKALAN Desktop | Pra-edit minor UI |
| [`05_shop_tab3_kosmetik_desktop.jpg`](05_shop_tab3_kosmetik_desktop.jpg) | Toko Tab 3 KOSMETIK Desktop | Pra-edit minor UI |
| [`06_flight_turbo_tracker_desktop.jpg`](06_flight_turbo_tracker_desktop.jpg) | Penerbangan live: Turbo Gas aktif & halo emas pada Tracker V2 | Pra-edit minor UI |
| [`07_flight_hud_and_coins.jpg`](07_flight_hud_and_coins.jpg) | Penerbangan live: HUD ketinggian & ekonomi Sky Coins | Pra-edit minor UI |
| [`08_phone_portrait_390x844_v2.jpg`](08_phone_portrait_390x844_v2.jpg) | Phone Portrait `390×844` v2 (sebelum polesan `H1..H6` & ikon warna) | Pra-polesan v3 (geometri diuji ulang pasca-edit final `issueCount=0`) |
| [`09_phone_landscape_844x390_fixed.jpg`](09_phone_landscape_844x390_fixed.jpg) | Phone Landscape `844×390` | Pra-polesan v3 (geometri diuji ulang pasca-edit final `issueCount=0`) |
| [`10_tablet_1024x768_fixed.jpg`](10_tablet_1024x768_fixed.jpg) | Tablet `1024×768` (Lobi dock satu baris, Kosmetik, In-Flight HUD & Tracker) | Pra-polesan v3 (geometri diuji ulang pasca-edit final `issueCount=0`) |
| [`11_shop_tab3_kosmetik_top_v3.jpg`](11_shop_tab3_kosmetik_top_v3.jpg) | Desktop Tab 3 `KOSMETIK` atas (`Bingkai Aurora Langit` aurora teal, `Tracer Emas Fajar`) | **Pasca-edit final** |
| [`12_shop_tab3_kosmetik_bottom_v3.jpg`](12_shop_tab3_kosmetik_bottom_v3.jpg) | Desktop Tab 3 `KOSMETIK` bawah (`Tracer Ungu Aurora`, `Gelar: Penakluk Awan` cyan kristal) | **Pasca-edit final** |
| [`13_phone_portrait_390x844_v3.jpg`](13_phone_portrait_390x844_v3.jpg) | Phone Portrait `390×844` v3 (4-panel: Daily Login `"H1".."H6"` berjarak `4 px` + `"HARI 7"`, `BEKAL`, `KOSMETIK` atas & bawah) | **Pasca-edit final** |

## Cleanup & Batas Tersisa
- **Cleanup `Edit`:** `__QA_PhoneShowcase` & atribut sementara `QA_ViewportSize`/`QA_Touch` dihapus sebelum `Stop`; pemeriksaan `Edit` sesudah `Stop` mencatat `qaDestroyed=0`, `playersCount=0`, `starterGuiCount=0`, `cameraType=Enum.CameraType.Fixed` (`(0,48,25) -> (0,12,-55)`), `viewport=2090, 752`, output konsol bersih (`[DataManager] Unpublished Studio: isolated mock data; checkout disabled.`).
- **Belum Diuji / Terbuka:** Uji multiplayer 2–3 klien bersamaan untuk sinkronisasi halo bingkai / gelar / tracer antar pemain, uji sentuh perangkat fisik nyata (bukan atribut simulasi `QA_ViewportSize`/`QA_Touch`), re-run fungsional gameplay (`Turbo Gas`, `Tali Awet`, flight 10k) pada build UI terakhir bila ingin verifikasi gabungan penuh (script server tidak berubah), serta verifikasi buka-ulang isi binary [`Fly High.rbxl`](../../Fly%20High.rbxl).

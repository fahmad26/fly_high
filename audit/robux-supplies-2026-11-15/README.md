# QA Opsi Beli Robux untuk Turbo Gas (+25%) & Tali Awet (15 November 2026)

## Ringkasan Perubahan

Penambahan dukungan pembelian Robux untuk dua item perbekalan pada `ShopModal` (baik di **Tab `ROBUX`** maupun tombol opsi ganda pada **Tab `PERBEKALAN`**) serta pemrosesan receipt idempoten di server:

- **Developer Products (`FlyHighConfig.PRODUCT_IDS`):**
  - `TurboGas = 3731342382` (`29 Robux`, masuk ke `SpeedBoostStock` +1)
  - `TaliAwet = 3731343075` (`19 Robux`, masuk ke `RopeBuffStock` +1)
- **Server (`DataManager`, `ShopManager`):**
  - `DataManager.GrantReceipt(p, receiptId, item)` menangani `"TurboGas"` (`d.SpeedBoostStock + 1`) dan `"TaliAwet"` (`d.RopeBuffStock + 1`) secara idempoten terhadap riwayat receipt, menyinkronkan atribut player, serta menjaga status mock terisolasi saat `game.GameId == 0`.
  - `ShopManager.ProcessReceipt` menambahkan konfirmasi pesan toast untuk `TurboGas` & `TaliAwet` melalui `ShopPurchaseEvent`.
- **Katalog & UI (`DailyAndShopCatalog`, `ShopClientController`, `ShopTabsController`, `HUDLayout`, `HUDTheme`):**
  - **Tab `ROBUX` (`RobuxScroll`):** diperluas menjadi `Card1..Card4` (`EmergencyKit`, `AK47Upgrade`, `TurboGas (+25%)`, `TaliAwet`) dengan grid `2×2` di Desktop/Tablet (tanpa scroll), `2×2` scrollable di Phone Landscape (`rowH=148`), dan `1` kolom scrollable di Phone Portrait (`cardH=140`).
  - **Tab `PERBEKALAN`:** tombol opsi ganda berdampingan (`120 Koin` | `29 Robux` pada `SupplyCard_turbo_gas`, `100 Koin` | `19 Robux` pada `SupplyCard_tali_awet`), harga Robux ditarik live dari `MarketplaceService:GetProductInfoAsync`.
  - **Fix pasca-temuan QA awal (`HUDTheme`):** mengganti `fallbackArt` `Card3`/`Card4` dari kunci tidak terdaftar `"turbo"`/`"rope"` ke `"art_balloon"`/`"art_kit"` sebelum sprite penuh selesai preload.

## Sinkronisasi & Kompilasi

- Pemeriksaan script Studio vs mirror [`audit/sources/`](../sources/): **`50/50` identik (`matched=50, mismatched=[], extra=[]`), `compileErrorCount=0`**.
- Hash 8 berkas yang diperbarui (Studio):
  - [`FlyHighConfig.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/FlyHighConfig.luau): `4.289` B, `4deb457c_49b8befe`
  - [`DailyAndShopCatalog.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/DailyAndShopCatalog.luau): `7.129` B, `fe5b551b_ab020027`
  - [`ShopTabsController.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/ShopTabsController.luau): `27.088` B, `ad75145b_b7b567e3`
  - [`HUDLayout.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau): `39.003` B, `e76a8384_bc16419c`
  - [`HUDTheme.luau`](../sources/ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau): `84.269` B, `d14b970c_37fe3d2c`
  - [`DataManager.luau`](../sources/ServerScriptService/FlyHighServer/DataManager.luau): `20.488` B, `1c46cebe_525dbd6c`
  - [`ShopManager.luau`](../sources/ServerScriptService/FlyHighServer/ShopManager.luau): `4.904` B, `f8d9141d_06b2484f`
  - [`ShopClientController.luau`](../sources/StarterPlayer/StarterPlayerScripts/ShopClientController.luau): `20.250` B, `7eb5b8ee_6d1330e6`

## Hasil QA Play Solo (Pasca-Edit Final `HUDTheme`)

- **Lingkungan:** Roblox Studio `Play Solo` Windows `1` klien lokal (`GameId=0`).
- **Live `MarketplaceService:GetProductInfoAsync`:** `EmergencyKit=29`, `AK47Upgrade=79`, `TurboGas=29`, `TaliAwet=19`.
- **Audit Geometri 4 Viewport (`QA_ViewportSize`/`QA_Touch`):** `Desktop_1280x720`, `Tablet_1024x768`, `PhoneLandscape_844x390`, `PhonePortrait_390x844` seluruhnya lulus **`robuxIssues=[]`**, **`perbekalanIssues=[]`**, **`btnH=44`** pada seluruh `Card1..Card4`, dan **`TextFits=true`** pada semua tombol/label yang diperiksa (`120 Koin`, `29 Robux`, `100 Koin`, `19 Robux`).
- **Panggilan Live `ShopPurchaseEvent` (`"TurboGas"` & `"TaliAwet"`):** keduanya mendapat respons server sesuai aturan unpublished place (`"Produk siap. Publikasikan place ke experience Fly High untuk menguji pembelian."`).
- **Console Boot & Gameplay Bersih (Run Play Solo Pasca-Edit):** `get_console_output` hanya mencetak `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.` — **`0` error/warning runtime maupun `Unknown Fly High UI sprite`**.

## Bukti Screenshot

- [`01_shop_tab_robux_desktop.jpg`](01_shop_tab_robux_desktop.jpg) — Tab `ROBUX` Desktop pasca-fix `HUDTheme` (`29`, `79`, `29`, `19` Robux + ikon kustom).
- [`02_shop_tab_perbekalan_desktop.jpg`](02_shop_tab_perbekalan_desktop.jpg) — Tab `PERBEKALAN` Desktop dengan opsi ganda Koin | Robux (direkam tepat sebelum 2-line fix `fallbackArt` di `HUDTheme`; Tab Perbekalan tidak terdampak fix).
- [`03_shop_tab_robux_phone_portrait.jpg`](03_shop_tab_robux_phone_portrait.jpg) — Tab `ROBUX` pada simulasi `PhonePortrait_390x844` (direkam pra-fix `fallbackArt`).
- [`04_shop_tab_perbekalan_phone_portrait.jpg`](04_shop_tab_perbekalan_phone_portrait.jpg) — Tab `PERBEKALAN` pada simulasi `PhonePortrait_390x844` (direkam pra-fix `fallbackArt`).

## Batas Pengujian & Status Place

- Checkout Robux nyata (`PromptProductPurchase` -> `ProcessReceipt` cloud live) belum dapat dijalankan di local `.rbxl` (`GameId == 0`) sampai place dipublikasikan ke experience Roblox (`DEFER-01`). Simulasi `GrantReceipt` server idempoten (`3731342382`/`3731343075`) tercatat lulus pada Play Solo sesi sebelumnya sebelum edit 2-baris `HUDTheme.fallbackArt` (file server tidak berubah sejak lulus).
- Studio dipulihkan ke mode `Edit` (`playersCount=0`, `CameraType=Enum.CameraType.Fixed`, kamera default `(0, 48, 25)` melihat `(0, 12, -55)`).
- **`Fly High.rbxl` tersimpan (`save_place`):** `1.902.001` B, `2026-11-15 01:36:12 +07:00`, SHA-256 `9F86EB8963E27E217633B35D23DA22D2E14F087425CD85209DB5799B9202D57D` (**isi binary belum dibuka ulang; belum commit/push**).

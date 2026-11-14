# QA Perapian Teks & Layout HUD (13 November 2026)

Perbaikan merapikan tata letak, keterbacaan teks, dan bentuk tombol di modal HUD dan dock pasca laporan visual iPad.

## Perubahan Source

Tiga file diubah dan tersinkronisasi persis antara `audit/sources/` dan DataModel `Edit` Roblox Studio:

- `ReplicatedStorage.FlyHigh.Modules.HUDLayout` (`17.409` B, Adler-32 `0xBB4C5A28`, `loadstring` OK):
  - **Dock kiri**: `tileH` dinaikkan (`54` compact / `58` reguler) + boost preferensi teks.
  - **`WeaponSettingsModal`**: rongga aman digeser ke bawah kompas (`innerTop = 0.252 * mh`, `innerBottom = 0.892 * mh`, `mw <= 468`, `mh <= 392`), `SlotLabel1`/`2` diperlebar (`56..78 px`) dengan jarak `8 px` ke tombol pilihan (`HandgunSlot`), serta ruang footer fleksibel (`>= 28 px`) untuk `LaunchNote` / `SettingsFeedback`.
  - **`ShopModal`**: `cardY` diturunkan ke `0.224 * mh` agar jelas di bawah `ModalTitle`; batas bawah `0.138 * mh` memberi ruang bersih untuk `ShopFeedback`.
  - **`TacticalPingWheel`**: margin horizontal `pad = 0.138 * mw`, `header = 0.252 * mh`, batas bawah `0.884 * mh`, `rowHeight` `36..46 px`, `gap = 6 px` sehingga baris ping tidak menabrak bingkai emas melengkung.
- `ReplicatedStorage.FlyHigh.Modules.HUDTheme` (`52.298` B, Adler-32 `0xD1C99752`, `loadstring` OK):
  - **`raster()`**: menunda latar fallback `0.12` saat aset katalog sedang decode (`< 0.5 dtk` terlihat) maupun ketika panel tersembunyi, mencegah kotak gelap persegi tampil di sekitar sudut melengkung/awan.
  - **`Ping1..Ping5`**: menambahkan `UICorner(0, 10)` dan border halus pada `HUDMotionVisual` serta inset teks kiri-kanan; **`dock`**: menaikkan posisi `HUDCaptionPill` `3 px` dari tepi bawah agar `"Kit habis"` tidak menempel garis bawah.
  - **`ShopModal` & Kartu**: memindahkan `"TOKO PERBEKALAN"` ke `0.156 * h` (di bawah garis pembatas emas/cyan atas); menaikkan `buttonBottom` kartu ke `0.892 * h` (jelas di atas bingkai emas bawah `shop_ak_card`), menurunkan `fitLine(..., 8)` pada deskripsi, dan mengubah threshold panel kartu penuh menjadi `h < 236` agar landscape phone pendek memakai mode kartu ringkas yang muat teks deskripsi 2 baris.
  - **`WeaponSettingsModal` & `TacticalPingWheel` teks**: menata tipografi (`FredokaOne` / `Nunito`), vector `UIStroke`, dan `fitLine` (`UITextSizeConstraint`) untuk `PingTitle`, `Title`, `InventoryCount`, `SlotLabel1`/`2`, `LaunchNote`, `SettingsFeedback`, dan `ChoiceCaption`.
- `StarterPlayer.StarterPlayerScripts.ShopClientController` (`18.493` B, Adler-32 `0xE2E08563`, `loadstring` OK):
  - Tombol opsi dan toggle di `WeaponSettingsModal` memakai `ChoicePill` (`UICorner(0, 10)`, border, gradient halus) di dalam `HUDMotionVisual` (tidak lagi membentangkan sprite `ScaleType.Stretch` dengan ujung tajam/terjepit) serta padding horizontal `16 px` pada `ChoiceCaption`.

## Hasil QA (Build Akhir)

- **Sinkronisasi & Kompilasi**: `HUDLayout`, `HUDTheme`, dan `ShopClientController` cocok panjang byte + Adler-32 antara mirror dan Studio `Edit`, lulus `loadstring` (`OK`); `42/42` script sebelumnya juga lolos kompilasi.
- **Playtest Terkontrol pasca-edit terakhir** (`1066x536` Studio Desktop, 1 pemain, DataManager mock lokal):
  - Pemeriksaan otomatis Client (`ShopModal`, `WeaponSettingsModal`, `TacticalPingWheel` + simulasi ukuran `TextLabel` untuk `1066x536`, `1024x711` iPad `boost=0/6`, `749x381` Phone Landscape, `390x700` Phone Portrait `boost=0/6`): **`SUMMARY: checks=164 failures=0`**.
  - Screenshot pasca-edit terakhir `ShopModal`: `qa_final_shop_desktop.jpg` — judul, deskripsi kartu, dan tombol `29 Robux` / `79 Robux` rapi tanpa kotak gelap atau tumpang tindih bingkai.
  - Screenshot sesi pada build sebelum penyesuaian threshold kartu `h < 236` (`WeaponSettingsModal`, `TacticalPingWheel`, dan In-Flight HUD, yang tidak berubah pada edit terakhir): `qa_weapon_settings_desktop.jpg`, `qa_ping_wheel_desktop.jpg`, `qa_inflight_hud_desktop.jpg`.
  - Log output Studio bersih dari error/warning (`[DataManager] Unpublished Studio: isolated mock data; checkout disabled.`).
- **Penyimpanan & Pembersihan**: Fixture `__TempUIProbe` dihapus; Studio dikembalikan ke `Edit` / 1 pemain / viewport default; place disimpan ke `Fly High.rbxl` (`1.733.267` B, SHA-256 `503CCCD6F007AA68B4CC113BA0B7E637A0CA6633BCE03F8A94619A1B79E1EBF1`, `2026-11-13T22:40:02`).

## Batas QA Tersisa

- Uji fisik langsung di iPad/ponsel pemain (termasuk chat bubble & sentuhan nyata) serta membuka ulang binary `.rbxl` tetap terbuka. Belum di-commit atau push.

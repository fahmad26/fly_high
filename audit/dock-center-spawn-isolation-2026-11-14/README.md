# QA Spawn Balon di Pusat Dermaga & Isolasi Antrean Kru (14 November 2026)

Ringkasan verifikasi pascapilihan **Opsi 1** (`Fly High.rbxl`, Git HEAD `f5aa15d`, Studio Edit/Play Solo Desktop, belum commit/push).

## Perubahan yang diterapkan

1. **`FlightSpace` (`0x74E28E78`, `3.424` B)**
   - Mengubah `SPAWN_FORWARD_DISTANCE = 28` menjadi `0` sehingga balon selalu spawn tepat di tengah lingkaran kayu (`FloorPad.Position.X, 12.5, FloorPad.Position.Z`), jauh dari tepi pasir/laut (`Terrain` `28×28` di `Pod_A..Pod_E` datar penuh pada `Y = 10.00`) serta mempertahankan jarak aman antar-dermaga (`68,88` stud > `BALLOON_CLEARANCE_DISTANCE = 60`).
2. **Relokasi Properti Dermaga `Pod_A..Pod_E` + Pembersihan Jalur `28×28`**
   - `Console` (+ kedua `SignPost` & `SignTopTrim`) dipindah ke sisi kiri-depan (`pad.CFrame * CFrame.new(-20.0, y, -9.5)`, menghadap ke tepi masuk dermaga) pada rumput datar (`10.00..10.17`), berjarak `22,33..22,34` stud dari pusat `FloorPad` serta tetap masuk FOV kamera depan (`42°`) sehingga prompt `StartPrompt` (`MaxActivationDistance = 40`) otomatis tampil saat pemain menghadap dermaga/laut.
   - `PreviewPedestal`, `PreviewPedestalCap`, dan `PreviewBalloon` dipindah ke kanan (`pad.CFrame * CFrame.new(22.5, y, 7.2)`) disertai sinkronisasi atribut `PreviewBase` untuk `BalloonFleetAnimator`.
   - Menggeser `Boulder_10` (`-73, 28` -> `-66, 9.80, 34`), serta `Fern_25`/`28`/`29` & `Flower_7_3`/`7_6` agar tidak berpotongan dengan keranjang `28×28` (`Pod_A..Pod_E` `spawnHits = 0`) maupun papan/pedestal.
3. **Isolasi Antrean & Penjaga Akses Kru**
   - **`PodManager` (`0x4782C184`, `5.796` B):** Menambah helper `isPlayerBusyInFlight(p)` (`U.Flight(p, true)`, `InFlight == true`, `BoardingFlight == true`, atau `FlightBalloon` aktif), menerapkannya di `playersOnPad`, `refresh`, dan `prompt.Triggered` (`U.Near(p, data.console, 40)`), serta memperbarui teks antrean terblokir menjadi `"Tunggu balon di dermaga menjauh"`.
   - **`BalloonManager` (`0x98A395BB`, `21.085` B):** Memagari `LaunchBalloon` agar menolak setiap anggota `players` yang memiliki `InFlight == true` atau `BoardingFlight == true`.
   - **`CrewAccessGuard` (`0x390172CB`, `1.106` B):** Mempersempit batas horizontal menjadi `15.5` saat `q.Y < 10` (`25` saat `q.Y >= 10`) agar pengunjung lobi di sekitar `Console`/`DockPromenade` tidak ikut terteleportasi ke `LobbySpawn`, sementara penyusup keranjang tetap dikeluarkan.

## Hasil QA Aktual

| Pemeriksaan | Lingkungan / Fixture | Hasil aktual | Bukti |
| --- | --- | --- | --- |
| Parity Source Studio <-> Mirror & `loadstring` | Edit `Fly High.rbxl` | 4/4 script (`FlightSpace`, `PodManager`, `BalloonManager`, `CrewAccessGuard`) cocok byte-per-byte & `compile=true`; `LingeringBalloons=0` | Inline Studio + Python |
| Sapuan Geometri `Pod_A..Pod_E` | Edit `MatchmakingPods` | Seluruh `Pod_A..Pod_E` memiliki `terrain28x28=10.00..10.00` dan `spawnCollHits=0 []`; Console & Preview bebas tabrakan | [PodC Edit](PodC_ForwardConsole_EditView.jpg), [PodE Edit](PodE_ForwardConsole_EditView.jpg) |
| Spawn Pusat Dermaga & Prompt Alami | Play Solo (`Fikki2621`) di `Pod_C` | Kamera menghadap depan: `OnScreen=true` `PromptEnabled=true` → tahan `E` meluncurkan `Balloon_Fikki2621` tepat di `(0.00, 12.50, -75.00)`, `Tilt=0.0000°`, `Touch=0 []` | [Prompt Alami Pod_C](Playtest_PodC_PromptVisible.jpg), [Launch Pod_C](Playtest_PodC_LaunchedCenter.jpg) |
| Spawn Pusat Dermaga `Pod_E` (pra-maju Console) | Play Solo (`Fikki2621`) di `Pod_E` | `RootPos=(90.00, 12.50, 15.00)`, `TiltDeg=0.0000°`, `TouchCount=0 []`, `PreviewBobOffset=0.092` | [Launch Pod_E](Playtest_PodE_LaunchedCenter.jpg) |
| Isolasi Hover / Lintas Dermaga (`Pod_C`, `Pod_B`, `Pod_E`, `Pod_D`) | Play Solo (`RootPart.Anchored=true` di dalam kotak `FloorPad` `Y=12.5/15.5/18.5`) | Di atas `Pod_C` (`Y=12.5..18.5`) dan `Pod_B` (`Y=15.5`), pemain berstatus `InFlight=true` selalu ber-`Count='0 / 3 KRU'`, `CurrentPod=nil`, `LaunchBlocked=true`, `Status='Tunggu balon di dermaga menjauh'` | Output Server `execute_luau` |
| Konsol Output Studio | Playtest client/server | 0 error/warning gameplay (`[DataManager] Unpublished Studio: isolated mock data; checkout disabled.`) | `get_console_output` |
| Penyimpanan Place | Lokal Windows (`save_place`) | Tersimpan (`Fly High.rbxl`, `1.741.532` B, SHA-256 `C89DC7FC8257D418C8EF14C62576E56C90D9DDF3F234227BF9B456B023CA81C0`) setelah mode kembali `Edit` | `save_place` + Python SHA-256 |

## Lanjutan: Relokasi Papan Console ke Sisi Masuk Dermaga & Fix Anti-Timpa / Boarding Balon

Setelah pemeriksaan lanjutan pada build yang sama (`Fly High.rbxl`, Git HEAD `f5aa15d`, Studio Edit/Play Solo Desktop, belum commit/push), diterapkan penyesuaian **Opsi 1** untuk papan dermaga serta perbaikan spawn/boarding balon agar tidak menimpa pemain:

### Perubahan Tambahan

1. **Relokasi `Console` ke Rumput Kiri Tepi Jalan Masuk + `StartPrompt` di `FloorPad.PromptAnchor`**
   - Seluruh `Console` (+ `SignPost`×2 & `SignTopTrim`) pada `Pod_A..Pod_E` dipindah mendekat ke sisi rumput datar (`groundMin = 10.00`, dasar tiang ditanam pada `Y = 9.65`) tepat di sebelah jalan masuk beton dan menghadap pemain yang datang:
     - `Pod_A`: `(-6.00, 2.85, 20.00)` (disertai pergeseran `Fern_50` ke `(-71.24, 10.45, 31.97)` agar tidak menutup papan)
     - `Pod_B`: `(-15.00, 2.85, 14.00)`
     - `Pod_C`: `(-18.50, 2.85, 11.00)`
     - `Pod_D`: `(-17.50, 2.85, 10.00)`
     - `Pod_E`: `(-19.80, 2.85, 7.50)`
   - Seluruh `28×28` jejak keranjang balon bebas tumpang tindih dengan papan (`28x28_ov = 0 []`).
   - Memindahkan `StartPrompt` (`MaxActivationDistance = 18`, `RequiresLineOfSight = false`) ke `Attachment` **`FloorPad.PromptAnchor`** (`Position = (0, 3.0, -3.5)`) agar pemain di dalam lingkaran dermaga tetap memunculkan dan memicu `[E] Mulai Penerbangan` sambil menghadap laut.
   - **`PodManager` (`0x5937e1e3`, `5.887` B)** & **`BalloonFleetAnimator` (`0xdb3ca4d3`, `9.353` B):** mencari `StartPrompt` lebih dulu di bawah `FloorPad` (`floorPad:FindFirstChild("StartPrompt", true)`) lalu `Console`, serta memeriksa `U.Near(p, data.pad, 14)` di `prompt.Triggered`.
2. **Perbaikan Anti-Timpa & Keandalan Boarding Balon**
   - **`BalloonManager` (`0x19859da4`, `22.572` B):** Saat `LaunchBalloon`, `root.Anchored` dikunci `true` dan seluruh kru dilepas dari kursi (`Unseat`, reset `Sit`/`PlatformStand`/`GettingUp`), dinaikkan lalu di-anchor pada posisi kabin (`start + offset`, `offset.Y = +4.8` dengan spasi horizontal 5 stud) **sebelum** model balon diparent ke `workspace`; meloloskan remote `"BoardReady"` dari rate-limit `actionRate(0.2s)`; menambah `finishBoarding(fd)` (serta auto-settle `boardingAutoSettle` setelah 4 detik) untuk menempatkan kru relatif terhadap `fd.root.CFrame`, melepas `fd.root.Anchored = false` sesudah `0.2s` dan `SetNetworkOwner(nil)`, lalu mengirim `"CompleteBoarding"` disertai `targetCF`.
   - **`FlightHUDController` (`0x88cf36f7`, `25.107` B):** Menangani `"PrepareBoarding"` (membersihkan status duduk) dan `"CompleteBoarding"` (reset `Sit`/`PlatformStand`/`GettingUp`, dan memindahkan `HumanoidRootPart.CFrame` ke `payload` jika karakter keluar atau `rel.Y < 1.2` terhadap `BasketFloor`).

### Hasil QA Lanjutan

| Pemeriksaan | Lingkungan / Fixture | Hasil aktual | Bukti |
| --- | --- | --- | --- |
| Parity Source & `loadstring` | Edit `Fly High.rbxl` | 4/4 script (`PodManager` `0x5937e1e3`/`5.887` B, `BalloonFleetAnimator` `0xdb3ca4d3`/`9.353` B, `BalloonManager` `0x19859da4`/`22.572` B, `FlightHUDController` `0x88cf36f7`/`25.107` B) cocok byte-per-byte & `compile=true`; `LingeringBalloons=0` | Inline Studio + Python |
| Visual Edit Console Opsi 1 | Edit `MatchmakingPods` (`Pod_A..Pod_E`) | Papan berdiri rata di rumput sebelah pintu masuk (`groundMin=10.00`, `postBot=9.65`), `28x28_ov=0 []`, bebas beton & tanaman | [PodA Edit](PodA_EntryConsole_EditView.jpg), [PodC Edit](PodC_EntryConsole_EditView.jpg), [PodE Edit](PodE_EntryConsole_EditView.jpg) |
| Spawn, Boarding & Kemudi `Pod_C` | Play Solo (`Fikki2621`) di `Pod_C` | `CurrentPod=Pod_C`, `prompt.Enabled=true`, `dist=3.63`, `PlayerGui.ProximityPrompts.Prompt` aktif (`ButtonText="E"`, `ActionText="Mulai Penerbangan"`, `textTr=0`); tahan `E` meluncurkan & menaikkan pemain ke dalam keranjang: `221` sampel Client & `1002` sampel Server mencatat `minClr=2.531` stud (`minHrpY=15.03` vs `BasketFloor.Y=12.50`), `maxTilt=0.0000°`, `InBasket=true`, `Boarding=nil`, `InFlight=true`, `CurPod=nil`, `Count='0 / 3 KRU'`; lalu jalan `W` + `E` duduk bersih di `HelmSeat` (`sit=true`, `rel=(0.00, 3.75, -10.00)`) | [Deck Pod_C](Playtest_PodC_DeckView.jpg), [Boarded Pod_C](Playtest_PodC_BoardedClean.jpg) |
| Spawn & Boarding `Pod_A` | Play Solo (`Fikki2621`) di `Pod_A` | Tahan `E`: `237` sampel Client (`minClr=2.531`, `minHrpY=15.03`, `maxTilt=0.0000°`) & `1054` sampel Server (`minClr=2.561`, `InBasket=true`, `BalloonWorldOv=0 []`, `CurPod=nil`, `Count='0 / 3 KRU'`), bebas tabrakan terhadap papan masuk, `Boulder_10`, dan `Fern_50` | [Boarded Pod_A](Playtest_PodA_BoardedClean.jpg), [Exterior Pod_A](Playtest_PodA_ExteriorClean.jpg) |
| Konsol Output Studio | Playtest client/server `Pod_A` | 0 error/warning gameplay (`[DataManager] Unpublished Studio: isolated mock data; checkout disabled.`) | `get_console_output` |
| Penyimpanan Place Terbaru | Lokal Windows (`save_place`) | Tersimpan kembali ke `Edit` (`Fly High.rbxl`, `1.742.017` B, SHA-256 `BC95E4CBB2231D60CAB674EC5EA50C57FBCCD455F8A0DE312529C5455F3D7E78`) | `save_place` + Python SHA-256 |

### Batas QA Tersisa

- Binary `.rbxl` tersimpan (`1.742.017` B) belum dibuka ulang di Studio setelah `save_place`.
- `screen_capture` viewport Playtest Studio tidak menampilkan overlay `PlayerGui.ProximityPrompts`; kemunculan serta pemicuan `PromptAnchor.StartPrompt` dibuktikan melalui inspeksi `PlayerGui.ProximityPrompts.Prompt` aktif (`Enabled=true`, `textTr=0`) dan input `E` nyata di `Pod_C` & `Pod_A`.
- Uji launch `[E]` langsung pasca-relokasi akhir dijalankan pada `Pod_C` & `Pod_A` (bukan `Pod_B`/`Pod_D`/`Pod_E` pada pass lanjutan ini), serta simulasi 2–3 pemain bersamaan (`Start Server + 2/3 Players`) saat spawn & antrean belum diuji secara langsung.
- Pengujian `Pod_C` + `Pod_A` memverifikasi perilaku `Spawn` → `Boarding` → `HelmSeat` (`Pod_C`), belum termasuk pendakian penuh ke awan atau tombol gas lanjutan setelah duduk.

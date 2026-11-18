# QA Kondisi Kematian Kru & Ping Taktis / Ghost Spotter (`2026-11-19`)

- **Run ID:** `death-ping-2026-11-19`
- **Waktu:** `2026-11-19 00:31–00:49 WIB` (`baseline` selesai `2026-11-18T17:31:30Z`, `final` Run 5 selesai `2026-11-18T17:49:07Z`)
- **Lingkungan:** Roblox Studio `6e240f19-beea-4042-9663-5e7d94ab1350` (`Fikki2621's Place: 11152026_1`, `placeId=97043730132219`, `universeId=10776821830`), `Start Server & Players` **2 klien lokal** (`Player1` & `Player2`, Windows)

## Ringkasan Temuan Baseline (`29/32 PASS`) & Perbaikan

Log baseline ([baseline-results.json](baseline-results.json)) menjalankan **32 cek** dan menemukan 2 bug nyata pada alur mati/ghost + ping serta 1 ketidaksesuaian timing/skrip uji:

1. **Roda Ping (`TacticalPingWheel`) tetap terbuka saat pemain mati / menjadi ghost (`wheel_closes_on_death` FAIL)**
   - **Akar masalah:** `WeaponClientController.luau` memanggil `HUDMotion.SetVisible(wheel, false)` setiap frame saat mati/selesai terbang, membatalkan task penutupan `0.14` detik secara berulang sehingga roda ping dan scrim tetap menggantung.
   - **Perbaikan ([WeaponClientController.luau](../../audit/sources/StarterPlayer/StarterPlayerScripts/WeaponClientController.luau)):** Penutupan `TacticalPingWheel` dibuat idempoten (`if (ghost or not inFlight) and wheel.Visible and wheel:GetAttribute("HUDMotionClosing") ~= true`), `pingInput()` (`[V]`) dibatasi hanya saat `InFlight == true`, ditambahkan guard `isGhostNow()` pada `ghostSpot()`, reset `ghostHintToken`/`GHOST_HINT`/`lastGhostSpot` saat keluar dari mode arwah, dan batas auto-aim spot `<= 265` stud.

2. **Obstacle di ketinggian `5.500 km` tidak ter-stream di klien arwah (`5500km_ghost_obstacle_streamed_in` FAIL)**
   - **Akar masalah:** Setelah pemain arwah respawn di Lobby sementara balon kru melaju di atas `4.100 km` (di luar radius `StreamingTargetRadius = 1024`), rintangan di sekitar balon tidak direplikasi ke klien arwah sehingga ghost spotter gagal membidik bahaya jarak jauh.
   - **Perbaikan:**
     - [`BalloonManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/BalloonManager.luau): Menambahkan helper `releaseGhostFocus(fd, p)`, menyetel `p.ReplicationFocus = fd.root` ketika `FlightGhost` bernilai `true`, menambahkan listener `p.CharacterAdded` untuk meng-anchor `fd.ghostParkedChars[p]` di Lobby agar lantai Lobby yang ter-stream out pada ketinggian tinggi tidak memicu loop mati ke Void `-500`, serta membersihkan `ReplicationFocus = nil` + `RequestStreamAroundAsync` + unanchor saat `EndFlight(fd, false)`, `b.Destroying`, dan `PlayerRemoving` (`fd.ghostParkedChars[p] = nil`).
     - [`PalaceArrival.luau`](../../audit/sources/ServerScriptService/FlyHighServer/PalaceArrival.luau): Membersihkan `if p.ReplicationFocus == fd.root then p.ReplicationFocus = nil end` dan `fd.ghostParkedChars[p] = nil` ketika anggota kru mendarat/bangkit di `CloudHavenDock`.

3. **Toleransi jarak & jitter cooldown ping arwah di server**
   - **Perbaikan ([TetherManager.luau](../../audit/sources/ServerScriptService/FlyHighServer/TetherManager.luau)):** Memperlebar batas jarak server Ghost/Ping dari `300 -> 340` stud serta menyetel `U.RateLimiter(1.75)` agar kompatibel dengan jitter cooldown klien `2.0s`.

## Hasil QA Final 2 Klien (`37/37 PASS`)

- **Run 5 ([final-results.json](final-results.json)):** **`success = true`**, **`37/37` PASS**, `0` error server, `0` error/warning klien (`Player1` & `Player2`).
- Seluruh cek utama lolos:
  - Ping kru hidup (`living_v_opens_wheel`, `living_quick_ping_received_alive`, `living_quick_ping_text_matches`)
  - Mati ke arwah & roda tertutup (`crew_marked_dead_and_ghost`, `wheel_closes_on_death`, `ghost_panel_visible_pre_respawn`, `ghost_hint_visible_no_overlap`, `ghost_camera_tracks_balloon_pre_respawn`)
  - Spot arwah & cooldown sebelum respawn (`ghost_spot_click_creates_marker_for_alive`, `ghost_spot_banner_for_alive`, `ghost_spot_hint_feedback_die`, `alive_offscreen_arrow_visible`, `ghost_cooldown_message`)
  - Pasca respawn & `5.500 km` (`crewDie_respawned_in_lobby`, `hud_survives_respawn`, `camera_stays_on_balloon_after_respawn`, `ghost_v_key_spots_post_respawn_400km`, `5500km_ghost_balloon_streamed_in`, `5500km_ghost_focus_is_balloon`, `5500km_ghost_parked_char_anchored_safe`, `5500km_ghost_obstacle_streamed_in`, `5500km_ghost_spot_reaches_alive`, `dead_sees_alive_quick_ping`, `ghost_panel_no_overlap_banner`, `server_rejects_quick_ping_from_ghost`, `moving_far_ghost_spot_delivered_or_matches_feedback`)
  - Game over & cleanup focus/anchor (`all_dead_ends_flight`, `post_gameover_replication_focus_cleared`, `post_gameover_parked_char_unanchored`, `lobby_v_does_not_open_wheel`, `ghost_panel_hides_after_gameover`).

## Parity, Cleanup & Penyimpanan Place

- **Parity & Compile (`Edit`, setelah seluruh perbaikan sesi 19 Nov):** `65/65` skrip compile bersih (`compileErrors = []`), `65/65` panjang byte UTF-8 ternormalisasi antara Studio dan `audit/sources/` cocok (`Diffs = `). SHA-256 prefix file yang diubah pada scope ini:
  - `BalloonManager.luau`: `1d80f3affe29eccc` (`33.768` B)
  - `PalaceArrival.luau`: `d19d27e096d0e40c` (`5.466` B)
  - `TetherManager.luau`: `f7c2167912acb972` (`25.661` B)
  - `WeaponClientController.luau`: `ff00839e80fa0a70` (`51.029` B)
- **Cleanup Studio:** Seluruh objek sementara `_QA_*` dihapus (`leftovers = []`), kembali ke mode `Edit`, `playerCount = 0`, `TestService.NumberOfPlayers = 1`, `CameraType = Fixed` pada `(0, 48, 25)` menghadap `(0, 14, -5)`, `StreamingEnabled = true`, `StreamingTargetRadius = 1024` — terverifikasi visual di [edit-restored.jpg](edit-restored.jpg). **Catatan belum dapat dipulihkan:** panggilan `StudioTestService:ExecuteMultiplayerTestAsync(2, ...)` membuat pilihan tombol Play/Test pada Next-Gen Ribbon (`sabuiltin_Ribbon.rbxm`) tetap tertinggal di `StartServer` (`2` pemain) meskipun `start_stop_play` dan `TestService.NumberOfPlayers = 1` dijalankan; belum ada API Studio/MCP resmi untuk mereset dropdown Ribbon tersebut secara terprogram sehingga perlu dikembalikan manual ke mode `Test` (`Play`) di Studio.
- **Simpan Place (`save_place`):** Tersimpan ke `E:/Antigravity/Fly High/Fly High.rbxl` (`3.533.855` B, `2026-11-19 01:29:28 WIB`, SHA-256 `5FE2544BD90E6C3BFEA64AC64BD6DBCE092C0628FF0447494969CC4A94596FCE`). Binary `.rbxl` belum dibuka ulang pada sesi pemeriksaan terpisah, dan perubahan lokal belum dicommit/dipush.

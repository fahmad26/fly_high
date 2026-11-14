# Audit Perapihan Sambungan Bulatan ke Jalan & Tepi Dermaga (14 November 2026)

## Identitas Build & Lingkup

- **Tanggal:** 14 November 2026 (Asia/Jakarta)
- **Git HEAD:** `f5aa15d` (working tree kotor; perubahan belum di-commit atau di-push)
- **Berkas tersimpan:** `Fly High.rbxl` (`1.819.938` byte, SHA-256 `45BC17B8A7AC2A624E3149F9B768FCE66EF5AD83D7CEC5AB5A2A9799FE90576B`)
- **Perubahan script:** `0` (`script_grep` memastikan `CoastalEdging`, `PromenadeSurface`, `DockPromenade`, dan `SculptedStoneBase` tidak memiliki referensi di source Luau gameplay)
- **Lingkup objek Studio (`Workspace.FlyHighLobby`):**
  - `ArrivalGarden.CoastalEdging`: seluruh `12` balok gerigi luar disembunyikan (`Transparency = 1`, `CanCollide = false`, `CanTouch = false`, `CanQuery = false`, `CastShadow = false`), mempertahankan `SculptedStoneBase` (`AG_R = 12.00`, `AG_TOP_Y = 10.525`).
  - `PromenadeSurface`: dibangun ulang via [build-surface.luau](build-surface.luau) menghasilkan `6141` part anak (`ModeCheck`: `PromenadeSurface=6141`), mempertahankan penanda huruf dermaga `DockLetter_1..5` (`A..E`) pada `r = 76.95`, `Y = 10.380`.
  - `DockPromenade.JunctionSupportCollider`: `724` wedge kolider penopang transparan (`Transparency = 1`, `CanCollide = true`) di bawah fillet simpang dan ramp masuk `ArrivalGarden`.

## Akar Masalah Sebelumnya

1. **Hub bulat `ArrivalGarden` (`(0, 35)`):** `12` balok miring `CoastalEdging` menonjol keluar menyerupai roda gigi di sekeliling lingkaran batu, sementara jalur lurus `Main` berhenti rata di `Z ≈ 23` sehingga menyisakan celah rumput segitiga di kedua sisi sambungan.
2. **Undakan elevasi & celah rumput (`Main <-> Ring` & `Ring <-> Cabang B/C/D`):** permukaan `Main` (`10.435`) lebih tinggi `+0.06` stud dari `Ring` (`10.375`), dan cabang `Pod_A..E` (`10.455`) lebih tinggi `+0.08` stud dari `Ring`, disertai celah nat paver tanpa alas menerus sehingga warna rumput hijau tampak menembus sela-sela ubin.
3. **Sudut simpang `T` & belokan `A/E`:** `InnerCurb` di `Main_T` dan `OuterCurb` di simpang `B/C/D` berhenti mendadak tanpa lengkung tangen penuh, sementara belokan `Pod_A`/`Pod_E` memiliki kerumunan sambungan miring.
4. **Ujung cabang ke lingkaran dermaga `Pod_A..E`:** ujung jalan cabang sebelumnya memotong lurus dan tumpang tindih ke atas lingkaran kuningan `BrassRim` (`POD_RIM_R = 11.15`) serta dek kayu `TimberDeck`.

## Implementasi yang Diterapkan

1. **Penyatuan elevasi & alas nat penuh (`PAVER_TOP_Y = 10.375`):**
   - Menyamakan tinggi seluruh permukaan paver (`PAVER_TOP_Y = 10.375`, `PAVER_THICK = 0.070`), kanstin (`CURB_TOP_Y = 10.375`, `CURB_THICK = 0.420`, lebar `CURB_W = 0.45`), dan alas mortar/grout menerus `ContinuousBed` (`BED_TOP_Y = 10.335`, `BED_THICK = 0.340`) di sepanjang `Main`, `Ring`, `Elbow`, serta kelima cabang `Pod_A..E`.
2. **Transisi mulus lingkaran `ArrivalGarden` ke `Main`:**
   - Memasang kanstin lingkar 36-segmen `ArrivalCurb` (`r ∈ [12.00..12.45]`) yang menyambung mulus dengan kanstin fillet `RF_AG = 2.50` pada sudut tangensi `THETA_AG`, serta ramp landai dari `AG_RAMP_START_Z = 18.00` (`10.375`) naik menuju kontur chord lingkaran `zSouth(x) = 35 - sqrt(12^2 - x^2)` (`10.525`).
3. **Simpang `T` tangensial & `Elbow` bersih (`Main_T`, `B/C/D`, `A/E`):**
   - Menghentikan `InnerCurb` (`THETA_MAIN_T`) dan `OuterCurb` (`THETA_OUT_T`) tepat di titik singgung busur fillet `RF_MAIN_T = RF_OUT_T = 2.50`, lalu mengisi sudut dengan `FilletCurb`, `FilletPaver` (nat `0.08`), `ContinuousBed`, serta sub-divisi segmen busur `Ring` dengan garis nat `0.10` menerus.
   - Membangun ulang belokan `Pod_A` dan `Pod_E` dengan `10` segmen `ElbowPaver` mulus per lajur (`1` quad per ubin) dan `24` segmen `ElbowCurb`/`ContinuousBed` hingga batas tangen `ELBOW_EX = sqrt(75^2 - 25)`.
4. **Pemangkasan presisi ujung jalan ke lingkaran `Pod_A..E`:**
   - Memangkas ujung paver dan alas tiap cabang mengikuti kurva `BrassRim`: `vEnd(u) = 90 - sqrt(11.15^2 - u^2)` agar tidak menutupi `TimberDeck` maupun memutus cincin kuningan, dilengkapi `PodFilletCurb` (`RF_POD = 1.80`, `THETA_POD`) yang meruncing (`0.45 -> 0.35 -> 0.02`) rata ke bibir `BrassRim`.

## Hasil Verifikasi

### 1. Perbandingan Visual Sebelum & Sesudah (7 Sambungan + Overview `Edit`)

| Lokasi | Sebelum | Sesudah | Ringkasan Hasil |
| --- | --- | --- | --- |
| `ArrivalGarden` <-> `Main` | [before_arrival_hub.jpg](before_arrival_hub.jpg) | [after_arrival_hub.jpg](after_arrival_hub.jpg) | 12 gerigi hilang; kanstin lingkaran, fillet `R=2.50`, & ramp menyatu mulus |
| `Main` <-> `Ring` (`Main_T`) | [before_main_ring_t.jpg](before_main_ring_t.jpg) | [after_main_ring_t.jpg](after_main_ring_t.jpg) | Tinggi rata `10.375`, fillet kiri/kanan simetris, nat menerus tanpa rumput |
| `Elbow` <-> `Pod_A` | [before_pod_a_elbow.jpg](before_pod_a_elbow.jpg) | [after_pod_a_elbow.jpg](after_pod_a_elbow.jpg) | Ubin belokan bersih & ujung cabang pas mengikuti lengkung `BrassRim` `Pod_A` |
| `Ring` <-> `Pod_B` | [before_pod_b_junction.jpg](before_pod_b_junction.jpg) | [after_pod_b_junction.jpg](after_pod_b_junction.jpg) | Simpang `T` luar dan ujung `BrassRim` `Pod_B` rapat & sejajar |
| `Ring` <-> `Pod_C` | [before_pod_c_junction.jpg](before_pod_c_junction.jpg) | [after_pod_c_junction.jpg](after_pod_c_junction.jpg) | Kanstin & fillet `Pod_C` menyatu mulus; pelat huruf `C` (`r=76.95`) terjaga |
| `Ring` <-> `Pod_D` | [before_pod_d_junction.jpg](before_pod_d_junction.jpg) | [after_pod_d_junction.jpg](after_pod_d_junction.jpg) | Simpang `T` luar & fillet `Pod_D` simetris tanpa takik rumput |
| `Elbow` <-> `Pod_E` | [before_pod_e_elbow.jpg](before_pod_e_elbow.jpg) | [after_pod_e_elbow.jpg](after_pod_e_elbow.jpg) | Belokan `10`-ubin bersih & ujung `Pod_E` pas terhadap `BrassRim` |
| Overview akhir `Edit` | — | [after_edit_overview.jpg](after_edit_overview.jpg) | `PromenadeSurface=6141`, `JSC=724`, kamera default `(0,48,25)->(0,12,-55)` |

### 2. Pengujian Jalan Langsung `Play Solo` (`WalkTour`, `CornerWalk`, & Console)

- **Lingkungan:** `Play Solo` 1 pemain di Roblox Studio pada PC Windows (`start_stop_play(is_start=true)`).
- **`WalkTour` (`25/25` waypoint):** `WalkTour complete: waypoints=25 stuck=0 Yrange=[11.96..12.90]`, seluruh titik (`Spawn_AG`, `AG_Ramp`, `Main_Mid`, `Main_T_Fillet`, `Ring_Center_N`, `PodC_Throat`, `Pod_C`, `PodC_Exit`, `Ring_NW`, `PodB_Throat`, `Pod_B`, `PodB_Exit`, `Ring_W_Elbow`, `PodA_Throat`, `Pod_A`, `PodA_Exit`, `Ring_SW_Arc`, `Ring_N_Arc`, `Ring_NE_Arc`, `PodD_Throat`, `Pod_D`, `PodD_Exit`, `Ring_E_Elbow`, `PodE_Throat`, `Pod_E`) tercapai dengan `hp=100` dan `CurPod` aktif sesuai dermaga `Pod_A..Pod_E`.
- **`CornerWalk` (`5/5` sudut fillet & hub):** `CornerWalk stuck=0` (`Fillet_PodE_L ok=true`, `Fillet_PodD_Corner ok=true`, `Fillet_MainT_R ok=true`, `AG_Corner_R ok=true`, `AG_Center ok=true`).
- **Console Output (`get_console_output`):** hanya `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.` (`0` error dan `0` warning gameplay).

### 3. Batas Verifikasi

- Pengujian jalan dilakukan pada fixture `Play Solo` 1 pemain desktop Windows; belum mencakup review visual manusia langsung di perangkat mobile/tablet.
- Place telah disimpan via `save_place` ke `Fly High.rbxl`; file `.rbxl` hasil simpan belum dibuka ulang di sesi Studio terpisah, dan perubahan belum di-commit atau di-push ke Git.

## Cleanup & Status Akhir

- `start_stop_play(is_start=false)` dijalankan; `get_studio_state` kembali ke `Edit`, kamera dipulihkan ke `(0, 48, 25) -> (0, 12, -55)` (`CameraType=Fixed`), `ModeCheck=Fixed PromenadeSurface=6141 JSC=724` ([after_edit_overview.jpg](after_edit_overview.jpg)).
- `save_place` sukses (`Saved to the local place file`, `1.819.938` byte, SHA-256 `45BC17B8A7AC2A624E3149F9B768FCE66EF5AD83D7CEC5AB5A2A9799FE90576B`).

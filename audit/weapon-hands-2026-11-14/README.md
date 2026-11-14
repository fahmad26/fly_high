# QA Senjata Tampak Tangan 1P & 3P — 14 November 2026

Implementasi **Opsi 1 (First-Person ViewModel Hands)** dan **Opsi 3 (Third-Person Two-Handed Character Hold)** untuk `Pistol` (`Handgun`) dan `AK47` (`AK-47`) pada `Fly High`.

## Perubahan

- **Template Senjata (`ReplicatedStorage.FlyHigh.Templates.Weapons`):**
  - `Pistol`: `Grip = CFrame.new(0, -0.18, 0.08)`, `Handle.LeftHandGripTarget.Position = Vector3.new(-0.06, -0.10, 0.04)`.
  - `AK47`: `Grip = CFrame.new(0, 0.05, 0.02) * CFrame.Angles(math.rad(-11.5), 0, 0)`, `WoodHandguard.LeftHandGripTarget.Position = Vector3.new(-0.04, -0.16, 0.35)`.
- **[`WeaponPresentation.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/WeaponPresentation.luau)** (`23.100` B, SHA-256 `35317d38b9e2edafc9b9947f608797ad0720b253c5fd4079fddb02e600cb9bfc`):
  - Mengupgrade `FlyHighHUD.WeaponView` menjadi `WorldModel` dengan model senjata ternormalisasi dan rig tangan R15 standar (`ViewRigFallback` instan + `ViewRig` asinkron sesuai warna kulit & `Shirt` pemain lewat `CreateHumanoidModelFromDescriptionAsync`).
  - Penempatan dua tulang IK lengan kanan/kiri (`poseRigArms`) per profil (`Pistol` & `AK47`), animasi recoil saat tembak (`triggerShot`), serta kemiringan reload (`setReloading`).
- **[`WeaponManager.luau`](../../audit/sources/ServerScriptService/FlyHighServer/WeaponManager.luau)** (`12.790` B, SHA-256 `a653c65490b47ef98ed6c31bea6d13abe928a222b78424adcc643681831f08b4`):
  - Memasang `FlyHighRightAimIK` (`IKControlType.Transform`) ke `UpperTorso.RightAimTarget` dan `FlyHighLeftSupportIK` (`IKControlType.Position`) ke `LeftHandGripTarget`.
  - Menggunakan `measureArmReach` berbasis jarak sendi bahu-siku-pergelangan (`RightShoulderRigAttachment` -> `RightElbowRigAttachment` -> `RightWristRigAttachment`) pada `HOLD_PROFILES.Pistol` agar cocok untuk avatar chibi pendek maupun R15 standar, dengan `HOLD_PROFILES.AK47` tetap mempertahankan pose dua tangan sebelumnya.
  - Membersihkan seluruh `IKControl` dan `RightAimTarget` saat unequip, mati (`Humanoid.Died`), `CharacterRemoving`, drop `[G]`, maupun `CleanupPlayer`.

## Hasil QA (Studio Windows · `Play Solo`)

- **Kompilasi & Sinkronisasi:** `45/45` script Studio lolos `loadstring` (`compileFail = 0`). Kedua script yang diubah (`WeaponPresentation.luau`, `WeaponManager.luau`) cocok byte-per-byte antara Studio dan mirror `audit/sources/` (catatan: 8 file tidak disentuh lain memiliki selisih baseline 1 byte newline / `ServerUtils` yang sudah ada sebelum tugas ini).
- **Boot & Kebersihan Edit:** Boot `Play Solo` bersih menghasilkan `0` error gameplay (hanya `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.`). Mode `Edit` dipulihkan dengan `leftover = 0`, `1` pemain, dan kamera `(0, 48, 25) -> (0, 12, -55)`. Place tersimpan ke [`Fly High.rbxl`](../../Fly High.rbxl) (`1.833.197` B, SHA-256 `ecd8f1637c39caa1ffbce9b5d3002fed8d96a0a09115ecec8b9d435fcb0898ff`).
- **Pistol 1P & Reload (Pasca-Edit Final):**
  - Pengambilan nyata `[E]` di `WeaponRack1`: `WeaponView` tampil `1457, 269` (`472×472`), `ViewRig` memakai sleeve hoodie `855759986` (`qa_pistol_1p_final.jpg`).
  - Klik kiri mengurangi `CurrentMag` ke `7`; `[R]` mengisi ulang ke `8 / ∞` (`qa_pistol_reload_complete.jpg`).
- **Pistol 3P (`Chibi` & `R15 Standar`):**
  - Avatar chibi live `Fikki2621` terverifikasi `FlyHighRightAimIK = true`, `FlyHighLeftSupportIK = true`, `RightAimTarget = true`; dumpy `Standard R15` berskala formula identik `WeaponManager` saat terbang (`586 km`) menghasilkan `dLDist = 0.04` stud (`qa_pistol_3p_final.jpg`); perbandingan pose chibi (`HumanoidDescription` `Fikki2621`) + R15 standar tercatat pada `qa_pistol_3p_chibi_r15_tune.jpg`.
- **Drop Aktif `[G]` Saat Balon Aktif (`b = true`):**
  - **Pistol:** `b = true`, `rack1Occ = true`, `tool = nil`, `FlyHighRightAimIK = false`, `FlyHighLeftSupportIK = false`, `RightAimTarget = false`, `WeaponView = nil`, `CameraMode = Classic`, `Head.LocalTransparencyModifier = 0.00`.
  - **AK-47 (fixture `WeaponRack2.CurrentWeapon = "AK47"`):** `b = true`, `rack2Occ = true`, `tool = nil`, seluruh IK/target dibersihkan, lalu fixture dihapus dan dikembalikan ke `nil`.
- **AK-47 1P & 3P:**
  - Pasca-edit final: pengambilan nyata `[E]` di `WeaponRack2` terverifikasi `tool = true`, `mag = 29` pasca-tembak, `FlyHighRightAimIK = true`, `FlyHighLeftSupportIK = true`, `RightAimTarget = true`, `WeaponView = true` (`ViewRig`, `1140, 217`, `597×597`).
  - Bukti visual 1P, reload `30 / ∞`, dan 3P ganda chibi + R15 (`Fikki2621` `rDist=0.02, lDist=0.64`; R15 `rDist=0.02, lDist=0.49` di `538–1.190 km`) dari sesi pra-tuning akhir `Pistol` (kode `WeaponPresentation` & profil `AK47` tidak berubah) tersimpan di `qa_ak47_1p.jpg`, `qa_ak47_reload_complete.jpg`, dan `qa_ak47_3p.jpg`.
- **Layout Responsif HUD (`HUDLayout`):**
  - Evaluasi batas `WeaponView` terhadap `WeaponFrame`, `MobileShootButton`, `ReloadButton`, `DropButton`, dan `JumpPanel` di `1920×1080` (`Desktop`), `1024×768` (`Tablet Touch`), `844×390` (`Phone Landscape Touch`), `390×844` (`Phone Portrait Touch`), plus viewport live `2090×752`: `WeaponView` transparan (`ZIndex = 0`) tetap bebas menindih kontrol HUD di keempat profil perangkat.

## Artefak Gambar

- [`qa_pistol_1p_final.jpg`](qa_pistol_1p_final.jpg)
- [`qa_pistol_reload_complete.jpg`](qa_pistol_reload_complete.jpg)
- [`qa_pistol_3p_final.jpg`](qa_pistol_3p_final.jpg)
- [`qa_pistol_3p_chibi_r15_tune.jpg`](qa_pistol_3p_chibi_r15_tune.jpg)
- [`qa_ak47_1p.jpg`](qa_ak47_1p.jpg)
- [`qa_ak47_reload_complete.jpg`](qa_ak47_reload_complete.jpg)
- [`qa_ak47_3p.jpg`](qa_ak47_3p.jpg)
- [`qa_pistol_1p_polished.jpg`](qa_pistol_1p_polished.jpg) (Pass 2 polesan tangan 1P Pistol)
- [`qa_ak47_1p_polished.jpg`](qa_ak47_1p_polished.jpg) (Pass 2 polesan tangan 1P AK-47)
- [`qa_pistol_1p_viewmodel.jpg`](qa_pistol_1p_viewmodel.jpg) (Pass 3 — Opsi A Camera ViewModel Skinned PBR Arms, Pistol)
- [`qa_ak47_1p_viewmodel.jpg`](qa_ak47_1p_viewmodel.jpg) (Pass 3 — Opsi A Camera ViewModel Skinned PBR Arms, AK-47)
- [`qa_ak47_1p_near_railing.jpg`](qa_ak47_1p_near_railing.jpg) (Pass 3 — CQB wall pull-back mepet pagar gondola, AK-47)

## Pass 2 — Polesan Bentuk Tangan ViewModel 1P (14 November 2026)

Menindaklanjuti masukan bentuk tangan 1P yang kaku, silau putih, dan ujung jari/pergelangan mencuat pada tangkapan dekat Handgun/AK-47:

- **[`WeaponPresentation.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/WeaponPresentation.luau)** diperbarui menjadi `27.654` B (`adler32 = 0xddb0107c`, SHA-256 `94525828ee1ef1033d3ffa049cda7780e2e81ac295ab0a32bc4ffd7728c4f688`, identik byte-per-byte Studio ↔ mirror, `edSame = true`, `45/45` script Studio `compileFail = 0`):
  - **Tangan Terpahat (`makeHandPiece` + `attachSculptedHands`):** `LeftHand`/`RightHand` R15 blok disembunyikan (`Transparency = 1`) dan digantikan model `LeftViewHand`/`RightViewHand` ber-pivot tepat di pusat grip (`GripPivot` di `(0,0,0)` agar `Model:PivotTo` tidak menggeser part menyamping) dari `SpecialMesh` halus (`Head` untuk `PalmCore`, `Sphere` elipsoid untuk `WristBridge`, `WebbingBridge`, `OuterKnuckle`, `ThumbBase`/`ThumbTip`, `IndexFinger`/`IndexWrap`, dan `FingerWrap1..3`) ber-warna kulit pemain aktif.
  - **Proporsi Lengan & Penempatan Grip (`viewProfiles` & `buildStyledArmRig`):** lengan R15 dirampingkan (`WidthScale = 0.23, DepthScale = 0.23, HeightScale = 0.92`) dengan `Shirt` pemain tetap terpasang; `poseRigArms` menempatkan bahu pada ruang `Handle` agar lengan kiri `AK47` yang memegang `WoodHandguard` (`handOffset` + `76°` roll, `scale = 1.18`) tidak melipat membentuk sudut V ke bawah; `Pistol` dinaikkan tepat membungkus tang atas grip (`Y = -0.13..-0.14`, `Z = 0.21..0.27`, kemiringan `-18..-20°`) dengan jempol kiri menyusur sisi kiri frame.
  - **Pencahayaan Kontur Alami (`ViewportFrame`):** `Ambient = (92, 86, 84)`, `LightColor = (165, 158, 148)`, dan `LightDirection = (0.45, -0.82, -0.55)` dari arah atas-kiri belakang kamera menjaga warna kulit hangat alami bebas whiteout `#FFFFE2` sambil memberi kedalaman bayangan antar jari. `WeaponView` (`RightEdge = 0.74`, `WidthCap = 0.48`/`0.68`, `CompactScale = 0.49`/`0.69`, `FOV = 42`) dan `WeaponManager.luau` (`12.790` B) tidak diubah.
- **QA Pasca-Edit Final (`Play Solo` Studio Windows):**
  - Boot bersih `0` error gameplay (hanya `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.`), console pasca-uji juga `0` error.
  - **`AK47` 1P (`qa_ak47_1p_polished.jpg`):** uji di ketinggian `altY = 34.6`, `WeaponRack2` fixture `"AK47"` -> `[E]` menghasilkan `tool = AK47`, `rig = ViewRig`, `Shirt = http://www.roblox.com/asset/?id=855759986`, `WeaponView = 597×597`, klik tembak menurunkan `AmmoLabel` `30 / ∞` -> `29 / ∞`, serta drop aktif `[G]` berhasil (`b = true, r2Cur = AK47, tool = nil`).
  - **`Pistol` 1P (`qa_pistol_1p_polished.jpg`):** `[E]` di `WeaponRack1` menghasilkan `tool = Pistol`, `rig = ViewRig`, `Shirt = http://www.roblox.com/asset/?id=855759986`, `WeaponView` pada `1457, 269` (`472×472`, `AmmoLabel = 8 / ∞`), tembak klik kiri -> `7 / ∞`, reload `[R]` -> `8 / ∞`, dan drop `[G]`.
  - Pemulihan `Edit` terverifikasi: `leftover = 0`, kamera default `(0, 48, 25) -> (0, 12, -55)`, fixture `WeaponRack2` bersih; place tersimpan ke [`Fly High.rbxl`](../../Fly High.rbxl) (`1.834.239` B, SHA-256 `fc1cfc39c1e5a160ab4b7af3b3c5610f9cb3ac56ddeb2c114d611dfa9703366f`, belum dibuka ulang/commit/push).
  - *Batas QA Pasca-Edit Pass 2:* 3P IK (`WeaponManager`) dan rumus responsif `HUDLayout` antar 4 profil layar (`1920×1080`, `1024×768`, `844×390`, `390×844`) memakai data verifikasi Pass 1 karena `WeaponManager`, `HUDLayout`, maupun atribut ukuran `WeaponView` (`RightEdge`, `WidthCap`, `CompactScale`, `fieldOfView`) tidak diubah pada Pass 2; perangkat fisik & multi-klien belum diuji.

## Pass 3 — Opsi A: Camera ViewModel Skinned PBR Arms (14 November 2026)

Menindaklanjuti persetujuan pengguna atas **Opsi A** (mengganti total sudut `ViewportFrame` dengan rig lengan FPS skinned PBR beresolusi penuh yang terpasang langsung di `workspace.CurrentCamera` saat `LockFirstPerson`):

- **Aset Template Baru `ReplicatedStorage.FlyHigh.Templates.ViewModelArms`:**
  - Diambil dari `Cand7_FPSArmsRig` (`rbxassetid://123048071994058`) pasca-audit Creator Store (menolak 4 kandidat lain yang mengandung `Script`/`LocalScript`/`RemoteFunction` tersembunyi): `0` script, single continuous skinned `MeshPart` (`ArmsMesh` `85121643579430`) + PBR `SurfaceAppearance` (`AlphaMode.Overlay`, `ColorMap=131618402188908`, `NormalMap=137006955586098` — lengan jaket gelap & sarung tangan taktis setengah jari dengan 5 jari realistis), `39` `Bone` aktif, skala `0.045`, seluruh part `Anchored=true, CanCollide=false, CanTouch=false, CanQuery=false, CastShadow=false, Massless=true`.
- **[`WeaponPresentation.luau`](../../audit/sources/ReplicatedStorage/FlyHigh/Modules/WeaponPresentation.luau)** (`27.465` B, Adler-32 `2900880989` / `0xaceb679d`, SHA-256 `a230360c644d7937126bea66ed648c7f791ffa3eac15b5223c7cb20d3c5aaf22`, identik byte-per-byte Studio ↔ mirror `edSame = true`, `45/45` script Studio `compileFail = 0`):
  - **1P Camera ViewModel (`FlyHighWeaponViewModel` -> `workspace.CurrentCamera`):** menyembunyikan tool 3P lokal (`LocalTransparencyModifier = 1`) hanya saat kamera `LockFirstPerson`, lalu merender `ViewModelArms` + klon senjata terskala (`Pistol`: `armsScale=0.042, gunScale=0.76`; `AK47`: `armsScale=0.048, gunScale=0.46`) dengan `MuzzleAttachment.WorldPosition` menjadi titik asal `WeaponMuzzleFlash` dan `FlyingBullet`.
  - **Analytical 2-Bone IK + Forearm Pronation + Finger Aiming (`buildRigData`, `solveArmIK`, `curlFinger`, `aimChainWorld`):** menghitung rantai FK tulang di ruang lokal `ArmsMesh` (kebal terhadap pitch/yaw kamera tanpa membaca `TransformedWorldCFrame` usang pada frame yang sama), mendistribusikan `60%` puntiran pergelangan ke tulang siku agar manset tidak terpelintir, mengarahkan 3 ruas telunjuk kanan ke pelatuk (`triggerPoint`) dan jempol kiri menyusur sisi frame/handguard (`thumbChain`) tanpa mengganggu crosshair `+`, serta memasang gerak ayunan jalan/belok, recoil tembak (`triggerShot`), kemiringan reload (`setReloading`), dan *CQB wall pull-back* (`wallPush`) saat berdiri dekat pagar gondola.
  - **`WeaponManager.luau` (`12.790` B) & `HUDLayout.luau` (`22.572` B):** tidak diubah; `HUDLayout` sudah menjaga guard `if weaponView then ...` untuk kotak sudut lama yang kini `nil`.
- **QA Pasca-Edit Final (`Play Solo` Windows `1` Klien, Build `f5aa15dc` + dirty working tree, Viewport `2090×752`):**
  - Boot `Play Solo` bersih `0` error gameplay (hanya `[DataManager] Unpublished Studio: isolated mock data; checkout disabled.`); console pasca-uji tetap `0` error.
  - **`Pistol` 1P (`qa_pistol_1p_viewmodel.jpg`):** `[E]` di `WeaponRack1` menghasilkan `tool=Pistol`, `camMode=LockFirstPerson`, `bones=39`, `nan=0`, `nonSafe=0`, `muzDist=2.187`, dua tangan bersarung taktis + lengan jaket bersih tanpa menindih crosshair atau kontrol HUD; klik kiri mengurangi `CurrentMag` `8 -> 7`, `[R]` mengisi ulang `7 -> 8`, `[G]` melepas senjata (`tool=nil, camMode=Classic, vm=false`).
  - **`AK47` 1P (`qa_ak47_1p_viewmodel.jpg`, `qa_ak47_1p_near_railing.jpg`):** `WeaponRack2` fixture `"AK47"` -> `[E]` menghasilkan `tool=AK47`, `camMode=LockFirstPerson`, `bones=39`, `nan=0`, `nonSafe=0`, `muzDist=2.876`; berdiri mepet `RailingNorth` (`hrpZ=3.24` vs `Z=1.50`) menarik moncong mundur rapi tanpa tembus pagar; klik kiri tembak `30 -> 29`, `[R]` reload `29 -> 30`, drop `[G]` saat balon masih aktif (`bal=true`) mengembalikan `tool=nil, camMode=Classic, minZ=0.5, vm=false`.
  - Pemulihan `Edit` terverifikasi: `leftover = 0`, seluruh objek inspeksi sementara (`_VmRigInspect`, `_TempArmsRaw`, `_VmTunePreview`) & fixture dihapus, kamera default `(0, 48, 25) -> (0, 12, -55)` dipulihkan; [`Fly High.rbxl`](../../Fly High.rbxl) tersimpan (`1.860.703` B, `14 Nov 2026 18:15:53+07:00`, SHA-256 `30e149d971cc2fe86bd93729e2fdacba7e1590eeab8ebfaa96e7cbf7d224599c`, belum dibuka ulang/commit/push).

## Batas QA & Pekerjaan Tersisa

- Diuji pada `Play Solo` `1` klien viewport Desktop/Ultrawide (`2090×752`) pasca-edit Pass 3; framing 1P Camera ViewModel pada rasio layar HP/Tablet (`390×844`, `844×390`, `1024×768`) secara live, perangkat fisik sentuh iOS/Android, serta uji multi-klien (`2–3` pemain untuk pose 3P rekan kru) masih perlu diverifikasi.
- Catatan sync `45/45` script Studio: seluruh file ubahan (`WeaponPresentation.luau`, `WeaponManager.luau`) identik byte-per-byte Studio ↔ mirror (`37/45` sama persis; 8 script tidak disentuh memiliki selisih baseline `±1` byte trailing newline yang sudah ada sebelumnya).
- `Fly High.rbxl` sudah disimpan lokal namun belum dibuka ulang dari disk dan belum di-commit/push.

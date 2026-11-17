# Efek suara rintangan (AUDIO-01) dan cutscene Istana Awan (CINE-01) — 17 November 2026

Implementasi dari [desain efek suara](../../design/features/obstacle-audio/design.md) dan [desain cutscene](../../design/features/palace-cutscenes/design.md), dikerjakan sesudah commit `57f7e31`. Verifikasi terakhir 03:39 WIB. Di-commit dan di-push 17 November. **Catatan:** montase portal dan beberapa detail cutscene di laporan ini sudah diganti di [round 6](../asset-round6-cutscene-polish-2026-11-17/README.md).

## Perubahan source

| Script | Jenis | Isi |
|---|---|---|
| `ReplicatedStorage.FlyHigh.Modules.ObstacleAudioCatalog` | baru | 23 aset, cue per musuh (datang/hancur, drone `charge`) dan hazard (telegraf/aktif, Storm `strike`, Dinding Badai). Batas suara 6 (4 di ponsel), cooldown datang 1,5 dtk, duck 0,6 saat WarningAudio prioritas ≥ 40 |
| `StarterPlayerScripts.ObstacleAudioController` | baru | Pool suara 3D di grup SFX, rolloff InverseTapered, eviksi skor prioritas/jarak. Mengamati `FlyHighObstacles` dan `FlyHighLargeChallenges`; suara hancur dari `WeaponFireEvent` kind Kill. Statistik di folder `FlyHighObstacleAudio` |
| `StarterPlayerScripts.PalaceCinematics` | baru | Cutscene tiba, efek kebangkitan, perayaan dermaga, kilat portal, montase turun lima zona. Watchdog mengembalikan kamera/kontrol |
| `ObstacleManager` | ubah | Atribut `ObstacleEffect`, `HazardActive`, `Strike` untuk klien audio. Tanpa perubahan gameplay |
| `PalaceArrival` | ubah | Docking diperlambat (1,6 + 1,8 + 1,4 dtk, ±4,8 dtk) dan atribut `ArrivalRevived` untuk kru yang dibangkitkan |
| `PalaceManager` | ubah | RemoteEvent `CutscenePreferenceEvent`, atribut `CutscenesEnabled` (bawaan Nyala), portal dua tahap: `ReturnSequence` → tutup 1 dtk → stream lobby → pindah → `ReturnLandedAt`. Mati = langsung pindah |
| `BiomeLightingController` | ubah | Preset bioma bisa dipaksa lewat atribut `CinematicBiome` selama montase |
| `ShopClientController`, `HUDLayout`, `HUDMotion` | ubah | Tombol "Cutscene: Nyala/Mati" di modal SETELAN (baris umum jadi 3 kolom) |

## Manifes audio

Semua aset Roblox Creator Store berlisensi (Pro Sound Effects / APM), kecuali WindGust (sintetis kreator). Semua 23 `IsLoaded` saat preload klien.

| Kunci | Asset ID | Sumber |
|---|---|---|
| SeagullCall | 9118858259 | Seagull Squawks 3 |
| BirdFlap | 9113443901 | Bird Flying 1 |
| HawkFlapCall | 9114787449 | Hawk Bird Wings Flap Flutter 1 |
| PigeonFlap | 9113444620 | Bird Wing Flaps Pigeon Two 1 |
| IceShatter | 9114855870 | Ice Block Drop To Concrete Shatter 1 |
| WindGust | 88352118429536 | Wind Gust (sintetis) |
| DroneHum | 9114037089 | Deep Synthetic Drone 8 |
| Beep | 9119100090 | Shortwave Bleep Beeps 9 |
| Zap | 9116277954 | Lightning Flashes Quick Electrical Bursts 32 |
| ZapShort | 9116276051 | Lightning Flashes Quick Electrical Bursts 11 |
| BeeBuzz | 9113414621 | Bee Various Buzzing Actions 10 |
| MetalCreak | 9126282474 | Wood Strain Stress Metal Creaking |
| MetalClang | 9125819197 | Robot Impact Metal Clangs 1 |
| RockHit | 9118608146 | Rock Hits Rock On Rock 8 |
| RockBreak | 9118588165 | Rock Drop On Concrete Breaks 10 |
| Thunder | 9126099928 | Thunder Constant Huge Hissing Strikes 2 |
| Boom | 9125484743 | Deep Hits Big Reverberant Booms 3 |
| CreatureRoar | 9113980319 | Creature Mix Giant Monster Roar Growl 1 |
| Waterphone | 9120574965 | Waterphone Burst 3 |
| Swish | 9126283592 | Wood Swish Whoosh Fast Movement 17 |
| SynthWhomp | 9119873304 | Synth Whomps 17 |
| FieryBlaze | 9116316301 | Swooshing Whisps Fiery Blaze 1 |
| Pixies | 1847063040 | Pixies C (APM), dipakai cutscene |

Pemetaan per rintangan ada di source katalog. Kunci bisa ditukar sesudah sesi dengar pengguna tanpa menyentuh controller.

## QA

Play Solo Windows, 1 klien Fikki2621, driver sementara `ServerScriptService._QA_CineDriver` (server memakai `_G` manager; obstacle/storm manager di-pause, band dimunculkan manual). Bukan penerbangan penuh.

**Audio.** Band 1–9 dan Dinding Badai: tiap musuh membunyikan cue datang dan hancur (lewat kill senjata), tiap hazard telegraf lalu aktif; drone memberi beep saat `Charging`, Spike swish, Debris berulang, Storm memberi guntur tiap `Strike`. Duck turun ke 0,6 di bawah peringatan badai. Evicted 0, LoadedAssets 23/23. Bukti dari statistik `FlyHighObstacleAudio` dan `Sound.IsPlaying`; **belum didengar telinga manusia**.

**Tiba di Istana (hidup).** Letterbox, orbit keep saat antre, establishing shot, orbit balon saat docking, judul "ISTANA AWAN · 10.000 km", kartu "ISTANA AWAN TERCAPAI · Puncak ke-N · m:ss · +150 koin", kamera dari sisi keep. [Judul](01-arrival-docking-title.jpg), [kartu](02-arrival-card-alive.jpg).

**Kru gugur bangkit.** Fixture `DeadVictory`: mati dan menang dalam satu langkah server (tiruan rekan hidup). Log klien: ghost=true → cutscene mulai (Scriptable) → bangkit dan `ArrivalRevived` di +5,2 dtk → kartu "Kru bangkit — kamu ikut sampai!" di +6,4 dtk → kamera kembali normal di +9,1 dtk. [Bangkit di dermaga](03-revived-crew-on-dock.jpg), [sesudah sekuens](04-revived-after-sequence.jpg).
Overlay GAME OVER pada percobaan pertama ternyata artefak fixture: solo + MarkDead membuat `alive==0`, jadi BalloonManager mengakhiri penerbangan sebagai kalah sebelum Victory. Bukan jalur nyata.

**Portal turun.** Tahan E di portal: kilat portal, tarik mundur, whiteout ([05](05-portal-whiteout.jpg)), jatuh 3 dtk melewati lima zona, mendarat di lobby lalu kamera blend ke belakang pemain ([11](11-portal-landing-lobby.jpg)). Log: whiteout +1,0 dtk, server pindah +2,2 dtk (tertutup whiteout), zona 4→3→2→1, kamera Custom di +7,9 dtk.
Perbaikan montase sesudah review visual: versi awal menatap ruang kosong gelap di bawah horizon ([16](16-before-dark-void.jpg)), lantai datar memperlihatkan tepi ([15](15-before-flat-deck-edge.jpg)). Versi final:
- dek awan anvil di batas tiap zona yang ditembus kamera;
- laut cakram di dasar;
- kamera lebih menukik (−0,95 → −1,2 rad);
- awan lebih banyak dan dekat, kristal kosmik lebih besar;
- pergantian pencahayaan mengikuti ketinggian kamera, bukan waktu.

Hasil: [jatuh live](06-fall-live-cosmic.jpg), [kosmik](07-montage-cosmic-deck.jpg), [senja](08-montage-senja.jpg), [badai](09-montage-badai.jpg), [laut](10-montage-laut.jpg). Gambar 07–10 diambil dari salinan montase dengan kamera fixture yang ditahan; capture live terlalu lambat untuk zona 0,6 dtk.

**Sakelar SETELAN.** [Nyala](12-setelan-cutscene-nyala.jpg) → klik → [Mati](13-setelan-cutscene-mati.jpg), atribut server `CutscenesEnabled=false`. Dengan Mati: tiba di istana tanpa GUI sinematik (gui=false sepanjang alur), portal langsung memindahkan ke lobby ([14](14-mati-direct-landing.jpg)).

**Catatan alat.** `execute_luau` Client memulihkan `CameraType` di akhir panggilan, sehingga kamera tampak "terkunci Scriptable" sesudah fixture kamera. Ini artefak alat, bukan bug game (diverifikasi: Custom bertahan di dalam panggilan, berubah sesudahnya; dipulihkan lewat `task.delay`).

## Cleanup, simpan, parity

- Play dihentikan, Edit / 0 pemain. `_QA_CineDriver`, `_QA_CineControl`, `_QA_CardShot`, `_QA_CardCtl` dihapus; 0 instance `_QA_*` tersisa.
- 57 script lolos `loadstring`.
- save_place LocalFile `E:/Antigravity/Fly High/Fly High.rbxl`, 3.402.649 B, SHA-256 `7f5eda1d856b5c28b35e52ab1043b6a91981f1c41299c9b813c31fdd86c64ce7`. Binary belum dibuka ulang di Studio.
- Parity: 10 source diekstrak dari `.rbxl` dengan `tools/rbxl_sources.py` dan dicocokkan dengan Studio. Normalisasi LF/trimEnd, panjang + FNV-1a. Mirror `audit/sources` diperbarui dari hasil ekstrak.

| Source | Panjang | FNV |
|---|---|---|
| HUDLayout | 39390 | cedfa39f |
| HUDMotion | 53946 | 54b5acdd |
| ObstacleAudioCatalog | 7629 | 64588b38 |
| ObstacleManager | 23726 | 30522a4b |
| PalaceArrival | 4604 | fe7788a3 |
| PalaceManager | 3564 | 94383077 |
| BiomeLightingController | 13128 | cb68a93c |
| ObstacleAudioController | 10661 | 68e33a0d |
| PalaceCinematics | 30536 | c4031f23 |
| ShopClientController | 21006 | 53e0729a |

## Batas

- Sesi dengar manusia untuk kandidat audio belum dilakukan.
- Belum ada multi-pemain nyata (efek kebangkitan dilihat pemain lain, antrean dua balon).
- Belum ada ponsel/tablet fisik atau angka performa.
- Belum ada penerbangan penuh tanpa driver.
- Preferensi Cutscene belum disimpan ke DataStore dan kembali Nyala tiap sesi. Desain tidak menetapkan hal ini. Ini berbeda dengan Nama/Animasi yang ikut disimpan DataManager.

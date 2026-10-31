# Rencana aset gambar UI Fly High

Daftar ini merupakan spesifikasi kandidat aset. Preview konsep pertama berisi 25 ikon/tombol sudah dibuat di assets/ui/concepts/fly-high-ui-kit-v1.png menggunakan imagegen; prompt dan peta ikon disimpan di folder yang sama. Preview belum menjadi aset individual siap produksi dan belum diunggah/dipasang ke Roblox. UI sekarang tetap berfungsi tanpa menunggu aset gambar.

Gunakan PNG transparan (RGBA), tepi bersih, gaya petualangan langit dengan warna teal gelap, ivory, dan aksen kuningan. Angka ukuran sumber di bawah adalah piksel file; ukuran tampil adalah unit UI Roblox. Sisakan sekitar 10% padding agar ikon tidak terpotong. Hindari teks, angka, bayangan besar dan detail kecil di dalam gambar. Ikon putih/ivory dapat diwarnai melalui `ImageColor3` untuk status aktif/terkunci.

| Aset / nama file | Ukuran sumber | Ukuran tampil | Deskripsi gambar |
|---|---:|---:|---|
| Dasar tombol kontrol — `control_circle_{normal,pressed,disabled}.png` | 512×512 per state | 72–96×72–96 | Lingkaran teal gelap dengan cincin kuningan tipis; versi ditekan sedikit masuk, versi terkunci desaturasi. Tanpa tulisan/ikon agar dapat dipakai ulang. |
| Ikon lompat — `jump_arrow.png` | 256×256 | 32–40×32–40 | Panah ke atas yang tebal, ujung membulat, sedikit garis dorongan di bawah. Terbaca pada layar kecil. |
| Ikon tembak — `fire_target.png` | 256×256 | 28–36×28–36 | Target dengan empat penanda bidik dan titik pusat; ivory di atas dasar tombol merah. |
| Bidikan tengah — `aim_reticle.png` | 256×256 | 24–28×24–28 | Bidikan putih tipis, titik tengah kecil, halo gelap lembut untuk terlihat pada awan dan kayu. Transparan di pusat. |
| Gas / burner — `burner_flame.png` | 256×256 | 28–40×28–40 | Nyala api bertingkat kuning-oranye, siluet jelas tanpa partikel atau teks. |
| Emergency Kit — `emergency_kit.png` | 256×256 | 24–32×24–32 | Tas reparasi kecil dengan tambalan kain dan perisai; tampil berbeda dari ikon toko. |
| Kondisi balon — `balloon_intact.png`, `balloon_torn.png` | 128×128 per state | 18–24×18–24 | Kubah balon mini utuh dan versi dengan sobekan kain gelap. Dipakai lima kali untuk mengganti emoji hati; angka 0/5 tetap teks. |
| Kemudi — `helm.png`, `helm_release.png` | 256×256 per ikon | 24–32×24–32 | Roda kemudi kayu/kuningan; versi lepas memiliki panah keluar yang jelas. |
| Aksi tali — `rope_attach.png`, `rope_detach.png`, `rope_climb.png`, `rope_descend.png` | 256×256 per ikon | 24–32×24–32 | Karabiner dan tali dengan panah masuk/keluar/atas/bawah. Arah juga dibedakan bentuk, tidak hanya warna. |
| Reparasi / rescue — `patch_repair.png`, `rope_repair.png`, `crew_rescue.png` | 256×256 per ikon | 24–32×24–32 | Tambalan dengan jarum; gulungan tali dengan kunci; tangan menarik tali dengan siluet rekan. Tiga aksi harus mudah dibedakan. |
| Senjata — `weapon_pistol.png`, `weapon_ak47.png` | 512×256 per senjata | 96×48 | Tampak samping senjata, siluet sederhana dengan dua atau tiga bidang warna; latar transparan. Amunisi/reload tetap teks dinamis. |
| Toko — `shop_supply.png` | 256×256 | 24–32×24–32 | Peti persediaan kecil dengan koin/label perlengkapan. Tidak mencantumkan harga atau logo Robux dalam gambar. |
| Ping dan audio — `team_ping.png`, `sound_on.png`, `sound_off.png` | 256×256 per ikon | 24–28×24–28 | Pin lokasi dengan gelembung pesan; speaker dengan gelombang; speaker dicoret untuk mute. |
| Peringatan — `warning_badge.png` | 256×256 | 24–32×24–32 | Segitiga/perisai dengan tanda seru yang kontras. Warna normal/merah kritis dapat diubah lewat tint UI. |
| Panel / tombol lebar — `panel_9slice.png` | 512×256 | Bervariasi, mis. 256×112 atau 148×48 | Panel teal semi-transparan dengan sudut membulat dan garis kuningan tipis. Gunakan `ScaleType.Slice`; contoh area tengah sumber: Rect(32,32,480,224), lalu sesuaikan `SliceScale`. |

Prioritas produksi: dasar tombol + lompat + tembak, lalu Emergency Kit / kondisi balon, kemudian tali / kemudi / toko. Panel dekoratif dapat menyusul; frame Roblox sekarang sudah cukup untuk menjaga layout.

## Tetap berupa UI dinamis

- Ketinggian, persentase, kecepatan, ammo, cooldown, jumlah kit, harga dan durabilitas tetap `TextLabel`/`TextButton`.
- Isi progress bar tetap frame yang ukurannya mengikuti data server; gambar hanya untuk bingkai/ornamen.
- Area sentuh tetap minimal 44×44, terpisah dari ukuran ikon di dalamnya. Tombol lompat saat ini 96×96 pada tablet, 72×72 pada layout ringkas, dan 80×80 pada desktop.
- `ImageLabel` dipakai untuk dekorasi/ikon; `ImageButton` atau ikon sebagai child tombol dipakai untuk aksi. Gambar tidak boleh menentukan izin role, damage, pembelian, atau hitbox gameplay.
- Kontrol inti Roblox seperti menu, chat, daftar pemain dan joystick bukan bagian dari paket gambar HUD ini. Hanya tombol loncat native yang disembunyikan sesuai permintaan; joystick tetap aktif.

Sesudah gambar tersedia, impor melalui pemilik experience dan masukkan asset ID pada konfigurasi UI. Tidak ada asset ID dummy, pembelian aset, atau upload yang dilakukan pada tahap daftar konsep ini.

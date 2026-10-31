# PNG siap impor untuk Fly High

Taruh file PNG individual dalam folder ini. Daftar mesin: `../asset-manifest.json`. Asset ID masih kosong sampai unggahan benar-benar berhasil; tidak ada unggahan atau pemasangan yang dilakukan hanya dengan membuat daftar ini.

| Ukuran sumber | Nama file |
|---|---|
| 512×512 | `control_circle_normal.png`, `control_circle_pressed.png`, `control_circle_disabled.png` |
| 256×256 | `jump_arrow.png`, `fire_target.png`, `aim_reticle.png`, `burner_flame.png`, `emergency_kit.png` |
| 128×128 | `balloon_intact.png`, `balloon_torn.png` |
| 256×256 | `helm.png`, `helm_release.png` |
| 256×256 | `rope_attach.png`, `rope_detach.png`, `rope_climb.png`, `rope_descend.png`, `patch_repair.png`, `rope_repair.png`, `crew_rescue.png` |
| 512×256 | `weapon_pistol.png`, `weapon_ak47.png` |
| 256×256 | `shop_supply.png`, `team_ping.png`, `sound_on.png`, `sound_off.png`, `warning_badge.png` |
| 512×256 | `panel_9slice.png` |

Satu file berisi satu ikon atau satu state tombol. Latar transparan asli (alpha), tanpa checkerboard yang tergambar, tanpa tulisan/angka/harga. Sisakan sekitar 10% ruang tepi. Untuk ikon lompat/tembak/api, jangan gabungkan ikon dengan dasar lingkaran; dasar tombol disediakan terpisah agar state dan ukuran mudah diubah. Lembar konsep 25 gambar bukan file siap impor.

Boleh mengirim sebagian dulu. Prioritas pertama: tiga dasar lingkaran, `jump_arrow.png`, `fire_target.png`, dan `emergency_kit.png`. File lain tetap opsional sampai tersedia; UI yang belum memperoleh gambar mempertahankan tampilannya yang berfungsi.

Setelah file tersedia, alur pengerjaan: periksa dimensi/alpha dan tampilan ukuran kecil, unggah melalui Studio yang terhubung, catat ID aktual pada manifest, pasang ikon pada HUD sambil menjaga teks/angka dinamis serta hitbox, lalu uji layout iPad/HP/desktop. Pembuatan atau unggahan aset tidak memerlukan publikasi versi game ke pemain.

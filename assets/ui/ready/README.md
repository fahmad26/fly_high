# PNG siap impor untuk Fly High

> Pembaruan 31 Oktober 2026: sumber final yang diunggah berasal dari `../final/compressed_img/` (27 PNG), bukan folder historis ini. Semua ID Roblox aktual tersedia di `../asset-manifest.json` dan `../final/compressed_img/roblox-asset-ids.json`. Integrasi gambar pada HUD belum dilakukan. Catatan generasi di bawah menjelaskan sumber lama sebelum pengguna menyiapkan ekspor final.

Taruh file PNG individual dalam folder ini. Daftar mesin: `../asset-manifest.json`. Asset ID masih kosong sampai unggahan benar-benar berhasil; tidak ada unggahan atau pemasangan yang dilakukan hanya dengan membuat daftar ini.

## Dua aset tambahan yang sudah dibuat

- `control_circle_pressed.png`: tombol teal dengan bagian tengah cekung dan bingkai kuningan; sumber hasil imagegen **1254×1254**.
- `panel_9slice.png` versi 2: panel teal penuh dengan bingkai kuningan memenuhi canvas, tanpa pita transparan lebar. Sumber imagegen **1774×887**, rasio **2:1**; target ekspor **512×256**. Seluruh gambar opak (RGB, alpha 255), termasuk bidang tengah, untuk menghilangkan cacat transparansi versi pertama.

Keduanya dibuat sebagai PNG individual menggunakan built-in imagegen. Tombol memakai RGBA transparan di luar lingkaran; panel versi 2 sengaja opak dan memenuhi canvas. Target ukuran pada tabel berikut tetap merupakan rencana ekspor, bukan resolusi file sumber aktual; `sourceWidth`/`sourceHeight` di manifest mencatat dimensi aktual. Prompt awal ada di `../concepts/prompts-additional-v1.json`, prompt koreksi panel ada di `../concepts/prompt-panel-v2.json`. Keduanya belum diunggah atau dipasang pada HUD. Batas `SliceCenter` panel perlu ditentukan dan diperiksa di Studio setelah impor agar sudut tidak terdistorsi.

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

Satu file berisi satu ikon atau satu state tombol. Ikon memakai latar transparan asli (alpha), tanpa checkerboard yang tergambar, tanpa tulisan/angka/harga. Sisakan sekitar 5–10% ruang tepi untuk ikon; panel boleh memenuhi canvas tanpa padding besar. Untuk ikon lompat/tembak/api, jangan gabungkan ikon dengan dasar lingkaran; dasar tombol disediakan terpisah agar state dan ukuran mudah diubah. Lembar konsep 25 gambar bukan file siap impor.

Boleh mengirim sebagian dulu. Prioritas pertama: tiga dasar lingkaran, `jump_arrow.png`, `fire_target.png`, dan `emergency_kit.png`. File lain tetap opsional sampai tersedia; UI yang belum memperoleh gambar mempertahankan tampilannya yang berfungsi.

Setelah file tersedia, alur pengerjaan: periksa dimensi/alpha dan tampilan ukuran kecil, unggah melalui Studio yang terhubung, catat ID aktual pada manifest, pasang ikon pada HUD sambil menjaga teks/angka dinamis serta hitbox, lalu uji layout iPad/HP/desktop. Pembuatan atau unggahan aset tidak memerlukan publikasi versi game ke pemain.

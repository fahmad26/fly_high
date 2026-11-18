# Exclusive Royal Titles — Implemented & Verified

Dokumen & aset desain vektor untuk dua gelar eksklusif **Fly High: Cloud Palace** (sudah disetujui pengguna, diunggah ke Roblox Asset Server, dan diimplementasikan ke game).

## Asset ID Terverifikasi & Status Figma
- `art_cosmetic_title_prince.png`: `rbxassetid://107428339594877`
- `art_cosmetic_title_princess.png`: `rbxassetid://95518013683213`
- Halaman Figma `"Exclusive Titles & Badges"` (`node 2027:2`) berhasil dibuat di file [`hsDf2FbnHnlSViAOq5DPJt`](https://www.figma.com/design/hsDf2FbnHnlSViAOq5DPJt) setelah membaca style existing (`6:2`, `6:817`, `6:1276`).
- Penulisan node lanjutan via Figma MCP terhenti oleh **paywall kuota Starter plan (`mcp_rate_limit_paywall`)**. Seluruh aset dibangun sebagai **SVG vektor berlapis siap-impor Figma** beserta pratinjau **PNG 1:1 / showcase**:

| Aset | Ukuran | Kegunaan | File |
| --- | --- | --- | --- |
| Showcase Lengkap | `1420×880` | Review desain Kartu Toko (`0 Koin`), Overhead ID/EN & aturan akses | [exclusive_titles_showcase.png](exclusive_titles_showcase.png) · [SVG](exclusive_titles_showcase.svg) |
| Ikon Mahkota Pangeran | `480×400` | Ikon Toko Tab Kosmetik `title:prince_of_sky` | [art_cosmetic_title_prince.png](art_cosmetic_title_prince.png) · [SVG](art_cosmetic_title_prince.svg) |
| Ikon Tiara Putri | `480×400` | Ikon Toko Tab Kosmetik `title:princess_of_sky` | [art_cosmetic_title_princess.png](art_cosmetic_title_princess.png) · [SVG](art_cosmetic_title_princess.svg) |

## Rancangan Item Katalog (Untuk Tahap Implementasi Setelah Approval)
1. **`title:prince_of_sky`**
   - **Label:** `Pangeran Langit` (`id`) / `Prince of the Sky` (`en`)
   - **Harga:** `0` Koin
   - **Akses eksklusif:** hanya `UserId == 8635452105` (tersembunyi di Toko & ditolak server di `ShopManager`/`DataManager` untuk akun lain)
   - **Visual mewah:** mahkota safir-indigo bersayap dengan aura bintang, border emas ganda, dan gradien overhead biru-royal-emas.
2. **`title:princess_of_sky`**
   - **Label:** `Putri Langit` (`id`) / `Princess of the Sky` (`en`)
   - **Harga:** `0` Koin
   - **Akses eksklusif:** hanya `UserId == 9294134678` dan `UserId == 8635452105` (tersembunyi & ditolak server untuk akun lain)
   - **Visual mewah:** tiara mawar-ungu velvet berlapis kristal champagne, pita rose-gold, dan gradien overhead ungu-plum dengan kilau bintang.

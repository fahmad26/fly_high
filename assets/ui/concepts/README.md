# Fly High UI kit — concept v1

> Arsip konsep awal, bukan daftar pekerjaan aktif. HUD produksi lokal dan upload berikutnya tercatat di [Sky Adventure](../sky-adventure/README.md). Pernyataan belum diunggah di bawah hanya berlaku untuk lembar konsep ini.

Generated with the built-in imagegen tool. The exact prompt is in `prompt-v1.txt`; preview: `fly-high-ui-kit-v1.png`.

This is an art-direction concept sheet with 25 icons/controls, not a production sprite atlas. Spacing, edge quality, silhouettes and small-size readability still need review before individual asset export. Do not assume exact cell rectangles or wire this whole sheet to live buttons. Nothing has been uploaded to Roblox or installed into the game.

Rows, left to right:

1. Jump, shoot, burner, blank circular base, disabled base.
2. Emergency Kit, intact balloon, torn balloon, helm, release helm.
3. Attach rope, detach rope, climb, descend, patch.
4. Repair rope, rescue, pistol HUD icon, rifle HUD icon, shop.
5. Team ping, sound on, sound off, warning, aiming reticle.

The rectangular 9-slice panel and pressed-state button variants from the asset plan are not included in this first concept sheet. Text, prices, ammo and cooldown remain dynamic game UI.

These two additions are now generated as separate PNG source files in `../ready/control_circle_pressed.png` and `../ready/panel_9slice.png`. Their exact built-in imagegen prompts are recorded in `prompts-additional-v1.json`; actual source dimensions and import status are in `../asset-manifest.json`. They have not been uploaded or installed into the game.

The panel was corrected in v2: the original canvas was 2:1 but its visible frame was close to 3:1 due to large vertical transparent margins, and its center had irregular alpha. `../ready/panel_9slice.png` is now a full-bleed 2:1 panel with a fully opaque center (1774×887 source, not a 512×256 export). The previous source is preserved as `panel-9slice-v1-superseded.png` for provenance only; do not import it. The correction prompt is in `prompt-panel-v2.json`.

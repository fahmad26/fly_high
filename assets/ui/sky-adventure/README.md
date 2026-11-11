# Fly High — Sky Adventure HUD

HUD design version 11 is installed in the local `Fly High.rbxl`. See the [approved visual brief](../../../design/features/hud-generated-art/design.md).

> The playtest record below belongs to the 7 November HUD pass. Later layout/input edits require their own regression evidence. [PROGRESS](../../../PROGRESS.md) tracks the current workspace; the historical count of 35 compiled scripts is not the current source inventory.

- [Generated sources and prompts](./generated/README.md): 55 independent source PNGs made with built-in image generation. No source sprite was cropped from a concept collage.
- [Catalog](./catalog.json): 53 selected sprites packed into eight 1024 × 1024 runtime textures. Two first drafts, `reload_normal` and `hull_panel`, remain in the source folder but are superseded.
- [Roblox IDs](./roblox-texture-ids.json): uploaded through Studio Asset Manager and matched against the Roblox creator inventory. The place is local; no experience publishing was performed.

Run `node assets/ui/sky-adventure/pack.cjs` with `sharp` available to rebuild the runtime textures and catalog. This preserves the original PNGs. If the atlas pixels or page ordering change, upload those pages again and update `HUDAdventureCatalog` to match the new rectangles and IDs.

The HUD uses the complete button images, including the silhouette, rim, shading and pictogram. Jump uses separate normal, pressed and locked images; gas automatic, warning audio and the kit have dedicated state art. Ordinary controls use a tint on the entire image for pressed or unavailable feedback. Altitude, prices, timers, names and ammunition remain live text in Fredoka One and Nunito. Atlas-backed panels use three horizontal segments where width changes; circles keep their aspect ratio. The prior art stays available as a runtime fallback.

Playtest, one player: desktop normal/pressed/locked jump images loaded with the arrow fallback hidden. In iPad Air 5th Generation emulation, a tap triggered a real Humanoid jump and no native jump button was visible. iPhone 17 Pro portrait (401 × 719 HUD area) showed separate Jump, Fire and Ammunition bounds. In landscape (748 × 323), both shop purchase controls were fully visible and 44 UI units tall. The damage, altitude, ammunition and result UI were checked using injected presentation fixtures. Console showed only the existing unpublished-place mock data message; all 35 Luau source containers compiled. Playtest stopped and Studio restored to the current desktop device with one player. No Robux purchase or real flight progression was tested in this pass.

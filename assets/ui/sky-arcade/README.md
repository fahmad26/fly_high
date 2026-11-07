# Sky Arcade PNG

Fly High loads 199 independent PNGs from nine Roblox image assets. The [source folder](./png) contains the 87 surfaces, glyphs, gauges, panels, and illustrations, 80 lettering sprites, and 32 telemetry and state images. `catalog.json`, `lettering-catalog.json`, and `meters-catalog.json` map each key to its texture rectangle. `roblox-texture-ids.json` records the uploaded pages.

Controls keep their input handlers and live values. The HUD now composes altitude, speed, progress, ammunition, stock badges, and the takeoff timer from image glyphs. Rectangle surfaces use 9-slice scaling, circles use Fit, and loaded artwork hides the previous border strokes. Player names, shop prices, translated copy, and contextual messages use live text. Core Roblox UI and native proximity prompts use the platform's controls.

## Updating a sprite

1. Replace its independent PNG. `generate.cjs` recreates the illustrated surfaces and glyphs from editable vector definitions. The four `art_*.png` illustrations are separate originals.
2. Run `node pack.cjs` with `sharp` available for the base images. For lettering, run `python generate-lettering.py` with Pillow and Arial Bold available, then `node pack.cjs --lettering`. Upload the changed texture pages to Roblox and update `roblox-texture-ids.json`.
3. Run `node link.cjs` to update the source mirror of `HUDImageAssets`. Apply that module to the place in Studio, playtest it, and save the place.

For telemetry artwork, run `python generate-meters.py` and `node pack.cjs --meters`, then follow the same upload and linking steps. The renderer caches glyph instances and positions for unchanged values.

## Studio verification, 7 November 2026

HUD version 10 verified the native 9-slice behavior with atlas-relative SliceCenter coordinates, plus image glyphs for altitude, progress, speed, ammo and takeoff countdown. A one-player visual fixture exercised 9999 km, 16.7 km/s, critical damage and a countdown on iPhone landscape and portrait (401 × 719 HUD area). Visible glyphs loaded and the project log contained only the existing mock-data notice. These were presentation fixtures, with no complete-flight or physical-device re-test. After testing, Studio returned to Edit and desktop emulation.

The lettering pass was verified on a desktop preset (1277 × 662 HUD area) and iPhone 17 Pro landscape (749 × 322 HUD area). The hull and Shop button did not overlap in either flight. The pilot's Auto Gas changed its PNG label and speed rose from zero. The Shop title, five Ping labels, and lobby sign lettering loaded. [iPhone Playtest capture](../../../audit/image-ui-lettering-mobile.jpg).

[Gunner capture](../../../audit/image-ui-gunner.jpg) · [Shop capture](../../../audit/image-ui-shop.jpg)

- All five uploaded textures loaded in the single-player gunner playtest. The visible HUD had no unloaded image labels. The hull card cleared all four left dock buttons at the tested 713 × 470 GUI viewport.
- Shop and ping opened from real input. Both product illustrations loaded, and the shop closed with its X button. Launch from Pod A and pistol equip through the actual prompts showed the gunner UI and the pistol illustration.
- The pilot's auto gas button changed to the active PNG when clicked, the replicated setting turned on, and the speed readout showed +14.9 km/s. The final playtest log contained only the existing unpublished-place mock data notice. All 33 Lua source containers compiled in Edit.
- Testing used one Studio client. Device-specific layouts and all engineer or hazard scenarios did not receive separate playtests in this pass.

The prior 27 image IDs remain in the historical manifest for traceability. The saved place had no references to those IDs. The superseded PNGs were removed from the project.

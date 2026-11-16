# Scenery review 5 — 16 Nov 2026

User request: "Lakukan 1-7, 8 dan 9 nanti saja" (items 8 phone/low-graphics and 9 Play Solo are deferred).
State: Studio edits saved to Roblox Cloud (place version 17). Not yet saved to file, mirrored to `audit/sources`, or committed.

| # | Item | Change | Evidence |
|---|------|--------|----------|
| 1 | Low-poly nature (incl. lobby) | Nature kit v2 (asset 131635585352473): PalmTree, BroadleafTree, Fern, Boulder, Flower + new HangingRoots in `EnvironmentAssets`. 269 lobby models in `FlyHighLobby.IslandNature` swapped in place (scale/pivot/name/attrs/petal colour kept, `NatureV2=true`, TrunkCollider and boulder collision kept). Backups: `ServerStorage.NatureAssets_Legacy`, `ServerStorage.LobbyNature_Legacy`. | 01 |
| 2 | Sunset roots looked like sticks | `hangingRoots()` helper in BiomeScenery clones `EnvironmentAssets.HangingRoots`; used for island vines (anchored to the `IslandTurf` rim), BridgeRoot and anchorIsle HangingRoot. Old beam/span code kept as fallback. | 02 |
| 3 | Leftover mini ruins on Sunset temple islands | Islands with a `TempleRuinArch` get nothing extra; others get a `SmallRuinArch` (RuinArch at 0.32×) instead of the old blocky `HabitatArt.Ruins`. | 02 |
| 4 | Storm cloud texture warnings | Investigated: the "No asset content representation … do_not_fallback_to_baseline" warning also fires for freshly uploaded decal images and for Cloud Palace cumulus TextureIDs. A/B capture (03 vs 04) shows the LUT renders. Warning is Studio noise; the original TextureIDs were kept (a test swap was reverted). | 03, 04 |
| 5a | Seagull too thin | Body ×1.45 wide ×1.3 tall, wings ×1.9 thick ×1.25 chord, plumage scaled, eyes re-seated; wing dihedral for Seagull and Eagle (`WingDihedral` attr). Backup `ObstacleMeshes_Legacy.Seagull_v4`. | 05, 06 |
| 5b | Phantom plain | ShadowPhantom v5 (asset 102599416782119, `tools/build_phantom.py`): hooded cloak with folds and ragged hem, sleeved arms (still named `Arms`), new `Claws` (Decoration), recessed hood; existing SurfaceAppearance reused. Backup `ObstacleMeshes_Legacy.ShadowPhantom_v1`. | 05 |
| 6 | Cosmic crystal islets / orbit stones | New `orbitShard()` helper: small IslandKit PBR rock + crystal cluster replaces the "Cosmic" landmark disc in `CrystalSatellite` and `CosmicArcStone`; halo rings thinner (0.18–0.2) and wider. Falls back to the landmark if the kit is missing. | 07 → 08, 09 |
| 7 | Gateway cream clouds cartoonish | `brightCloud`: all lobes use the day LUT (blue-grey self-shadow) instead of the gold LUT; soft-edge shell 1.04× at T 0.86 (was 1.07× / 0.78) to remove the halo outline. Only the Gateway used warm lobes. | 10 → 11 |

Source sizes: BiomeScenery edited in Studio (mirror not yet updated). BiomeLightingController unchanged.

Blender sources for this round are saved in `assets/models/scenery/FlyHigh_SceneryKits_round5.blend` (scenes FlyHigh_Nature, FlyHigh_Phantom, FlyHigh_Hail, FlyHigh_IslandFix, ...). The nature kit v2 / HangingRoots generator was not kept as a script; the .blend is its source of record.

Cleanup verified: no `_QA*`, `_Sweep*`, `_Gallery*`, `*_Import` instances left; Lighting/Atmosphere/Sky restored to file originals; Edit mode.

## Lobby tidy-up (16 Nov, 23:05 WIB, Cloud v18)

User: "Tolong dicek dong satu-satu asset di pulau awal spawn ini, lokasinya berantakan. Tolong rapikan ya".
Cause: the nature kit v2 swap kept each model's uniform scale, but the old SteppingStone (7) and Pebble (114) models had been flattened per part. They became full mossy boulders, and four sat on the spawn deck.

| Fix | Count |
|---|---|
| SteppingStone models removed (under the spawn deck / curb; the paved path already covers that route) | 7 |
| Boulders and pebbles: moss cap removed, mesh replaced with new natural rocks (`EnvironmentAssets.LobbyRocks`, asset 111074492228074), seated on the lowest terrain sample and sunk 18% (boulders) / 30% (pebbles) | 12 + 114 |
| Ferns/flowers/boulder clearing the pod StoneFoundation, Console and PreviewPedestal (nearest free spot, re-grounded) | 10 |
| Hen_5 / Hen_6 `Home` moved so the 8-stud roam circle stays clear of pods | 2 |
| Ferns sunk below terrain raised | 6 |
| ArrivalFern moved off the spawn-deck rim (radius 15.8) | 1 |

Audit after the fix: 0 nature models overlapping lobby structures (pods, consoles, pedestals, spawn deck, paths, signs; hen roam radius included); 0 floating rocks; no `moss patch_geom`/old boulder meshes left. IslandWildlifeController uses `Rocks[*].PrimaryPart` (NatureRoot, still at each rock's position). Old lobby models remain in `ServerStorage.LobbyNature_Legacy`.

Evidence: 12 → 13 (spawn deck), 14 → 15 (boulder), 16 (overview).

## First-person weapon hands (16 Nov, 23:20 WIB)

User: "Saya notice bentuk tangan ketika pegang senjata aneh, tolong perbaiki".
Reproduced in Edit with a harness that runs WeaponPresentation's own IK functions at a fixed camera (17, 19). Causes:
- The right hand sat on the trigger guard/slide instead of the grip (knuckles ~0.2 stud too far forward and ~0.1 too high), so the light grip stuck out below the hands like a stick.
- The left (support) arm crossed under the right arm and came out on the right side, so the forearms formed an X.
- Both thumbs pointed outward (+X), sticking out to the right/left of the gun.

Changes (`viewProfiles` in `ReplicatedStorage.FlyHigh.Modules.WeaponPresentation`, 40,447 → 40,606 B):
- Pistol: R wristOffset (0.16,-0.17,0.34) → (0.14,-0.27,0.52); L wrist (-0.13,-0.20,0.18) → (-0.26,-0.30,0.22) with elbow pole, finger and back-of-hand directions turned so the support hand wraps from the left; thumbs point forward along the frame (thumbs-forward grip); gunOffset (0.46,-0.38,-1.48) → (0.38,-0.40,-1.32), shoulderOffset y -0.58 → -0.54 so the hands and wrists stay in frame.
- AK47: R wristOffset (0.17,-0.13,0.28) → (0.15,-0.19,0.40) (hand on the pistol grip, not the trigger guard); right thumb points forward. Left hand on the handguard unchanged.

Checks: harness after the edit uses the module source itself (18, 20, 21); all 54 scripts compile; harness removed. Play Solo not run (deferred item 9), so the live 1P view, recoil and reload poses still need a playtest.

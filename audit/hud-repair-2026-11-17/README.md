# HUD alert, header and repair polish — 17 November 2026

Historical first iteration: the user subsequently requested smaller, more transparent capsules and custom UI for other native actions. Prompt presentation is now superseded by [the compact shared renderer audit](../interaction-prompts-2026-11-17/README.md). Header/alert changes remain. The source hashes/results below describe this first iteration, not the current prompt renderer. [Design brief](../../design/features/hud-repair-consistency/design.md).

## Changes

- `HUDTheme`: shared regular/storm two-line alert group raised by 4 px. Current measured bottom clearance is 14 px or greater. Single-line grounded countdown has no secondary line to raise.
- `HUDTopChrome`: header uses the same `modal_frame_9slice` image as the popup, with a flat coral balloon and concentric navy/gold medallion. Lobby, dock, loading, biome, descending and turbo text/state are preserved.
- `HUDRepairPrompts`: custom translucent navy action cards (background transparency 0.35), gold rim, keyboard/gamepad/touch hint and hold progress. 248 × 72 desktop, 216 × 72 touch. Position follows the original prompt's world anchor plus UIOffset, recalculated every frame. A ScreenGui projection was selected after the initial BillboardGui variant did not appear in capture; the invisible variant is not shipped.
- `BalloonFleetAnimator`: starts the repair UI once and sets only `PatchPrompt`/`RepairRopePrompt` to Custom before enabling them. Server repair, eligibility, duration, remotes and rewards were not modified.

## Evidence and actual results

Baseline: `6f6dc64`, with pre-existing uncommitted HANDOVER/PROGRESS and user-test rollback audit. Two existing UI sources matched Studio after LF/trimEnd normalization before editing; originals are in `baseline/`. Other AI work appeared concurrently in BalloonVFX, BiomeScenery, binary and playtest-fixes audit; it was preserved and is outside this UI QA.

Environment: Windows Roblox Studio Solo, one player Fikki2621, client-only fixture prompts and client HUD state injections. The fixture does not grant inventory, advance a real flight, or perform server repairs. Raw MCP responses and source hashes are in [results.json](results.json).

| Check | Actual result |
| --- | --- |
| Desktop 1066.4 × 536 | Nine sample warning strings on both alert surfaces: all title/detail TextFits true, bottom clearance ≥14 px; five biome/descending headers fit |
| iPhone 17 Pro simulator, 749 × 381 | Same alert/header matrix passes, TouchEnabled true, repair width 216, TAHAN hint |
| iPad Pro M5 13in simulator, 1375 × 1030 | Same alert/header matrix passes; no text clipping |
| Header extra states | Lobby FLY HIGH, DERМAGA C and turbo labels fit; nine-slice image loaded |
| Keyboard E | Short hold cancels, full 1.5 s hold triggers once; raw trigger count 1 |
| Pointer in touch-enabled phone simulator | Short rope hold followed by full 4 s hold triggers once; width 216 and transparency ~0.35 verified |
| Lifecycle | Partial hold progress observed (~0.268), release resets to 0; destroying one prompt removed its UI. No success claim is rendered before server updates; pending text is Memproses… |
| Compile / source | Four changed/new scripts compile. Studio source exported to mirrors, compared after LF/trimEnd normalization |
| Console | No runtime errors observed in the tested session |

Screenshots: [header](header-desktop.jpg), [repair desktop](repair-desktop.jpg), [repair phone](repair-phone.jpg), [tablet](hud-tablet.jpg). Early diagnostic captures were not used as pass evidence. The screenshots use injected HUD state, including loading/zone labels, not an end-to-end flight.

Limitations: no physical touch/gamepad test, actual flight repair completion, moving-balloon network test, or real hazard timing test. Phone input was injected through the mouse input tool in a touch-enabled simulator. Portrait was not tested because this place is LandscapeSensor.

## Cleanup / persistence

Play stopped; Edit, 0 players, default device viewport, no repair fixture or user-test cheat flag remaining. Client-only GUI/attributes disappeared with Play. No fixture entered the Edit place.

`save_place` saved the open place to **Cloud version 24** (not Publish). No claim is made that local `Fly High.rbxl` includes these UI changes: the local binary has concurrent work and was not reopened/compared. No commit/push requested in this task.

Next: user visual review and natural-flight repair tests on a physical phone/gamepad. Save to local file and reopen/compare before claiming binary parity.

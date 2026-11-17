# Compact custom world actions — 17 November 2026

Implementation available; awaiting user visual review. This supersedes the larger repair cards from the [first iteration](../hud-repair-2026-11-17/README.md). [Approved request and design revision](../../design/features/hud-repair-consistency/design.md).

## Result

- Capsule 196 × 50 on keyboard/gamepad input, 196 × 52 on touch. This reduces the old desktop card area by about 45% (248 × 72); touch area by about 34% (216 × 72).
- Background transparency raised from 0.35 to 0.65; key-cap background 0.55. Outer ends have radius scale 0.5. Key cap is a genuine 32 × 32 / 36 × 36 circle, also radius 0.5.
- One renderer handles 13 prompt families. The following list comes from Edit DataModel inventory plus the dynamic weapon-pickup code:

| Prompt | Action |
| --- | --- |
| PatchPrompt | Tambal balon |
| RepairRopePrompt | Perbaiki tali |
| HelmPrompt | Pegang kemudi |
| PickupPrompt | Ambil Handgun / AK-47, using the live rack ActionText |
| StartPrompt | Mulai terbang at five docks |
| ReturnPrompt | Portal pulang from Istana Awan |
| PhotoPrompt | Foto kemenangan |
| SitPrompt | Sofa two seats and two swings (four seat prompts) |
| TetherPrompt | Pasang tali |
| DetachTetherPrompt | Lepas tali |
| ClimbPrompt | Panjat kubah |
| DescendPrompt | Turun ke gondola |
| PullCrewPrompt | Tarik rekan |

The last five families remain disabled where the existing bottom HUD owns their actions. Registration never enables a prompt. It only selects Custom style, handles future/renamed/streamed prompts, and draws native locations. No server action, duration, range or exclusivity was changed.

`HUDInteractionPrompts` owns presentation. `HUDRepairPrompts` is a compatibility entry point (WaitForChild before require); the existing flight controller starts it as before. BalloonFleetAnimator is unchanged from this task's baseline.

## QA and evidence

Build: `6f6dc64` plus pre-existing dirty HUD/header, VFX/scenery, binary and documentation work. Baselines for the previous renderer and controller are in `baseline/`. Studio sources were compared against mirrors before editing. Source parity after edits uses CRLF→LF and trimEnd normalization; hashes are in [results.json](results.json).

Windows Studio Solo, Fikki2621. Fixtures are client-only local prompts and do not complete real server gameplay or alter persistent stock/progress.

| Check | Actual result |
| --- | --- |
| Desktop 1066.4 × 536, keyboard input | All 13 families + dynamic AK label render; title/detail fit; 196 × 50, transparency ~0.65, circle/capsule properties correct |
| iPhone 17 Pro simulator 749 × 381 | All render/fit at 196 × 52; touch hints present |
| iPad Pro M5 13in simulator 1375 × 1030 | Same result as phone |
| World anchor | Final screen-space comparison error <1 px in all three viewports, including a nonzero UIOffset |
| Zero-duration action | Pointer click on HelmPrompt triggers once |
| Patch hold | Partial hold (~0.267 progress) cancels/reset 0 without trigger; full keyboard hold triggers once |
| Rope hold | Partial hold cancels; full 4 s pointer hold in touch-enabled simulator triggers once |
| Pickup | Pointer hold at 0.2 s triggers once; Handgun label updates live to AK-47 |
| Lifecycle | Disabled prompt removes its UI; removing parent unregisters it; repeated Start through compatibility entry point does not add a duplicate |
| Photo | Disabling the main HUD hides the custom action and restoring it shows the action again |
| Compile / console | Two presentation modules and unchanged controller compile; tested session console has no errors |

Early fixture results are preserved separately: the first desktop anchor check mixed viewport and screen coordinate spaces; the initial phone check exposed a real safe-area offset. Final projection uses WorldToScreenPoint minus ScreenGui.AbsolutePosition, fixing the phone/tablet position. First results must not be treated as passes.

Automatic review rejected an attempted full controller source replacement as too broad. The controller was not changed in Studio. The final implementation uses only presentation modules through its existing startup call. No permission-dependent work remains.

Screenshots: [compact repair desktop](compact-repair-desktop.jpg), [compact weapon pickup phone](compact-pickup-phone.jpg). Raw responses for the matrices, taps, hold and cleanup are in results.json. These images show local prompt fixtures near the lobby avatar, not actual balloon damage or weapon grants.

Limitations: no physical phone/gamepad or real-flight server-action outcome test. Pointer input was injected with the mouse tool in a touch-enabled simulator. The game is LandscapeSensor; portrait is outside the supported flow. A final compatibility-shim change only adds WaitForChild; it was compiled/compared after the visual/input runs.

## Persistence and cleanup

Play stopped, Edit/0 players/default viewport; no action fixture/GUI or temporary cheat flag saved. Saved to Cloud version 26 including the final compatibility WaitForChild guard; the earlier save was version 25. See results.json for both save responses. No Publish or commit/push requested. Local rbxl was not reopened/compared with Studio and is not claimed equal. Concurrent game/scenery edits were preserved.

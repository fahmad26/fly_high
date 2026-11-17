# Reopened place and multiplayer regression — 17 November 2026

Build under test: **`de8c273`**, clean production source/place at start. Local file SHA-256 remains `d5e1eed6295891ddba751603916490ab60903285621c50214a933a7f14f9603a` (3,495,644 bytes). Windows Studio local simulations, default desktop viewport, ideal local networking. No publishing, checkout or persistent player-data edits.

## Reopened local file

Opened `E:\Antigravity\Fly High\Fly High.rbxl` through Studio's Open Roblox File dialog in a separate session. The original session remains untouched. Studio displayed its file-in-use/read-only warning; the verification/test session does not save over the original.

- Original cloud/session ID: `5847b091-658c-4cee-b661-28c5ea116a09`.
- Reopened local session ID: `d058cf7b-04d5-46bc-9b4e-0ed0ecaab1e4`, `GameId=0`, `PlaceId=0`, not cloud-persisted.
- [Before manifest](place-before.json), [reopened manifest](place-reopened.json), [comparison](place-reopen-comparison.json), [read-only probe](place-probe.luau).
- Source path/class/raw byte length/rolling checksum matches **61/61**. The preceding [checkpoint](../checkpoint-2026-11-17/README.md) separately proves direct Studio↔binary source byte equality and normalized mirror parity on the unchanged saved file.
- Geometry/property checksums match across **14,635 BaseParts** in lobby (9,007), CloudPalace (1,029) and replicated templates (4,599). Scope: path, class, CFrame/Size rounded to 0.0001, collision/touch/query/anchored flags, transparency, material/color and MeshPart mesh/texture IDs.
- All **83 prompt records** match (path, style, enabled, key, hold, activation distance and action text); selected Lighting, streaming, auto-jump and orientation settings match.
- Terrain material/occupancy checksum matches at 4-stud resolution in `(-256,-16,-256)` to `(256,80,256)`, including the lobby grass region, plus Decoration/water transparency.

These are scoped manifest comparisons. Geometry/Terrain use rolling checksums, not cryptographic equality or a full property-by-property proof for the entire DataModel. No claim covers unlisted properties, distant Terrain or every archived ServerStorage asset. An optional EncodingService SHA probe stalled and was abandoned; it provides no evidence and made no scene changes.

## Trio moving repair regression

[Raw results](repair-trio-results.json), [server driver](repair-trio.server.luau), [client driver](repair-trio.client.luau).

**40/40 checks passed**, server runtime errors 0. Three real local clients, isolated unpublished mock profiles. Covers moving patch validation, rejected early finish, malformed client requests, cancellation, validated remote hold, descent, helm release and six role-related jump cases including holding/dropping a weapon.

Fixtures: manager launch/boarding acknowledgement, +125 stud altitude warp, shield, temporary anchor during setup only, client positioning/follow input and rope durability resets between independent trials. Balloon is unanchored during measured moving repairs/jumps. This reuses the historical driver against the current build, with a new run identity. It is not a natural spawn-to-summit flight or physical-device/network-latency test. Native/custom pointer repair is checked separately in duo.

## Duo prompt, weapon and arrival regression

[Client driver](duo.client.luau), [server driver](duo.server.luau).

[Attempt 1](duo-attempt1-failed.json) failed at custom rope prompt visibility: the fixture directly changed slot durability without publishing `RepairableRopes`, leaving the production eligibility mask disabled. No runtime game errors were recorded. The retry changes only the fixture: attach, set runtime durability, then detach through production cleanup so station eligibility updates. The failed run remains failed.

Further diagnostic runs are retained separately:

| Run | Actual outcome |
| --- | --- |
| [Attempt 2](duo-attempt2-failed.json) | Prompt visible, pointer completion failed; no game-code change made. |
| [Attempt 3](duo-attempt3-diagnostic.json) | Button/prompt/server instrumentation recorded zero button input/hold events, despite a visible eligible capsule. |
| [Attempt 4](duo-attempt4-ab.json) | Hiding only `GhostSpotArrows` did not change the failure; the overlay hypothesis was rejected and the original HUD restored. |
| [Attempt 5](duo-attempt5-blank-area.json) | Blank capsule area also failed; global mouse event arrived but button event did not. |
| [Attempt 6](duo-attempt6-inset.json) | Corrected simulated screen coordinates with actual GUI inset `(0,58)`: pointer begin/end/trigger reached the prompt and repair completed. Both weapons passed combat/UI checks. The overall run still failed on a client error assertion: platform CoreGui/StarterScript errors were included in the unclassified error list. |

Root cause of the pointer-test failure was the fixture coordinate conversion. `GetGuiObjectsAtPosition` uses the GUI inset coordinate space; `VirtualInput:SendMouseButton` uses screen space. The retry adds `GuiService:GetGuiInset()` for injection, retaining the GUI-space point for hit testing. [GuiObject coordinate guidance](https://create.roblox.com/docs/reference/engine/classes/GuiObject), [VirtualInput](https://create.roblox.com/docs/reference/engine/classes/VirtualInput). No production HUD change was needed. No later pass overwrites the failed status of these earlier runs.

Final driver additionally covers custom pointer patch hold/cancellation on the catwalk, both weapons, and arrival/revive. It retains raw client error messages and classifies only messages with explicit `[Roblox][CoreGui.RobloxGui.*]` or `[Roblox][Script Context.StarterScript]` prefixes as platform errors. Other messages remain game errors. This classification does not resolve the platform issue or claim an entirely clean engine console.

**Final result: [55/55 passed](duo-final-results.json)**, 0 game-client errors on both clients and 0 server runtime errors. The observer client retained **13 platform errors**, beginning with `PlayerPermissionsModule: Invalid value for enum CreatorType`; the other client recorded 0. Platform issue remains open, with raw messages preserved. The earlier unclassified run remains failed.

Actual outcomes:

- Rope pointer hold starts/cancels on early release and fills the detached rope from 30 to 100 on complete hold; role releases afterward.
- Patch pointer hold on the catwalk cancels early without consuming the hole; full hold removes the hole. Measured character-to-hole distance 9.529 stud, within the unchanged 10-stud validation limit. Capsule 196×50, background transparency approximately 0.65.
- Native E on custom pickup equips both Pistol and AK47. Full magazines 8/30, labels `8 / ∞` and `30 / ∞`; two shots spend exactly two rounds and destroy the registered 50-HP test target. Reload does not refill instantly and finishes at the magazine cap. Both Hit/Kill events reach the teammate; teammate hotbar remains enabled, gunner's hotbar hides and restores after drop.
- The dead teammate is tracked before a controlled `EndFlight(fd,true)` call. Arrival protection rejects puncture, balloon departs/destroys, both players are alive at the palace and receive exactly one summit. The observer receives the teammate's `ArrivalRevived` state. This is state replication evidence, **not** visual verification of every cinematic/particle frame.

Main Edit viewport after cleanup: 1066.4×536. Exact dimensions of the detached local client windows were not separately exported; these are desktop gameplay/input checks, not a responsive-layout or physical mobile certification. GUI inset `(0,58)` is recorded by the actual final client input fixture.

## Cleanup

[Build and driver hashes](build.json), [cleanup](cleanup.json), [post-cleanup manifest](place-after-cleanup.json). Returned to Edit / 0 players / 61 production sources, compile errors 0, fixture scan empty. Source, model/property, prompt, Terrain and environment manifest sections still match the freshly reopened baseline. No save/publish or persistent inventory changes; the original file hash remains unchanged. The extra read-only verification window is closed after fixture removal; the original Studio session is preserved.

## Boundaries

The [StudioTestService API](https://create.roblox.com/docs/reference/engine/classes/StudioTestService) launches real local multi-client simulations. Assertions inspect actual server state and client responses; setup still uses test-only managers/warp and mock profiles. Prompt/combat checks anchor the balloon; they do not prove moving-pointer ergonomics or physical phone/tablet behavior. Screenshot absence for an automated scenario means no new visual approval is claimed. Earlier HUD/device screenshots retain their earlier fixture/build scope.

Remaining: natural full flights, public network latency/jitter, physical phone/tablet, concurrent arrival FIFO/cinematics seen by another team, and persistent cloud/rejoin/checkout scenarios. These remain separate release gates.

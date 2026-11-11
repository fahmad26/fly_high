# Full-journey QA — 31 October 2026

> Historical run. Counts, hashes, environments and outcomes below belong to the recorded October build. This is not a pass report for the current workspace. [PROGRESS](../PROGRESS.md) tracks open findings; [WORKFLOW](../docs/WORKFLOW.md) defines evidence required for a new run. Keep failed raw results intact.

## Scope

One native Studio server runs six clients together: one solo crew (dock A), one duo (dock C), and one trio (dock E). Each crew travels from its dock to 10,000 km at production speed. Regular enemies, global hazards, storm walls, ammunition, reloads, repair hold durations, rope wear, damage and role restrictions stay enabled. Continuous journeys do not receive altitude skips, shields or replacement characters.

The bots use native dock interaction, validated pilot/weapon/tether remotes, and production manager validation. Role setup repositions avatars inside the basket. Repairers walk along the ring with `Humanoid:Move`; their movement and repair duration are not accelerated. The solo pilot leaves auto gas running and changes between gunner and engineer. Duo uses a pilot plus gunner/engineer; trio uses separate pilot, gunner and engineer.

The shooting bot selects a nearby obstacle and sends the ordinary validated firing remote. It exercises ammo, reload, raycast damage and presentation, but does not assess a human player's aiming or the client auto-aim selection algorithm. Lateral steering reacts to hazard warnings. Storm damage is repaired; this run does not assess how intuitive the jump counterplay feels.

## Controlled ending branches

After the continuous journeys, enemies/storms are paused and new crews are launched. Test-only fixtures set altitude to 2,000 km, apply five punctures and grant offline inventory using two valid `ModifyEmergencyKits(player, 1)` calls. These fixtures test Clutch Save, rejection of repeated use, the roughly three-second crash, Game Over, rope rescue, fatal rope ejection, surviving teammates, respawn, the real 60-second grounded timeout, native disconnect and cleanup.

`full_journey_client_playtest.luau` and `full_journey_server_playtest.luau` are temporary Studio-only drivers. The latter already contains `full_journey_ending_cases.luau`; that separate fragment is a maintenance reference, not another installed script. Run with `StudioTestService:ExecuteMultiplayerTestAsync(6, "FlyHighFullJourneyQA")`. Store its returned JSON in Edit mode so results survive native client shutdown. Remove drivers, remotes and result containers from the production place after testing. Restore the Studio client count to **1** and toolbar mode to **Test**.

## Diagnostic iterations

- First run stopped after 607 seconds, near 9,300 km, when the bot treated an interrupted patch hold as fatal. Server logs were clean. The fixture now walks opposite the hole before holding and records legitimate cancellations for retry.
- Second run stopped after 168 seconds when a rope-repair hold was cancelled. The bot now follows the moving station with ordinary humanoid movement and records/retries a cancelled hold up to three times. Production distance checks and repair durations are unchanged.
- Neither interrupted run establishes that all three crews reached the summit. Raw reports are preserved as `full-journey-diagnostic.json` and `full-journey-diagnostic-retry.json`.
- A subsequent run completed the solo journey in 708.45 seconds with 34 patches. Duo/trio reached 9,014/9,417 km before station reattachment was rejected. Its ending cases verified Clutch Save, crash timing, rope rescue/ejection, respawn and the grounded timeout. The raw report is `full-journey-partial-results.json`; it is **not** an all-pass report. One client warning in that report came from the Studio MCP camera-restoration action used for a screenshot. The harness now excludes only that exact automation warning, keeping all game warnings and errors.
- The station fixture now approaches from the clear inner basket at local `(0, 4, 6)`, allows settling, and retries attachment for two seconds while preserving production validation. Failed attachment includes role, range, floor position, anchor/seat state and rope reservations. `FlyHighDuoTrioQA` repeats twenty approaches for each crew before its uninterrupted full journey; it repeats only the two unfinished crew sizes, keeping a sixth client available for the ending cases.
- That retry still exposed climb/patch failures during rapid lateral manoeuvres. Its 44 checks contain 41 passes and three journey-related failures. Importantly, **all 37 ending/cleanup checks passed**, including native disconnect and empty tether/weapon reservations. Keep `full-journey-duo-trio-diagnostic.json` separate from any later passing journey report.

## Open lateral-movement finding

In the focused moving-platform reproduction, the client reported the repairer around local `(0.08, 20.64, -15.87)` while server-side hole distance was 11.07 studs, beyond the 10-stud validation radius. The server subsequently classified the player as Hanging. The local view was closer to the repair point. This establishes a client/server position discrepancy during rapid lateral steering; the exact contributions of replication delay and platform physics remain unconfirmed. Production range, role and fall validators have **not** been widened or bypassed to turn this case green.

A first focused fixture also moved a seated pilot during its altitude warp, moving the welded balloon a second time. It was corrected to warp before taking the helm. Subsequent fixtures acknowledge positioning on the owning client, use offsets relative to the moving balloon, and keep following the ring point while holding a patch. Diagnostic JSON files preserve both failures.

With the pilot holding horizontal position during repair, while auto gas keeps the balloon ascending, **eight complete trio repair cycles and three client log checks passed (11/11)**. See `moving-trio-repair-coordinated-results.json`. This focused test uses controlled altitude/damage and paused hazards; its original generic report header was inherited from the journey harness and does not describe those fixtures. The maintained probe source now labels them explicitly.

The final coordinated journey mode is `FlyHighDuoTrioJourneyOnlyQA`: native six-client session, five active crew plus one idle client, production hazards and altitude integration, pilot holds horizontal input only while the engineer repairs. It omits ending cases already verified separately. A successful coordinated route does **not** close the rapid lateral-movement finding.

Two setup-only attempts are also preserved: `coordinated-journey-setup-diagnostic.json` records a pose acknowledgement during lateral motion, and `coordinated-journey-dock-diagnostic.json` records a rejected launch. The final fixture settles horizontal motion before the station warm-up and waits for the production dock-clearance check before starting the next crew. Those attempts do not count as completed routes. Native dock input remains the real virtual E hold and the production prompt/boarding flow.

## Completed route evidence and terminal validation

`full-journey-coordinated-results.json` records **both duo and trio at 10,000 km** in the sample at 729.19 seconds. Duo completed 26 patches and trio 13. No altitude skips, shields or hazard pauses were used during these routes. The raw report nevertheless remains **failed**: the bot attempted further rope repair/attachment after Victory had removed those handlers. Do not relabel it as an all-pass run. The maintained harness now treats a repair cancellation as a normal terminal transition only when the server has actually declared Victory; all subsequent summit/docking assertions still apply.

The terminal branch was then tested independently with controlled altitude at 9,995 km and normal final ascent, while duo rope repair / trio patch holds were active. **28/28 checks passed**: five summit credits, five living palace arrivals, unanchored characters, cleared roles/tools, all client logs clean, empty reservations and natural model cleanup. See `victory-handoff-results.json` and `victory_handoff_server_playtest.luau`. An earlier terminal attempt encountered Roblox CoreGui `CreatorType` startup errors; its raw diagnostic is preserved separately and the successful repeat kept the same log assertions.

The evidence therefore covers a fully asserted solo route, normal-speed duo/trio routes recorded at the ceiling, and separately asserted co-op terminal handoff. It is **not** a single all-green end-to-end suite. The rapid lateral-movement finding above remains open. Publishing, cloud/Robux, public latency and human/device assessment remain deferred.

Final cleanup verified 29 compiled production scripts, no QA/probe instances, a saved place, Studio client count **1**, and toolbar **Test**. `full-journey-summary.json` indexes the evidence and records the saved place SHA256. This audit does not approve a release.

## Lighting lifecycle regression

The original controller ignored the Game Over flag and selected lighting from the last flight altitude. A one-player Play reproduction at 2,500 km confirmed that a failed flight kept Indigo lighting (`ClockTime=0.5`, `FogEnd=800`) instead of lobby Dawn. See `biome-lifecycle-original-failure.json`.

The correction restores Dawn on Game Over and lobby respawn, invalidates the previous fog timer, and preserves an active team's biome for a respawning Ghost Spotter. Victory stays Celestial until returning to the lobby. Separate native one-player drivers are `biome_lifecycle_server_playtest.luau` and `biome_lifecycle_client_playtest.luau`; run with `ExecutePlayModeAsync("FlyHighBiomeLifecycleQA")`.

The corrected controller passed **12/12** checks with clean server/client logs; see `biome-lifecycle-results.json`. An initial fixed-version attempt sampled during a startup tween (`FogEnd=883.84` approaching 800). That timing diagnostic is preserved separately. The final fixture waits for the avatar root and polls bounded eventual completion instead of assuming that a server-side 5.4-second sleep includes client startup and delivery time.

Cloud persistence, real Robux purchases, publishing, public-network latency and human/device comfort are outside this local automated run.

# OPEN-09 — CoreGui impact investigation

17 November 2026, Asia/Jakarta. Build `de8c273`, original place SHA-256 `d5e1eed6295891ddba751603916490ab60903285621c50214a933a7f14f9603a`. Windows Studio `version-63eb6055af4e4688`; disposable copy opened as unpublished `GameId=0`. Two real local clients per run, default desktop viewport (actual sizes in client snapshots), isolated mock profiles. No publish, inventory grant, persistent data edits or production source/model changes.

## Answer and severity

**No gameplay failure was observed from this error in the tested scenarios.** The affected client still moved, jumped and rendered Fly High's HUD. Earlier [duo gameplay results](../multiplayer-checkpoint-2026-11-17/duo-final-results.json) separately verify server repair/combat/reload/arrival while its observer recorded these errors. This does not certify every client-side function under the error.

**The issue is not dismissed as harmless console noise.** The exception occurs when reading the engine's `game.CreatorType` property on an affected local-test client; thirteen messages cascade through PlayerPermissionsModule, PlayerList, legacy TopBar modules and InspectAndBuy. These native modules failed to load. That presents a risk to native player-list/avatar-inspection/menu integration, although this investigation did **not** visually prove which native menu actions fail while the error is active. Keep OPEN-09 open with that distinction.

The same error/Studio local-server pattern has a [primary Roblox developer bug report](https://devforum.roblox.com/t/playerpermissionsmodule-corescript-module-frequently-breaks-causing-cascading-problems/3130688). That report describes missing menus/topbar; its symptom is corroborating context, not a substitute for current-build visual evidence. The installed Roblox owner-permission factory also reads CreatorType; [local source reference/hash](installed-source-reference.json). Runtime shipped-module line numbers may differ. No vendor/CoreScript was edited.

**The evidence points to intermittent Studio metadata/initialization behavior.** It does not establish the exact engine race or conclusively exclude an indirect timing contribution from game startup. The read-only metadata query itself fails on the affected VM. The same game code later runs with valid metadata and no errors. There is no production workaround/fix installed, and no suppression of native errors.

## Runs and actual outcomes

| Run | Metadata/errors | Actual gameplay observations |
| --- | --- | --- |
| [Game scripts enabled](game-enabled-results.json) | Player1: CreatorType read throws, 13 cascading errors. Player2: `User`, 0 errors. | Both move (5.32 / 3.85 studs), HUD present. Initial zero-duration jump injection produced 0 jump delta on both and is not used as gameplay evidence. |
| [29 game BaseScripts disabled](game-disabled-results.json) | Both `User`, 0 errors. | Movement 6.35 / 5.99 studs; jump rise 7.12 / 6.37 studs with corrected 0.1-second Space hold. This single healthy ablation run does not prove the issue can never occur without game scripts. |
| [Game scripts restored, repeat](game-enabled-repeat-results.json) | Player1: invalid CreatorType, 13 errors. Player2: `User`, 0 errors. | Affected client moves 5.28 studs and jumps 6.66; healthy client moves 6.54 and jumps 5.40. Both HUDs render. |
| [Game scripts restored, visual inspection](game-enabled-visual-results.json) | Both `User`, 0 errors, without production code edits. | Movement 4.55 / 6.78 studs and jump rise 5.73 / 6.60. Native UI inspection occurred on this healthy run. |

Fixtures: native virtual W/Space, targeted custom-settings click attempt, native Tab/Escape input probes, temporary bottom QA identity label. No altitude warp, shield, weapon entitlement or metadata injection in these impact probes. [Client probe](probe.client.luau), [server probe](probe.server.luau), [longer inspection server](visual-inspection.server.luau).

## UI evidence and important limits

- Saved Studio captures show the game HUD and auto-opened Daily Login on [affected Player1](game-error-player1.jpg) and [healthy Player2](game-healthy-player2.jpg), in the restored-game repeat. These captures do not establish native CoreGui visibility because the Studio capture excludes the native overlay.
- The custom-settings click probe reported `opened=false` on both clients. The Daily Login modal was open and intercepted the underlying click; this is not attributed to the CoreGui error. No setting or reward was changed.
- LocalScript CoreGui-tree inspection is restricted (the probe records a nil-service access inside pcall). Native Tab/Escape virtual input can also be refused as a permanently bound core action. These are tooling limits, not proof that the native menu is broken.
- Native menu opened through the Roblox icon on a healthy no-game-code client in Computer Use. That screenshot was displayed in chat only; it is **reported in session**, not a saved artifact. Affected-client native menu behavior remains unverified: inspection attempts outlived the earlier test clients. Do not promote the old report's missing-menu symptom to a verified local result.
- [Native tree Player1](native-tree-Player1.json) / [Player2](native-tree-Player2.json) were captured by Studio MCP in the final healthy inspection run. Both contain enabled TopBarApp and PlayerList layers; registration/enabled flags alone do not prove every feature works.
- No published Roblox Player run was performed. The problem is reproduced in local Studio multiplayer; absence of impact in a released/private live client is not claimed.

## Action and prevention

No change to Fly High gameplay or HUD is justified by these results alone. Repeating local tests produced healthy clients without source changes, but this is not a permanent fix. Before release, verify native menu, player list and avatar inspection in the intended Roblox Player/test environment. If reproduced there, retain that environment's metadata, stack and recording separately.

Future impact fixtures should close known startup modals before clicking underlying HUD controls, hold keys long enough to exercise movement/jump, record client viewport/metadata, and distinguish protected virtual-input failures from UI functionality. A source-prefix filter classifies messages; it does not prove native UI is healthy.

## Cleanup

All 29 BaseScript enabled states restored in the disposable copy; probes/remote/QA globals removed, Edit / 0 players / 61 production sources / 0 compile errors / 0 fixtures. [Cleanup record](cleanup.json). The copy is closed without saving and deleted after the investigation. Original Studio stays open in Test/default viewport, unchanged. Existing documentation/QA work from the previous task is preserved. Commit/push status at the time of the run: not yet committed. Subsequent checkpoint status belongs to Git history and [HANDOVER](../../HANDOVER.md); this report retains its original tested build/hash.

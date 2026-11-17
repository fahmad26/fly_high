# Local save and Git checkpoint — 17 November 2026

Base build: `main` at `6f6dc64`, plus the HUD/interaction, hotbar and other AI playtest fixes included in this checkpoint. User confirmed saving Studio to `E:\Antigravity\Fly High\Fly High.rbxl`. This run performs read-only verification; it does not publish or start another Play session.

## Saved file

- Size: **3,495,644 bytes**.
- SHA-256: `d5e1eed6295891ddba751603916490ab60903285621c50214a933a7f14f9603a`.
- Direct binary extraction: [binary-source-report.json](binary-source-report.json), produced with [verify-place-checkpoint.cjs](../../tools/verify-place-checkpoint.cjs). Requires Node with built-in Zstandard decoding; this verifier supports the current Zstandard-compressed file, not every historical Roblox compression variant.
- All **61** production script paths/classes are present in the binary, Studio and mirror. Binary source equals mirror after CRLF→LF and trimEnd normalization: **61/61**, no missing paths or mismatches. The mirror also contains 61 source files.
- [studio-checksums.json](studio-checksums.json) records byte lengths/classes/rolling checksums as supplemental evidence.
- [studio-exact-report.json](studio-exact-report.json) records **72 overlapping UTF-8 byte ranges** read from `ScriptEditorService:GetEditorSource` and compared directly against the binary source bytes: **61/61 scripts**, every range equal, coverage continuous from first to final byte of every script. No normalization for this Studio comparison. Temporary duplicate source export removed after comparison.

## Environment and actual results

Windows Roblox Studio, connected instance `5847b091-658c-4cee-b661-28c5ea116a09`, place `97043730132219`, universe `10776821830`, Edit / **0 players**. [studio-state.json](studio-state.json) preserves the response: **61 scripts compile, 0 compile errors, 0 `_QA_*`/FlyHighUserTest fixtures**. Workspace `FlyHighUserTest` attribute is absent. No new fixture, gameplay test, profile write, device simulation or scene edit was introduced by this checkpoint verification.

The temporary invulnerability/4×/mock-stock source rollback is retained; [rollback evidence](../user-test-2026-11-17/rollback-results.json) describes the earlier operation. The restored scripts are included in the current 61-source comparison.

## Included changes and earlier QA

- [Raised HUD and hidden native hotbar](../top-hud-hotbar-2026-11-17/README.md): desktop/iPhone/iPad simulator fixtures, custom combat HUD preserved.
- [Compact world-action prompts](../interaction-prompts-2026-11-17/README.md): 13 prompt families, capsule/circular key caps, 65% background transparency.
- [Alert/header and initial repair revision](../hud-repair-2026-11-17/README.md): historical first pass, superseded dimensions retained as history.
- [Other AI playtest fixes](../playtest-fixes-2026-11-17/README.md): fitted shield ellipsoid, CloudKetch moved outside the corridor and Terrain grass reverted. These changes are preserved.
- User accepted the latest HUD appearance in chat; this is visual feedback, not additional device or server gameplay evidence.

Earlier run reports retain their original Cloud versions, hashes and “not yet local/committed” statements. They describe those runs; this checkpoint supersedes the source/file-save status only.

## Limits and next verification

The saved file was parsed directly, **not reopened in a separate Studio session**. Script parity is proven above; full scene/model/property/Terrain equality with the open Studio session is **not** claimed. No new gameplay screenshots were generated for this source verification. Prior screenshots belong to their linked UI fixtures, not a fresh end-to-end flight.

Next QA: reopen the saved place and compare relevant scene properties, then test native server action outcomes and 2–3-player flight/arrival on the identified build. Physical phone/tablet checks remain open. This checkpoint does not mark release QA complete.

Commit/push identity is recorded by Git history and the final remote verification; it is separate from saved-file and source evidence.

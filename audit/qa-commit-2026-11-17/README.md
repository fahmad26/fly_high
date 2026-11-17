# Saved-place checkpoint before commit

17 November 2026, Asia/Jakarta. Base Git commit `de8c273d311ec09f7fca997e60bfccd4c5a70ba6`. Read-only inspection of the existing Edit Studio and newly user-saved local file. No gameplay/source edits, fixtures, Playtest or publication.

## Current file

`Fly High.rbxl`: 3,495,514 bytes; SHA-256 `71c0666af8d2fee2ef83f1d9fa29f28a7697baa60eda086556971eb10812b2df`.

The file changed after the earlier QA checkpoint (3,495,644 bytes; SHA-256 `d5e1eed6295891ddba751603916490ab60903285621c50214a933a7f14f9603a`). Preserve the user's new save. The reason for the 130-byte difference was not determined.

## Results and limits

- [Binary source report](binary-source-report.json): 61 production scripts; all full source contents match `audit/sources` after CRLF-to-LF and trimEnd normalization. No missing scripts or failures. Studio byte count/class/rolling checksums also match; that supplemental check is not full-content Studio equality.
- [Studio manifest](studio-manifest.json) and [comparison](manifest-comparison.json): source records, model geometry manifest, prompts, selected environment and sampled Terrain region match the earlier [multiplayer baseline](../multiplayer-checkpoint-2026-11-17/place-before.json). Probe scope/rolling-checksum limits are defined by [place-probe.luau](../multiplayer-checkpoint-2026-11-17/place-probe.luau).
- **This latest binary was not reopened in Studio.** The manifest compares current Studio with the old baseline, not the new binary's entire world. No full DataModel equality or new gameplay QA is claimed. Earlier multiplayer/CoreGui results keep their original tested hash.
- Edit/0 players retained; read-only checks require no fixture cleanup. Previous test cleanup records remain in their run folders.

Reproduction: run `tools/verify-place-checkpoint.cjs` against the saved file, `audit/sources`, and this folder's `studio-checksums.json`. Temporary raw source extraction was removed after validation; the report contains hashes and match results.

Commit and push are recorded separately by Git history; this report describes pre-commit verification.

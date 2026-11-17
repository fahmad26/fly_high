# Copy coverage correction — 18 November 2026

Base commit 2456f26. User screenshot shows AMBIL HANDGUN in English. Previous geometry QA included an untranslated AMBIL AK-47 fixture but treated fit as sufficient; this was a missed copy defect, not evidence that all action copy passed.

## Findings and correction

- Pickup renderer uppercases ActionText. Catalog had Ambil Handgun/Ambil AK-47 but no uppercase matches. Added AMBIL HANDGUN → PICK UP HANDGUN and AMBIL AK-47 → PICK UP AK-47.
- Added AKTIF → ACTIVE, BAHAYA → DANGER and koin → coins, including whitespace-composed fragments.
- Existing Bahasa / Language mapped to itself; corrected English to Language. Bahasa Indonesia remains the native language name deliberately.
- Added BLN → MONTH and removed BadgeGlyph from the localization exclusion list so the monthly leaderboard crest can translate. Player names, usernames and avatar letters remain excluded.
- 500 → 506 catalog entries, 59 dynamic formats; six appended keys, one existing English value corrected. No gameplay/data/receipt/weapon behavior changed.

## Evidence and limits

[Literal inventory](candidate-literals.json): scan of all mirrored Luau files collected 249 candidate Indonesian literals with file/line locations. These literals already mostly translated; this alone missed generated uppercase pickup text. Artificial lower/uppercase variants were explored but are not treated as real missing UI states or added wholesale.

[Runtime before](runtime-before.json): distinct untranslated strings across FlyHighHUD, lobby and palace, including hidden objects; manually classified names, numbers, English words and icons separately. [World prompt inventory](world-prompts.json) is an Edit snapshot, not a natural flight.

[Catalog test](catalog-final.json): 506/506 source-to-English checks passed with Indonesian unchanged; each parameter format uses one representative input (number 3, string Tali Awet, raw captures preserved). This is not exhaustive combinations or screenshots of every state. [Initial samples](catalog-check.json) preceded the Language value correction; final result supersedes them.

[Source check](source-check.json): changed Studio scripts match mirror normalized SHA-256 (CRLF→LF, trimEnd), all production scripts compile. Studio private universe 10776821830 / place 97043730132219 / session 40b5eed0-545b-4ff6-9174-53be3464aa14. Cloud v51 saved without Publish; local Fly High.rbxl remains the previous checkpoint and has not been downloaded/reopened for this revision.

Two post-change Play attempts were kicked by existing fail-closed data loading (Data belum dapat dimuat dengan aman). The temporary native-render QA driver could not run in PlayerScripts; no claim of post-change pickup/popup screenshots, touch/keyboard fit or native MONTH render. No data protection bypass, mock data, reward claim or real purchase. Stopped Play, Edit restored; Client fixture discarded. QA driver is archived in this folder only. Initial runtime inventory succeeded before these failed runs.

Native disconnect messages still require a separate server language decision; local UI translation cannot translate Roblox's native Kick dialog. Cloud Dashboard manual imports, physical devices, mixed-language clients and all natural conditional states remain open. No commit/push in this task. Untracked marketing files from another task were left untouched.

## Next verification

Once normal data loading succeeds, set English via actual Settings or a gameplay-context LocalScript, exercise both real pickup racks and inspect the rendered title, then review settings/shop/daily/login/leaderboards/flight/defeat/victory text in both languages. Translate-before-uppercase must be tested as displayed copy. Never count a geometrically fitting Indonesian label as a successful English check.

## Saved-file / Git checkpoint

User saved the local place after the QA run. Pre-commit parsing: 3,525,850 bytes, SHA-256 42c966afd3ac0e84e553cc14c2cd2444b46899f304013ca4ddd7104dee116d2e; [64 source contents](commit-check/binary-source-report.json) match mirror and raw checksums from the Studio instance currently opened from Fly High.rbxl (session 4606f99b-ff46-4aed-a089-7cf302bdcf9a, place 107361757876418, universe 10773510320). No claim that every world property equals the earlier private cloud place. No new Playtest or Publish. This commit includes the saved place, copy fixes and QA evidence; earlier not-saved/not-committed statements describe the run, not this checkpoint. Unrelated marketing drafts remain untracked.

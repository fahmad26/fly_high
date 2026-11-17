# Fly High — Indonesia / English

Status: approved

Approved scope: the user's 17 November request to carry out the localization proposal (Indonesian source, English support, per-player Auto/Indonesian/English selection, full UI/dynamic copy and image text). Preserve the existing Sky Adventure artwork and native interaction positions.

## Behavior

- Auto follows the player's Roblox locale: Indonesian locales use Indonesian, other locales fall back to reviewed English. Manual choice changes only that client, immediately, including existing world signs and newly spawned UI. Selection is local for the current session; no new persistence schema or purchase authority.
- Setelan keeps the two weapon racks and existing preferences. Following the iPad revision, language is the fourth button in the preference row, with a 2×2 grid below 380 px inner width. The picker opens upward and keeps three 44-pixel options: Auto (Roblox), Bahasa Indonesia, English. The active choice has a check and the existing selected-button style. Selection closes the picker; closing Settings closes it too. No server remote is required for a local display preference.
- Local native LocalizationTables render translations while original Text and prompt action data remain Indonesian. This preserves legacy HUD parsers for victory/reload/health. Each live object owns at most one small table, replaced on source updates and destroyed with the object. No per-frame polling or unbounded timer-string cache.
- A reviewed JSON catalog is authoritative; deterministic Luau/CSV exports support Studio and later cloud-table upload. Dynamic counts/time/player placeholders are preserved. Player names, chat, input fields and item identifiers are not word-translated.
- Images with Indonesian lettering use the existing live text fallback in English; icons, frames and number glyphs remain unchanged. English body copy may wrap; responsive controls remain at least 44 pixels high. No new image generation is required for text already available as live UI.

## QA and bounds

### Countdown stability — approved bugfix, 18 November 2026

Presentation-only alert/countdown labels translate before Text is assigned, with native AutoLocalize disabled. Retain Indonesian source in FlyHighDisplaySource so switching languages translates from the original. Grounded countdown, hazard title/detail and storm countdown use this writer. Parser/state labels retain their original Text and other UI keeps native tables. Verify repeated ticks frame by frame, ID/EN round trips and cleanup; settled screenshots or translator lookups alone cannot catch a one-frame language flash. [Implementation QA](../../../audit/prompt-alignment-countdown-2026-11-18/README.md).

### Approved revision — 18 November 2026

User approved the six audited string groups and touch prompt plan. Add catalog coverage for standalone Target Istana Awan/Balon Menurun!, biome notice prefix, uppercase numbered ZONA, summit count as a fragment when time is appended, and known ⚡/⚠ message wrappers. Preserve names, source Text and dynamic values. Touch prompt height 56 px (from 52), key circle 44 px (from 40), centered 32×20 text region with a bounded 9–11 px fit for HOLD/TAHAN. Keep existing location, transparency, progress, server input/hold semantics. Desktop/gamepad geometry and type remain unchanged. Test native rendered output and language switching in idle/hold/completion, phone/tablet and desktop. Physical iPad remains a separate acceptance check. Native disconnect dialogs are outside these two annotated requests.

Test Auto/id/en switching, unsupported-locale fallback, dynamic alert timers, shop/daily messages, two-rack loadout locks, custom repair/pickup prompts, result states and world signs. Check phone portrait/landscape, tablet and desktop. Record native-rendered screenshots as Text/ContentText intentionally retain source strings. Verify mixed-language clients independently when available. No real checkout, grants or reward claims for localization QA. Restore Edit/Test/one player/default viewport and remove all fixtures. Cloud configuration and saved local place are recorded separately.

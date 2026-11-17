# Fly High — Indonesia / English

Status: approved

Approved scope: the user's 17 November request to carry out the localization proposal (Indonesian source, English support, per-player Auto/Indonesian/English selection, full UI/dynamic copy and image text). Preserve the existing Sky Adventure artwork and native interaction positions.

## Behavior

- Auto follows the player's Roblox locale: Indonesian locales use Indonesian, other locales fall back to reviewed English. Manual choice changes only that client, immediately, including existing world signs and newly spawned UI. Selection is local for the current session; no new persistence schema or purchase authority.
- Setelan keeps the two weapon racks and existing preferences. A 44-pixel language button in the header opens a compact picker with three 44-pixel options: Auto (Roblox), Bahasa Indonesia, English. The active choice has a check and the existing selected-button style. This avoids adding a row that would overflow short landscape screens. Selection closes the picker; closing Settings closes it too. No server remote is required for a local display preference.
- Local native LocalizationTables render translations while original Text and prompt action data remain Indonesian. This preserves legacy HUD parsers for victory/reload/health. Each live object owns at most one small table, replaced on source updates and destroyed with the object. No per-frame polling or unbounded timer-string cache.
- A reviewed JSON catalog is authoritative; deterministic Luau/CSV exports support Studio and later cloud-table upload. Dynamic counts/time/player placeholders are preserved. Player names, chat, input fields and item identifiers are not word-translated.
- Images with Indonesian lettering use the existing live text fallback in English; icons, frames and number glyphs remain unchanged. English body copy may wrap; responsive controls remain at least 44 pixels high. No new image generation is required for text already available as live UI.

## QA and bounds

Test Auto/id/en switching, unsupported-locale fallback, dynamic alert timers, shop/daily messages, two-rack loadout locks, custom repair/pickup prompts, result states and world signs. Check phone portrait/landscape, tablet and desktop. Record native-rendered screenshots as Text/ContentText intentionally retain source strings. Verify mixed-language clients independently when available. No real checkout, grants or reward claims for localization QA. Restore Edit/Test/one player/default viewport and remove all fixtures. Cloud configuration and saved local place are recorded separately.

# Action alignment and countdown language stability — 18 November 2026

## Git checkpoint

Implementation, saved place and evidence are included in the commit containing this checkpoint update. Raw committed=false and not-committed notes below describe the QA run before this commit. No new Playtest or Publish during Git preparation; commit/push results are checked separately.

## Build and scope

Base commit `47da17491a7ada35f6ebcc9e107ae558db2d4f45`; initial working tree clean. Studio private universe `10776821830`, place `97043730132219`, session `99c49201-4035-4c84-abc2-289b979064bf`. Only six production scripts changed: HUDInteractionPrompts, Localization, LocalizationController, HUDTheme, FlightHUDController and FlightJumpController. Catalog remains 500 entries / 59 formats. No server gameplay, purchase, inventory or persistence changes.

## Reproduction and fix

- Action layout used fixed title/detail Y positions 7/26, ending at 41 in a 56 px touch capsule. The block was above centre. The shared renderer now measures both line heights, adds a 2 px gap and centres their combined block and input ring. Minimum capsule height is 50 keyboard / 56 touch; measured content plus 8 px top/bottom padding may enlarge it (normal keyboard sample: 52 px). Width continues to follow rendered text.
- [Baseline probe](baseline.json): eight consecutive new countdown strings lacked a matching native table entry immediately after Text changed. Updating a per-object table after each source write leaves an asynchronous rendering gap; this explains the language flash. This probe establishes the gap, not a frame-by-frame recording of the user's physical iPad.
- `Localization.SetDisplayText` translates before assigning Text on presentation-only countdown/alert labels. `FlyHighDisplaySource` retains the Indonesian source separately. LocalizationController opts these labels out of native AutoLocalize, removes their transient table, and refreshes the retained source on language changes. Underlying HUD state labels/parsers keep their existing Indonesian Text. Grounded countdown, hazard warning title/detail and storm-wall countdown use this path; other UI retains its native localization tables.

## Actual QA

Play Solo, Windows Studio, one client. Game orientation LandscapeSensor; portrait unsupported and not tested. All interaction prompts are local fixtures at spawn with native ProximityPrompt eligibility/input, not real server repairs or a full flight. [Fixture](qa-fixture.luau) and [countdown driver](countdown-driver.luau) are audit files, not installed in the saved place.

| Environment | Actual viewport | Cases / result |
| --- | --- | --- |
| [iPad Pro M5 13in](tablet-ipad-pro.json) | 1373×1030 | 13 families × ID/EN, centred and fits |
| [iPad 6th generation](tablet-ipad6.json) | 1021×766 | 13 families × ID/EN, centred and fits |
| [iPhone 17 Pro](phone-iphone.json) | 749×381 | 13 families × ID/EN, centred and fits |
| [Galaxy A06](phone-galaxy-a06.json) | 705×338 | 13 families × ID/EN, centred and fits |
| [Galaxy Tab A8](tablet-galaxy-a8.json) | 958×599 | 13 families × ID/EN, centred and fits |
| [Desktop keyboard](desktop.json) | 984×448.8 | 13 families × ID/EN, centred and fits |

156 geometry cases passed, centre error 0 in every recorded case. Input can change with Studio/user mouse activity: the iPad Pro matrix contains keyboard samples during the English pass, identified by E in the JSON. English touch on iPad was checked again for HelmPrompt ([screenshot](tablet-helm-en.jpg)); the phone matrices also cover English touch across all families. Do not label every iPad matrix row touch-only.

[Hold/cancel/completion](hold.json) passed on RepairRopePrompt. [Phone hold screenshot](phone-hold-en.jpg) shows the progress disc and vertically centred two-line text. [Enlarged font fixture](enlarged-font.json), title 23/detail 18 px, grew the capsule to 59 px with 8 px equal margins and no clipping. This is a font stress fixture, not a physical device or account PreferredTextSize Large test.

[Countdown monitor](countdown-final.json): 120 rapid timer updates, four ID/EN switches, 374 rendered frames / 809 checks / zero mismatches. Monitored actual HUDCountdownNotice, hazard AlertTitle/AlertDesc and storm Title. Warning remotes sent controlled visual fixtures; client InFlight and timer attributes were temporary and restored. Asserted AutoLocalize=false and Text equals translation of retained source on each sampled frame. No actual flight, damage, inventory or summit data changed. [Console](console.txt) contains only an Assistant camera-reset message, no gameplay error.

The first language-switch probe used MCP's require context, which did not switch the production controller. It was discarded; final language matrices use a temporary LocalScript in the gameplay context. Screenshots use Studio capture resolution, which may be smaller than the recorded viewport.

## Source, save and cleanup

[Final manifest](final-studio-manifest.json): 64 scripts compile and normalized SHA-256 matches all mirrors (CRLF→LF, trimEnd). Hash API checked against the SHA-256 `abc` test vector. Cloud **v48** saved without Publish. Download a Copy updated `Fly High.rbxl`: **3,527,607 bytes**, SHA-256 `de9b6b97043672793d3dd1ddb810aab4a0378afbc2b1a3ca79bf16976a443656`. [Binary parse](binary-source-report.json): 64 source contents match mirror and supplemental raw Studio checksums. Binary not reopened; this does not prove all world properties match.

[Early binary read](binary-source-report-early-read.json) happened before asynchronous file saving completed and used the wrong supplemental checksum algorithm. It is retained as a failed attempt, superseded by the final report with the new hash and matching source. Temporary full binary-source dump removed after verification.

Cleanup observed: temporary Part/prompts and both LocalScript drivers destroyed; language preference restored, client InFlight/timer attributes restored; stopped Play, Edit / default device / one-player Test preserved. No fixture in the saved Edit place. Not committed/pushed or published in this task. Physical iPad/mobile, account Large text, gamepad and natural server actions remain separate QA.

## Preventing recurrence

Use the pretranslated writer only for display-only labels and preserve source separately for language changes. Keep parser/state labels independent. Check rapidly changing alerts across many rendered frames, not only the settled translator result; verify actual gameplay-context language switching. For prompts, centre the measured two-line block rather than assigning fixed offsets, and rerun all registered families on keyboard and touch after font/localization changes.

# Fly High — Full-image HUD art

Status: approved

User approved the proposal with “Oke lakukan”. First delivery is the complete jump-button artwork for visual review before extending the style to the other families.

## Goal

Replace the current HUD artwork with individually generated, cohesive assets. The user requested an asset proposal before generation. Previous HUD approval does not approve this new visual direction. Preserve gameplay and server validation.

## Visual contract proposed for approval

Sky-adventure cartoon arcade: cyan/teal, cream and warm gold, navy outlines, rounded silhouettes, restrained depth and soft highlights. Orange marks thrust and warnings; red marks immediate danger. Avoid dense diagonal textures, metallic dashboard framing, tiny details and excessive glow.

Generate one usable asset at a time, never crop a contact sheet. Every action image includes its complete silhouette, border, depth and pictogram. Jump includes the entire circle and arrow in one PNG. No additional procedural circle, duplicate arrow or shine layer. Transparent exterior with consistent optical padding; controls retain a separate invisible rectangular touch target.

Use Fredoka One for short headings and button captions, with a readable rounded supporting face such as Nunito for values and body text. Confirm the exact Roblox-supported fonts before implementation. Keep names, altitude, velocity, timers, ammunition, inventory counts and prices as live text. Compose short captions separately using the same font for consistency and localization; do not rely on image generation to spell labels correctly.

## Asset families and source canvas sizes

Sizes are source pixels, not on-screen touch sizes. Variants are separate complete PNGs with matching bounds.

| Family | Source canvas | Composition and states |
|---|---|---|
| Jump | 512 × 512 | Full cyan circle, rim, depth and white upward arrow; normal, pressed, locked |
| Fire | 512 × 512 | Full orange/red control and target pictogram; normal, pressed, locked |
| Thrust | 512 × 512 | Full orange control and burner/flame; normal, pressed, locked |
| Automatic thrust | 768 × 256 | Full pill and flame/loop motif; off, on, pressed, locked |
| Release helm | 512 × 512 | Full compact button with helm/release motif; normal, pressed |
| Reload and drop | 512 × 512 each | Full compact controls and unique pictograms; normal, pressed, locked |
| Kit | 512 × 512 | Complete medical-kit tile; available, empty, clutch-save, pressed |
| Ping, sound, shop | 512 × 512 each | Complete side-dock tiles; normal and pressed, sound on/off |
| Tether actions | 768 × 256 each | Attach, detach, climb, descend, patch, repair rope, pull teammate; full controls with unique pictograms; normal, pressed, locked |
| Altitude | 1024 × 256 | Cloud/balloon-themed frame, open live-number area and progress track |
| Flight progress | 1024 × 64 | Separate track, fill and goal marker; stretch-safe fill |
| Hull | 768 × 256 | Compact envelope/health frame; normal, damaged, critical |
| Hull segments | 128 × 64 each | Intact and torn segments; differences visible without color |
| Ammunition | 768 × 256 | Compact full panel with open number area; normal and empty |
| Pistol and rifle portraits | 512 × 256 each | Consistent illustrated weapon silhouettes for ammunition/shop panels |
| Rope condition | 768 × 192 | Full frame, rope track and frayed/broken indicators |
| Warning | 1024 × 192 | Full amber warning banner; critical red variant, open live-copy area |
| Role and contextual prompt | 768 × 256 | Full prompt frame with icon area and live action/key text |
| Player overhead | 768 × 256 | Lightweight full nameplate and master crest; live name and record |
| Ping selection | 512 × 512 base; 256 × 256 choices | Full picker shell and five complete choice tiles; normal/selected |
| Shop | 1024 × 1024 shell; 512 × 768 cards | Full modal and kit/AK cards, open price/copy regions |
| Buy and close | 768 × 256; 256 × 256 | Complete purchase pill and close control; normal, pressed, locked/loading |
| Result and notices | 1024 × 512 | Victory, game-over and notice frames with open live-copy regions |

Do not replace Roblox-owned menu/chat/capture interfaces. World dock signage is a separate scope; the overhead is included because it shares this HUD style.

## Responsive layout

Phone first, tablet and desktop next. Respect Core UI safe areas and system gesture margins. Keep large jump/fire targets at lower right with a deliberate gap; reserve lower left for the native joystick. Desktop key labels are separate live chips and hide on touch. Only applicable role actions are visible. Preserve persistent auto-thrust/release controls without an extra menu. Scale whole square artwork uniformly; do not stretch circles. Use deliberate nine-slice boundaries only on suitable panels, never across artwork or pictograms.

Images do not replace responsive constraints: maintain readable live text, aspect ratios and touch targets across portrait and landscape.

## States and interactions

- Default: applicable controls use normal art; pressed uses an visibly depressed matching image with unchanged bounds.
- Empty: kit zero, ammunition zero and no flight have explicit art/copy rather than disappearing context.
- Loading: preload artwork; one clean fallback per control until ready; prevent overlapping fallback and image.
- Error: show a short native text notice and stable fallback if an asset fails. No permanent blank input targets.
- Locked: distinct subdued artwork, lock marker and reason; server remains authoritative.
- Feedback: restrained press/release transitions, with reduced motion where appropriate. Do not pulse or animate jump continuously.

## Jump glitch investigation

Source inspection found two presentation risks, not a confirmed runtime root cause: HUDGlyphs displays a text fallback until an IsLoaded property signal updates it; FlightJumpController writes AutoButtonColor and BackgroundTransparency while HUDTheme also controls appearance. Consolidate presentation ownership, remove duplicate glyph layers, and verify native touch jump stays hidden across respawns. Do not change jump permissions or input behavior.

## Delivery and verification

> Catatan status 11 November: brief ini adalah rekaman keputusan desain. Generasi, upload dan pemasangan Sky Adventure telah dilakukan setelah brief disetujui; lihat [katalog aktif](../../../assets/ui/sky-adventure/README.md) dan [PROGRESS](../../../PROGRESS.md) untuk cakupan QA. Daftar langkah berikut menjelaskan rencana saat brief disusun, bukan backlog yang harus dimulai ulang.

At the time of drafting, the approved plan was to generate and review the jump asset first at actual phone/tablet display size, then complete the remaining families individually. Preserve PNG sources and a manifest recording states and upload IDs. Verify replacements before deleting prior assets. Acceptance checks cover pressed/released/locked/loading/failure states, respawn, role changes, multi-touch, portrait phone, landscape phone, iPad, desktop, image readiness, font readability, overlap and console output. Current implementation and evidence are tracked in the linked catalog and PROGRESS.

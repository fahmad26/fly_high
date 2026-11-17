# HUD alerts, header and repair

Status: approved — scope follows the user's three explicit requests on 17 November 2026 and the approved flight-hud design; implementation details below use the existing Sky Adventure system.

## Revision 4 — centre the measured action text block

User request 18 November: all action title/detail pairs must be vertically centred on desktop, phone and tablet. Measure both rendered line heights, separate them by 2 px and centre the combined block. Keep at least 8 px top/bottom padding; capsule height may grow for larger fonts. Re-centre the input ring when height changes. Preserve transparency, world anchor, width fitting and native hold/input semantics. Touch uses the 56 px minimum / 44 px circle from the localization revision. Earlier dimensions below are historical.

## Revision 3 — use the empty topbar area and hide native weapon slots

User requests a higher centre HUD and no native weapon hotbar on desktop, tablet or phone. The centre header moves into GuiService's TopbarSafeInsets rectangle with 6 px top spacing and 8 px horizontal spacing, clamped to the free area. The left hull panel keeps its safe position. On screens too narrow for the header plus native controls, retain the lower safe row. Warnings follow the header or the hull row according to available width. Modals and other controls retain CoreUISafeInsets.

Hide only CoreGuiType.Backpack while a configured Fly High weapon Tool exists in Character or Backpack. Preserve its prior enabled state when the weapon disappears, and retry if CoreGui initializes late. Do not change Tool parent, server ownership, native topbar, health/chat/touch controls, or the custom ammo/fire/reload/drop HUD. Use rack pickup and existing custom controls as before; native Backpack number-key selection is unavailable while its UI is disabled.

## Revision 2 — compact capsules and all world actions

User requested smaller, more transparent repair actions, fully rounded ends/circular key caps, and custom presentation for other native actions. This revision supersedes the card dimensions below.

- Panel 196 × 50 px on keyboard/gamepad, 196 × 52 on touch; the whole capsule remains a touch target exceeding 44 px height. Background transparency 0.65, border 0.55, circular key cap 32/36 px with radius 0.5; outer radius 0.5 makes a true capsule.
- Shared renderer covers 13 prompt families: patch, rope repair, helm, weapon pickup (Handgun/AK-47), flight start, return portal, victory photo, furniture seats, attach/detach rope, climb, descend, rescue crew. Native enabled state, key mapping, hold duration, distance and exclusivity remain owned by existing gameplay.
- Existing bottom HUD actions keep their disabled world prompts disabled. Registration changes style only, including future streamed/spawned prompts and prompts renamed after parenting.
- Tap and hold share the same capsule. Tap has no progress track; hold uses a thin inset track. Pickup title follows the live ActionText so Handgun and AK-47 remain distinct.
- The compatibility repair module forwards to the shared renderer; initialization is idempotent. World location/UIOffset is preserved. World prompts render below the main HUD/modal screen layer.

## Original revision (historical dimensions)

- All regular and storm alerts: raise the two-line text block by 4 px; preserve at least 10 px bottom clearance and avoid clipping for larger text.
- Header: use the popup's existing navy/gold/turquoise nine-slice frame, matching circular navy/gold emblem with a flat intact coral balloon. Keep lobby, dock, loading, biome, descending, turbo and palace states and text intact. No new uploaded asset needed.
- Repair balloon and rope: custom screen layer projected from the native ProximityPrompt world anchor/UIOffset, with navy background at 0.35 transparency, muted gold border, stable key/touch cap, action label and hold progress. Keep server hold duration and eligibility. Only PatchPrompt and RepairRopePrompt change style. Projection updates each rendered frame as the balloon/camera moves.
- Desktop: actual key displayed; gamepad: actual mapped gamepad key; phone/tablet: touch hold on the entire 216 × 72 panel (desktop 248 × 72). Same world anchor across sizes; no bottom-screen replacement or joystick overlap by fixed positioning.
- States: available, holding, cancelled/reset, request pending, hidden/disabled/destroyed, death/respawn. No claim of repair success until the server updates the prompt. No stock/loading UI: those remain with their existing authoritative systems.
- Cancel pointer hold on release, focus loss and prompt removal; clean connections/tweens/GUI. Keyboard/gamepad keep native prompt input processing, touch/mouse feed InputHoldBegin/End.
- QA: all alert surfaces and header states at desktop, phone landscape and tablet; separate hold/release/cancel/complete lifecycle checks. The game uses LandscapeSensor, so portrait is outside the supported flow. Simulator/layout checks are not physical mobile QA.

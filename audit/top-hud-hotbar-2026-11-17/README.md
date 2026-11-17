# Raised centre HUD and hidden weapon hotbar — 17 November 2026

Implementation available; user requested less empty space above the header and removal of the native weapon slot. [Design revision 3](../../design/features/hud-repair-consistency/design.md).

## Changes

- `HUDLayout` places the centre header 6 px from the top of the unoccupied native topbar region, with 8 px horizontal clearance. It reads [GuiService.GetInsetArea](https://create.roblox.com/docs/reference/engine/classes/GuiService#GetInsetArea) with `TopbarSafeInsets`, recalculated during layout. Horizontal placement is clamped to avoid native controls. If the free strip is too narrow, it retains the lower safe row. Hull, utility buttons, modals and the rest of the ScreenGui keep CoreUISafeInsets. Warning placement follows the lifted header or the hull row.
- New client `WeaponHotbarController` hides only `CoreGuiType.Backpack` while a configured Pistol/AK47 Tool exists in Character or Backpack. It restores the previous state when the weapon is removed, watches container/character changes, and retries late CoreGui initialization. No Tool reparenting, server weapon handling, combat input or ammo logic was changed. Native Backpack number-key selection is unavailable while that CoreGui is disabled; Fly High uses rack equip and custom reload/drop controls.

Baseline: `6f6dc64` plus prior uncommitted HUD, prompt, VFX/scenery, place and documentation work. The original HUDLayout matched Studio/mirror after CRLF→LF/trimEnd normalization and is saved under `baseline/`. Only layout and a new client hotbar controller were changed for this task. Concurrent changes were preserved.

## QA

Windows Studio Solo, Fikki2621. [Raw responses and source hashes](results.json). Client-only fixtures set local HUD flight state and clone temporary weapon Tools. They do not grant inventory, run a real flight, or prove server shooting/reload/drop outcomes.

| Environment | Actual header result | Weapon result |
| --- | --- | --- |
| Desktop 1066.4 × 536 | Lobby and flight raised; top margin 6 px, inside free horizontal region; title/detail fit | Pistol and AK47 equipped remain in Character; native Backpack disabled; custom ammo/reload/drop visible |
| iPhone 17 Pro simulator 749 × 381 | Same; flight header clamps to x=216 to avoid left native controls/notch | Same, including Backpack→Character→Backpack→removed transitions |
| iPad Pro M5 13in simulator 1375 × 1030 | Same, centered within available width | Same |
| Layout-only QA width 320 | Header falls back to y=8; width 296, x=12, fully within 320 | Not a physical device test |

For both weapons in all three environments, native Backpack stays hidden while the Tool is equipped or stowed, and the original enabled state returns after removal. This confirms the custom presentation remains available; no real server fire/reload/drop outcome was tested.

Initial attempt: using StarterGui.CoreGuiChangedSignal in a LocalScript failed due to its RobloxScript capability. That listener was removed and replaced with normal container events plus bounded initialization retries. The failure was observed in chat only, not exported as an engine log. The subsequent final play session console was empty. Both final scripts compile and match exported mirrors after stated normalization.

Screenshots: [desktop equipped, no native slot](desktop-equipped.jpg), [phone raised header](phone-header.jpg). Their flight/status state is locally injected; they are UI fixtures, not a real 2400 km journey. Physical phones/tablets and gamepad were not tested. The place uses LandscapeSensor.

## Cleanup and persistence

Studio returned to Edit/0 players/default viewport. Probe GUI, QA attributes and local test Tools were discarded with Play; final fixture scan is empty and the earlier temporary cheat flag is absent. Saved to **Cloud version 27**, not Publish. No commit/push requested. Local `Fly High.rbxl` was not reopened/compared and is not claimed to contain this change yet.

# Sky Arcade HUD — 31 October 2026

The user's reference established a bright arcade direction rather than the previous dark prototype panels with small decorative icons. The current HUD uses saturated blue/cyan, green repair, orange ascent, red danger, heavy dark outlines, inner highlights, subtle depth and outlined Fredoka labels. A centered flight header prioritizes altitude, with a compact five-segment hull card, four navigation tiles, a contextual action row and a separate gunner control cluster. Pilot gas lock and helm release remain direct controls. The old AKSI tray is no longer part of this composition.

`HUDGlyphs` draws scalable white UI silhouettes. `HUDTheme` owns surfaces and presentation; `HUDLayout` owns bounds. Gameplay controllers retain the same button instances, handlers, role rules, remotes and canonical data labels. Illustration loading is optional and serialized for only the four used keys. All 27 user PNGs and uploaded IDs remain available; none were edited or re-uploaded.

## Evidence and limits

`hud-arcade-phone.jpg` is an unedited Studio capture of the running HUD, not a generated mockup. `hud-arcade-results.json` records 12 device/state samples: iPad landscape gunner/shop/pilot/critical damage/engineer; portrait engineer/storm; portrait phone engineer/gunner; final landscape phone gunner/pilot; desktop gunner. All recorded project button bounds fit, targets meet 44 pixels, button pairs do not overlap and visible text fits. Core Roblox overlays and 3D proximity prompts remain native; these are outside that project-button-pair check.

Native window clicks verified shop open/close, auto gas ON, helm release preserving gas and a kit clearing four holes. A fresh phone session credited one real jump. During an earlier role-cycled anchored fixture with auto gas enabled, a jump button activation reached the client but did not increment the server counter; its cause is unresolved. No jump physics/validation code was changed, and this does not constitute a full gameplay regression pass.

The fixture anchors the balloon and pauses hazards, so these checks do not cover flight physics, public-server latency, purchases or physical devices. The complete 27-image inventory is not claimed load-verified. Core UI appearance no longer depends on that inventory loading. After the last full live scenes, a short cooldown badge, explicit rope-repair hold label and removal of two unused preload requests were compiled and saved; these small changes were not given another full scene run.

Final cleanup: temporary TabletUIQA removed, 32 source containers compile, live changed sources match their mirrors, and Studio returns to Edit / Test / desktop. Backup: `Fly High.before-hud-redesign.rbxl`. Prior integration reports remain historical evidence.

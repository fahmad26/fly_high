# Fly High — final compressed UI assets

> Current design: Sky Arcade. All 27 uploaded IDs remain preserved. Core HUD controls, glyphs, gradients and borders now render directly with Roblox UI; four optional illustrations are used. Earlier integration/loading notes below describe the previous image-led prototype. See `../../../../audit/HUD_ARCADE_REDESIGN.md` and the canonical manifest for the active design.

27 PNG supplied by the user and uploaded to Roblox through the connected Fly High.rbxl Studio on 2026-10-31. All image dimensions match the planned export targets. Source bytes were not modified.

`roblox-asset-ids.json` maps each filename to its returned Roblox image ID. `source-audit.json` records source dimensions, lengths and SHA-256 hashes. The canonical manifest is `../../asset-manifest.json`. All 27 IDs are now wired into HUDImageAssets/HUDTheme in the saved place. Image rendering is conditional on successful loading; 7 images loaded in Studio, while 20 retain original control presentation. See `../../../../audit/hud-images-results.json` for integration checks and limitations. No source images were edited.

| File | Resolution | Roblox image |
|---|---|---|
| `control_circle_normal.png` | 512×512 | `rbxassetid://103129971812686` |
| `control_circle_pressed.png` | 512×512 | `rbxassetid://73541054583304` |
| `control_circle_disabled.png` | 512×512 | `rbxassetid://83631720689910` |
| `jump_arrow.png` | 256×256 | `rbxassetid://134915712312480` |
| `fire_target.png` | 256×256 | `rbxassetid://130345737141401` |
| `aim_reticle.png` | 256×256 | `rbxassetid://92435439695269` |
| `burner_flame.png` | 256×256 | `rbxassetid://78927787373191` |
| `emergency_kit.png` | 256×256 | `rbxassetid://124454343942952` |
| `helm.png` | 256×256 | `rbxassetid://103615791844589` |
| `helm_release.png` | 256×256 | `rbxassetid://129496037588586` |
| `rope_attach.png` | 256×256 | `rbxassetid://131371711483262` |
| `rope_detach.png` | 256×256 | `rbxassetid://101141157478051` |
| `rope_climb.png` | 256×256 | `rbxassetid://84749963770786` |
| `rope_descend.png` | 256×256 | `rbxassetid://90768025375567` |
| `patch_repair.png` | 256×256 | `rbxassetid://129313674817197` |
| `rope_repair.png` | 256×256 | `rbxassetid://134330609503010` |
| `crew_rescue.png` | 256×256 | `rbxassetid://80037291958003` |
| `shop_supply.png` | 256×256 | `rbxassetid://130991989483112` |
| `team_ping.png` | 256×256 | `rbxassetid://125897278409378` |
| `sound_on.png` | 256×256 | `rbxassetid://135591436991154` |
| `sound_off.png` | 256×256 | `rbxassetid://104567673131313` |
| `warning_badge.png` | 256×256 | `rbxassetid://133110984727781` |
| `balloon_intact.png` | 128×128 | `rbxassetid://102772330060648` |
| `balloon_torn.png` | 128×128 | `rbxassetid://130748218921310` |
| `weapon_pistol.png` | 512×256 | `rbxassetid://99082950855244` |
| `weapon_ak47.png` | 512×256 | `rbxassetid://121163530661782` |
| `panel_9slice.png` | 512×256 | `rbxassetid://119752524819445` |

Load verification: 7/27 returned Success; 20/27 returned Failure after initial HTTP 429 responses, unchanged on a paced second check. See `upload-report.json`. All 27 uploads returned IDs, but visual load verification is incomplete. Do not assume the 20 failures mean a rejected upload or moderation outcome.

# HUD image integration — 31 October 2026

The saved place uses the user's 27 compressed PNG asset IDs through `HUDImageAssets` and `HUDTheme`. `HUDLayout` calls the theme after each layout pass so image children follow the existing bounds and modal Z order. Existing controllers retain their input handlers, role validation, visibility, and dynamic text. Decorative ImageLabels are not active or selectable.

Jump/fire use the combined circular artwork directly, without stacking another circle underneath. Rectangular action controls keep labels and optional icons, and use the 9-slice panel when it loads. The small icon medallion uses normal/pressed/disabled bases; pressed controls also darken visibly. Balloon damage icons, warning badges, reticle, weapon type, sound mute state and all rigging actions have mappings. Missing art preserves native text and backgrounds instead of an empty button. The hole count uses `n/5` to fit phone widths.

Loading uses ImageLabel instances, serial requests and a bounded three-pass retry with increasing pauses. The theme disconnects input and descendant listeners and cancels its loading worker when its GUI is destroyed. See Roblox's [ContentProvider reference](https://create.roblox.com/docs/reference/engine/classes/ContentProvider) and [ImageLabel reference](https://create.roblox.com/docs/reference/engine/classes/ImageLabel) for the APIs used.

## Verification and limits

- Single-player stationary Studio fixture: desktop 2090×694; phone 749×323; iPad landscape 1179×761 and portrait 819×1120. Gunner, pilot and attached engineer layouts checked. No project button overlap, out-of-bounds controls or visible text overflow in recorded profiles. Touch targets meet 44 pixels; small desktop targets are not touch failures.
- Native window clicks verified sound ON/OFF artwork and caption, auto gas ON, helm release preserving auto gas, and one accepted server flight jump. Native joystick remains enabled; native jump remains hidden.
- Phone fire was moved another 24 pixels left after visual inspection to clear Roblox's capture overlay. Final phone gunner profile verifies that spacing and the shortened hole count. Earlier desktop/iPad profiles preceded those two refinements.
- 31 source containers compile; live changed modules match source mirrors. Temporary `TabletUIQA` removed before saving. Final Play log contains only the expected unpublished Studio mock-data notice, with no warnings/errors. Studio left in Edit, Test, Current device desktop.
- **Only 7/27 original image IDs loaded successfully. The other 20 remained Failure after the earlier HTTP 429 responses.** The complete artwork, including 9-slice panel, circular bases and weapon art, is therefore not visually verified. These components currently use native presentation where necessary. No image re-upload or asset-ID substitution was performed.
- This is UI verification, not a new flight-physics, live purchase, public-server or physical-device test. The fixture anchored the balloon and paused hazards. It was removed from the production DataModel.

Machine-readable evidence: `hud-images-results.json`. Pre-change place backup: `Fly High.before-hud-images.rbxl`.

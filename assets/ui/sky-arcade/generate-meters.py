"""Generate individual HUD images for telemetry glyphs and fixed state labels."""
from math import ceil
from pathlib import Path
from runpy import run_path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).parent
OUT = ROOT / "png"
lettering = run_path(str(ROOT / "generate-lettering.py"))
font = ImageFont.truetype("C:/Windows/Fonts/arialbd.ttf", 72)
glyphs = {str(n): str(n) for n in range(10)}
glyphs.update({
    "dot": ".", "comma": ",", "plus": "+", "minus": "−", "slash": "/",
    "percent": "%", "dash": "—", "km_s": "km/s", "seconds_short": "s",
})

for key, glyph in glyphs.items():
    image = Image.new("RGBA", (ceil(font.getlength(glyph)) + 8, 84))
    ImageDraw.Draw(image).text(
        (image.width / 2, 65), glyph, anchor="ms", font=font, fill="#f7fbff",
        stroke_width=4, stroke_fill="#071326",
    )
    image.save(OUT / f"meter_glyph_{key}.png", optimize=True)

for key, value in {
    "choose_dock": "PILIH DERMAGA",
    "hull_loading": "MEMUAT KONDISI",
    "hull_critical": ("KRITIS", "#ffd48d"),
    "hull_freefall": ("TERJUN BEBAS", "#ffb6aa"),
    "kit_empty": "KIT HABIS",
    "kit_loading": "MEMUAT KIT",
    "kit_used": "KIT TERPAKAI",
    "kit_shield": "PERISAI AKTIF",
    "reload_empty": "ISI ULANG",
    "ground_pilot": "Tahan gas untuk lepas landas",
    "ground_crew": "Pilot belum lepas landas",
    "storm_title": "Dinding Badai",
    "scrim": "",
}.items():
    if key == "scrim":
        Image.new("RGBA", (16, 16), (4, 10, 22, 166)).save(OUT / "meter_scrim.png")
    else:
        lettering["render"](key, value, prefix="meter_")

"""Render independent, transparent lettering sprites for Fly High's fixed labels."""
from pathlib import Path
from math import ceil

from PIL import Image, ImageDraw, ImageFont

FONT_DIR = Path("C:/Windows/Fonts")
OUT = Path(__file__).parent / "png"
LABELS = {
    "shop_toggle": "TOKO",
    "kit_use": "KIT",
    "kit_clutch": "SAVE!",
    "ping_toggle": "PING",
    "audio_on": "SUARA",
    "audio_off": "BISU",
    "gas": "GAS NAIK",
    "auto_on": "OTOMATIS: ON",
    "auto_off": "OTOMATIS: OFF",
    "release": "LEPAS",
    "drop": "LEPAS",
    "reload": "ISI",
    "attach": "PASANG TALI",
    "detach": "LEPAS TALI",
    "climb": "NAIK KUBAH",
    "descend": "TURUN",
    "patch": "TAHAN TAMBAL",
    "repair_rope": "PERBAIKI TALI",
    "pull": "TARIK REKAN",
    "spot": "TANDAI BAHAYA",
    "ping1": "Gas Api Sekarang!",
    "ping2": "Awas Tornado Menghindar!",
    "ping3": "Tali Saya Mau Habis!",
    "ping4": "Saya yang Perbaiki!",
    "ping5": "Fokus Tembak Rintangan!",
    "brand": ("FLY HIGH", "#edfbff", 72),
    "goal": ("ISTANA AWAN • 10.000 KM", "#ccecff"),
    "km": ("KM", "#a8e5ff"),
    "hull_safe": ("BALON AMAN", "#beebff"),
    "hull_damage": ("KONDISI LAMBUNG", "#beebff"),
    "hull_0": ("▲ Kecepatan Naik Optimal", "#a6f7b7"),
    "hull_1": ("▲ Naik Sedikit Melambat", "#ffe6a1"),
    "hull_2": ("■ Diam (Gaya Angkat Seimbang)", "#ffe6a1"),
    "hull_3": ("▼ Bahaya! Kecepatan Turun 1.5x", "#ffc6a9"),
    "hull_4": ("▼ Kritis! Kecepatan Turun 2.5x", "#ff9d9c"),
    "hull_5": ("▼ TERJUN BEBAS KE TANAH!", "#ff9999"),
    "flight_lost": ("GAME OVER", "#ff9d9c"),
    "flight_won": ("TIBA DI ISTANA AWAN!", "#ffdf86"),
    "pistol": ("PISTOL", "#ffdc75"),
    "rifle": ("AK-47", "#ffdc75"),
    "reserve": ("CADANGAN: ∞", "#c3e4ff"),
    "reload_state": ("MENGISI", "#e9f9ff"),
    "launch": ("LEPAS LANDAS!", "#fff0b4"),
    "seconds": ("DETIK", "#fff0b4"),
    "shop_title": ("TOKO PERBEKALAN", "#ffe08b", 72),
    "party_master": ("◆ PARTY MASTER", "#ffe08b"),
    "welcome_sign": ("FLY HIGH\nPILIH DERMAGA • BENTUK KRU • TERBANG!", "#ffedb3"),
    "palace_sign": ("DERMAGA AWAN 10.000 KM", "#ffe18c"),
    "storm_sign": ("DINDING BADAI\n▼ TURUN KE BAWAH AWAN", "#ffdc88"),
    "pod_start": ("E  •  MULAI PENERBANGAN", "#ffe18c"),
    "pod_footer": ("Master memulai • 1–3 pemain", "#c0d8fa"),
    "speed_up": ("▲", "#73ffa2"),
    "speed_down": ("▼", "#ff9b9d"),
    "speed_still": ("●", "#9ccfff"),
}
for index in range(6):
    LABELS[f"damage_{index}"] = (f"{index} / 5", "#8affae" if index == 0 else "#ffabab")
for key in ("V", "Z", "H", "SPACE", "R", "G", "T", "E", "Q", "F", "C", "B", "Y", "X", "P"):
    LABELS[f"key_{key.lower()}"] = (key, "#ffe58a")
for pod in "ABCDE":
    LABELS[f"pod_{pod.lower()}"] = (f"DERMAGA {pod}", "#ccecff")


def render(key, design, prefix="letter_"):
    text, color, *sizes = design if isinstance(design, tuple) else (design, "#f5fbff")
    font = ImageFont.truetype(str(FONT_DIR / "arialbd.ttf"), sizes[0] if sizes else 56)
    draw = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    style = dict(font=font, stroke_width=4, spacing=10, align="center")
    x, y, right, bottom = draw.multiline_textbbox((0, 0), text, **style)
    inset = 5
    image = Image.new("RGBA", (ceil(right - x) + 2 * inset, ceil(bottom - y) + 2 * inset))
    ImageDraw.Draw(image).multiline_text(
        (inset - x, inset - y), text, fill=color, stroke_fill="#071326", **style
    )
    image.thumbnail((672, 112), Image.Resampling.LANCZOS)
    image.save(OUT / f"{prefix}{key}.png", optimize=True)


if __name__ == "__main__":
    OUT.mkdir(exist_ok=True)
    for key, design in LABELS.items():
        render(key, design)

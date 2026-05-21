#!/usr/bin/env python

import yaml
from pathlib import Path
from PIL import Image, ImageOps

ROOT = Path.cwd()

RAW = ROOT / "assets/img/headshots/raw"
PROCESSED = ROOT / "assets/img/headshots/processed"
YAML = ROOT / "data/collaborators.yml"

SIZE = 500
QUALITY = 92

people = yaml.safe_load(YAML.read_text())

PROCESSED.mkdir(parents=True, exist_ok=True)

for person in people:
    slug = person["slug"]

    candidates = (
        list(RAW.glob(f"{slug}.jpg")) +
        list(RAW.glob(f"{slug}.jpeg")) +
        list(RAW.glob(f"{slug}.png")) +
        list(RAW.glob(f"{slug}.JPG")) +
        list(RAW.glob(f"{slug}.JPEG")) +
        list(RAW.glob(f"{slug}.PNG"))
    )

    if not candidates:
        print(f"MISSING: {slug}")
        continue

    src = candidates[0]    
    dst = PROCESSED / f"{slug}.jpg"

    crop_x = person.get("crop_x", 0.50)
    crop_y = person.get("crop_y", 0.25)

    img = Image.open(src)
    img = ImageOps.exif_transpose(img)
    img = img.convert("RGB")

    w, h = img.size
    side = min(w, h)

    max_left = w - side
    max_top = h - side

    left = int(max_left * crop_x)
    top = int(max_top * crop_y)

    img = img.crop((left, top, left + side, top + side))
    img = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    img.save(dst, quality=QUALITY)

    print(f"{slug}: crop_x={crop_x}, crop_y={crop_y}")

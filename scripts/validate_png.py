from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate a CUMCM PNG figure.")
    parser.add_argument("png", help="PNG file to inspect.")
    parser.add_argument("--min-width", type=int, default=1200)
    parser.add_argument("--min-height", type=int, default=700)
    args = parser.parse_args()

    path = Path(args.png).expanduser().resolve()
    errors: list[str] = []
    warnings: list[str] = []

    if not path.exists():
        errors.append("file does not exist")
        report = {"path": str(path), "status": "FAIL", "errors": errors}
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 1

    try:
        with Image.open(path) as image:
            if image.format != "PNG":
                errors.append(f"decoded format is {image.format}, not PNG")
            image.verify()
        with Image.open(path) as image:
            dpi = image.info.get("dpi")
            # Inspect the visible result on the paper's white background, not hidden RGB pixels.
            rgba = image.convert("RGBA")
            background = Image.new("RGBA", rgba.size, "white")
            image = Image.alpha_composite(background, rgba).convert("RGB")
            width, height = image.size
            if path.suffix.lower() != ".png":
                errors.append("file extension is not .png")
            if width < args.min_width:
                errors.append(f"width {width}px is below {args.min_width}px")
            if height < args.min_height:
                errors.append(f"height {height}px is below {args.min_height}px")
            if width / max(height, 1) > 4.5:
                warnings.append("extreme landscape aspect ratio may be unreadable in the paper")
            if height / max(width, 1) > 2.5:
                warnings.append("extreme portrait aspect ratio may be unreadable in the paper")

            white = Image.new("RGB", image.size, "white")
            content_box = ImageChops.difference(image, white).getbbox()
            if content_box is None:
                errors.append("image appears blank")
            else:
                left, top, right, bottom = content_box
                if left == 0 or top == 0 or right == width or bottom == height:
                    warnings.append("content touches an image boundary; inspect for clipping")

            if dpi and min(dpi) < 250:
                warnings.append(f"embedded DPI is {dpi}, below the preferred 300")
    except Exception as exc:
        errors.append(f"cannot decode PNG: {type(exc).__name__}: {exc}")
        width = height = 0

    report = {
        "path": str(path),
        "status": "PASS" if not errors else "FAIL",
        "width": width,
        "height": height,
        "errors": errors,
        "warnings": warnings,
        "scope": "File/render checks only; not a verification of data, units, or model claims.",
    }
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    raise SystemExit(main())

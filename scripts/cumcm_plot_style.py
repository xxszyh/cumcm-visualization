from __future__ import annotations

from pathlib import Path

import matplotlib as mpl
from matplotlib import font_manager


PALETTE = {
    "primary": "#2F5597",
    "secondary": "#70AD47",
    "accent": "#ED7D31",
    "neutral": "#7F8C8D",
    "light": "#D9E2F3",
    "dark": "#263238",
}

FONT_CANDIDATES = (
    "Microsoft YaHei",
    "SimHei",
    "Noto Sans CJK SC",
    "Source Han Sans SC",
    "Arial Unicode MS",
)


def choose_chinese_font() -> str:
    available = {font.name for font in font_manager.fontManager.ttflist}
    for candidate in FONT_CANDIDATES:
        if candidate in available:
            return candidate
    return "DejaVu Sans"


def configure_style() -> str:
    font = choose_chinese_font()
    mpl.rcParams.update(
        {
            "font.family": "sans-serif",
            "font.sans-serif": [font, "DejaVu Sans"],
            "axes.unicode_minus": False,
            "figure.facecolor": "white",
            "axes.facecolor": "white",
            "savefig.facecolor": "white",
            "axes.edgecolor": "#666666",
            "axes.labelcolor": "#333333",
            "text.color": "#333333",
            "xtick.color": "#444444",
            "ytick.color": "#444444",
            "axes.grid": True,
            "grid.color": "#D9D9D9",
            "grid.alpha": 0.45,
            "grid.linewidth": 0.7,
            "axes.spines.top": False,
            "axes.spines.right": False,
            "legend.frameon": False,
            "lines.linewidth": 2.0,
            "lines.markersize": 5.0,
        }
    )
    return font


def save_figure(fig, output: str | Path, *, dpi: int = 300) -> Path:
    path = Path(output).expanduser().resolve()
    if path.suffix.lower() != ".png":
        raise ValueError("The required primary output format is PNG.")
    path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(path, dpi=dpi, bbox_inches="tight", facecolor="white")
    return path


if __name__ == "__main__":
    print(choose_chinese_font())

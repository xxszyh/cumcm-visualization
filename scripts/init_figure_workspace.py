from __future__ import annotations

import argparse
import json
from pathlib import Path


def write_json_if_missing(path: Path, payload: dict) -> bool:
    if path.exists():
        return False
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return True


def main() -> int:
    parser = argparse.ArgumentParser(description="Initialize a CUMCM figure workspace.")
    parser.add_argument("root", nargs="?", default=".", help="Project root.")
    args = parser.parse_args()

    root = Path(args.root).expanduser().resolve()
    output = root / "paper_output"
    plan_dir = output / "plan"
    figures = output / "figures"
    source = figures / "source"
    code = output / "code" / "visualization"

    for directory in (plan_dir, figures, source, code):
        directory.mkdir(parents=True, exist_ok=True)

    created = []
    plan_path = plan_dir / "figure_plan.json"
    if write_json_if_missing(
        plan_path,
        {
            "version": 1,
            "figures": [],
            "required_fields": [
                "id",
                "question",
                "claim",
                "role",
                "backend",
                "png",
                "source",
                "inputs",
            ],
        },
    ):
        created.append(str(plan_path))

    index_path = output / "figure_index.json"
    if write_json_if_missing(index_path, {"version": 1, "figures": []}):
        created.append(str(index_path))

    print(
        json.dumps(
            {
                "root": str(root),
                "created_files": created,
                "preserved_existing_files": len(created) < 2,
            },
            ensure_ascii=False,
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

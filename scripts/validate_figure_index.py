"""Check figure artifacts and declared input hashes without running plotting or solvers."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def validate_index(index_path: Path, strict: bool = False) -> dict:
    errors: list[str] = []
    warnings: list[str] = []
    base = index_path.resolve().parent
    try:
        document = json.loads(index_path.read_text(encoding="utf-8-sig"))
    except (OSError, ValueError) as exc:
        return {"status": "FAIL", "errors": [str(exc)], "warnings": []}
    figures = document.get("figures") if isinstance(document, dict) else None
    if not isinstance(figures, list):
        return {"status": "FAIL", "errors": ["figures must be a list"], "warnings": []}

    def check_file(value: object, label: str, hash_required: bool = False) -> None:
        entry = {"path": value} if isinstance(value, str) else value
        if not isinstance(entry, dict) or not isinstance(entry.get("path"), str) or not entry["path"].strip():
            errors.append(f"{label}: expected a path string or object with path")
            return
        path = Path(entry["path"])
        if path.is_absolute():
            warnings.append(f"{label}: absolute path reduces portability")
        path = base / path
        if not path.is_file():
            errors.append(f"{label}: file missing: {entry['path']}")
            return
        expected = entry.get("sha256")
        if expected is None:
            (errors if hash_required else warnings).append(f"{label}: no sha256 recorded")
        elif not isinstance(expected, str) or len(expected) != 64 or any(c not in "0123456789abcdefABCDEF" for c in expected):
            errors.append(f"{label}: invalid sha256")
        else:
            digest = hashlib.sha256()
            try:
                with path.open("rb") as source:
                    for block in iter(lambda: source.read(1024 * 1024), b""):
                        digest.update(block)
            except OSError as exc:
                errors.append(f"{label}: cannot read file: {exc}")
                return
            if digest.hexdigest() != expected.lower():
                errors.append(f"{label}: sha256 mismatch; input/artifact changed")

    seen: set[str] = set()
    for position, figure in enumerate(figures):
        label = f"figure[{position}]"
        if not isinstance(figure, dict):
            errors.append(f"{label}: expected an object")
            continue
        identifier = figure.get("id")
        if not isinstance(identifier, str) or not identifier.strip():
            errors.append(f"{label}: id must be a nonempty string")
        elif identifier in seen:
            errors.append(f"{label}: duplicate id {identifier}")
        else:
            seen.add(identifier)
        for field in ("png", "source"):
            check_file(figure.get(field), f"{label}.{field}")
        inputs = figure.get("inputs")
        if not isinstance(inputs, list):
            errors.append(f"{label}: inputs must be a list")
        else:
            for item, value in enumerate(inputs):
                check_file(value, f"{label}.inputs[{item}]", hash_required=strict)
        kind = figure.get("data_kind")
        if kind not in ("observed", "computed", "schematic"):
            (errors if strict else warnings).append(f"{label}: declare data_kind as observed/computed/schematic")
        if strict and kind in ("observed", "computed") and isinstance(inputs, list) and not inputs:
            errors.append(f"{label}: quantitative figure needs input artifacts")
        if kind == "computed":
            if not isinstance(figure.get("run_id"), str) or not figure["run_id"].strip():
                (errors if strict else warnings).append(f"{label}: computed figure needs run_id")
            if figure.get("run_status") != "completed":
                (errors if strict else warnings).append(f"{label}: run_status is not completed")
        comparison = figure.get("comparison")
        if comparison is not None:
            fields = ("quantity", "unit", "time_basis", "position_basis")
            if not isinstance(comparison, dict) or any(not isinstance(comparison.get(k), str) or not comparison[k].strip() for k in fields):
                errors.append(f"{label}: comparison must declare quantity, unit, time_basis, position_basis")
    return {"status": "FAIL" if errors else "PASS", "figures": len(figures),
            "errors": errors, "warnings": warnings,
            "scope": "Checks declared provenance and files, not the truth of model claims or physical compatibility."}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("index", type=Path)
    parser.add_argument("--strict-provenance", action="store_true")
    args = parser.parse_args()
    report = validate_index(args.index, args.strict_provenance)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())

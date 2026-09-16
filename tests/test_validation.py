"""Exercise artifact failures using temporary files, without Visio or a solver."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from PIL import Image, ImageDraw

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))
from validate_figure_index import validate_index


class ArtifactTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def cli(self, script, *args):
        result = subprocess.run(
            [sys.executable, str(SCRIPTS / script), *map(str, args)],
            cwd=self.root, capture_output=True, text=True, check=False,
        )
        self.assertIn(result.returncode, (0, 1), result.stderr)
        report = json.loads(result.stdout)
        return result.returncode, report

    def png(self, mode="RGB", color="white", visible=True, format="PNG"):
        path = self.root / "figure.png"
        image = Image.new(mode, (1200, 700), color)
        if visible:
            ImageDraw.Draw(image).rectangle((100, 100, 300, 300), fill="black")
        image.save(path, format=format, dpi=(300, 300))
        return path

    def test_visible_png(self):
        code, report = self.cli("validate_png.py", self.png())
        self.assertEqual(code, 0, report)

    def test_disguised_jpeg(self):
        code, report = self.cli("validate_png.py", self.png(format="JPEG"))
        self.assertEqual(code, 1)
        self.assertTrue(any("not PNG" in item for item in report["errors"]))

    def test_invisible_rgb_is_blank(self):
        path = self.png("RGBA", (0, 0, 0, 0), visible=False)
        code, report = self.cli("validate_png.py", path)
        self.assertEqual(code, 1)
        self.assertIn("image appears blank", report["errors"])

    def test_transparent_background_with_visible_content(self):
        code, report = self.cli("validate_png.py", self.png("RGBA", (0, 0, 0, 0)))
        self.assertEqual(code, 0, report)

    def test_corrupt_png(self):
        path = self.root / "broken.png"
        path.write_bytes(b"not an image")
        code, report = self.cli("validate_png.py", path)
        self.assertEqual(code, 1)
        self.assertTrue(report["errors"])

    def manifest(self):
        self.png()
        (self.root / "plot.py").write_text("# plotting source\n")
        data = self.root / "data.csv"
        data.write_bytes(b"time,value\n0,1\n")
        return {"version": 1, "figures": [{
            "id": "fig1", "png": "figure.png", "source": "plot.py",
            "inputs": [{"path": "data.csv", "sha256": hashlib.sha256(data.read_bytes()).hexdigest()}],
            "data_kind": "computed", "run_id": "run-1", "run_status": "completed",
            "comparison": {"quantity": "temperature", "unit": "K",
                           "time_basis": "elapsed seconds", "position_basis": "center"},
        }]}

    def validate(self, document, strict=True):
        path = self.root / "figure_index.json"
        path.write_text(json.dumps(document), encoding="utf-8")
        return validate_index(path, strict)

    def test_valid_strict_relative_paths(self):
        self.assertEqual(self.validate(self.manifest())["status"], "PASS")

    def test_changed_input(self):
        document = self.manifest()
        (self.root / "data.csv").write_bytes(b"changed")
        self.assertEqual(self.validate(document)["status"], "FAIL")

    def test_duplicate_id(self):
        document = self.manifest()
        document["figures"].append(document["figures"][0].copy())
        self.assertEqual(self.validate(document)["status"], "FAIL")

    def test_missing_artifact(self):
        document = self.manifest()
        document["figures"][0]["source"] = "missing.py"
        self.assertEqual(self.validate(document)["status"], "FAIL")

    def test_incomplete_run(self):
        document = self.manifest()
        document["figures"][0]["run_status"] = "cancelled"
        self.assertEqual(self.validate(document)["status"], "FAIL")

    def test_legacy_index_warns_and_strict_rejects(self):
        document = self.manifest()
        figure = document["figures"][0]
        figure["inputs"] = ["data.csv"]
        for field in ("data_kind", "run_id", "run_status"):
            figure.pop(field)
        report = self.validate(document, strict=False)
        self.assertEqual(report["status"], "PASS")
        self.assertTrue(report["warnings"])
        self.assertEqual(self.validate(document)["status"], "FAIL")

    def test_observation_needs_no_solver_run(self):
        document = self.manifest()
        figure = document["figures"][0]
        figure["data_kind"] = "observed"
        figure.pop("run_id")
        figure.pop("run_status")
        self.assertEqual(self.validate(document)["status"], "PASS")

    def test_invalid_shapes(self):
        for document in ([], {}, {"figures": {}}, {"figures": [None]}):
            with self.subTest(document=document):
                self.assertEqual(self.validate(document)["status"], "FAIL")

    def test_incomplete_comparison(self):
        document = self.manifest()
        document["figures"][0]["comparison"].pop("unit")
        self.assertEqual(self.validate(document)["status"], "FAIL")

    def test_initializer_preserves_existing_files(self):
        self.cli("init_figure_workspace.py", self.root)
        path = self.root / "paper_output" / "figure_index.json"
        self.assertEqual(validate_index(path)["status"], "PASS")
        original = b'{"version":1,"figures":[],"user_note":"keep"}'
        path.write_bytes(original)
        self.cli("init_figure_workspace.py", self.root)
        self.assertEqual(path.read_bytes(), original)


if __name__ == "__main__":
    unittest.main()

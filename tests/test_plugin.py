"""Plugin setup/launch regression tests; no desktop, network, or user config access."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]


class PluginTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="writing tools # ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.project = self.root / "plugin checkout"
        (self.project / "bin").mkdir(parents=True)
        shutil.copy(REPO / "bin/tot-plugin", self.project / "bin/tot-plugin")
        shutil.copy(REPO / "config.example", self.project / "config.example")
        (self.project / "bin/translateonthego").write_text(
            '#!/bin/bash\nprintf "backend launched\\n"\n'
        )
        self.commands = self.root / "commands"
        self.commands.mkdir()
        for name in ("bash", "readlink", "dirname", "cat", "mkdir"):
            (self.commands / name).symlink_to(shutil.which(name))
        for name in ("curl", "jq", "wl-paste", "wl-copy", "notify-send", "python3", "fuzzel"):
            self.stub(name, "exit 0")
        self.env = {
            "HOME": str(self.root / "home"),
            "XDG_CONFIG_HOME": str(self.root / "custom config"),
            "PATH": str(self.commands),
            "LANG": "C.UTF-8",
        }
        self.config = self.root / "custom config/translateonthego/config"

    def stub(self, name, body):
        path = self.commands / name
        path.write_text("#!/bin/bash\n" + body + "\n")
        path.chmod(0o755)

    def run_plugin(self, *args):
        return subprocess.run(
            [str(self.commands / "bash"), str(self.project / "bin/tot-plugin"), *args],
            env=self.env, cwd=self.root, capture_output=True, text=True, check=False,
        )

    def test_setup_creates_private_config_without_integration(self):
        result = self.run_plugin("--setup")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.config.stat().st_mode & 0o777, 0o600)
        self.assertEqual(self.config.read_bytes(), (REPO / "config.example").read_bytes())
        self.assertFalse(Path(self.env["HOME"]).exists())
        self.assertEqual(list(self.config.parent.parent.iterdir()), [self.config.parent])

    def test_setup_preserves_existing_config_and_permissions(self):
        self.config.parent.mkdir(parents=True)
        self.config.write_text('PROVIDER="ollama"\n# keep my settings\n')
        self.config.chmod(0o640)
        before = self.config.read_bytes()
        for _ in range(2):
            self.assertEqual(self.run_plugin("--setup").returncode, 0)
        self.assertEqual(self.config.read_bytes(), before)
        self.assertEqual(self.config.stat().st_mode & 0o777, 0o640)

    def test_setup_rejects_dangling_symlink(self):
        self.config.parent.mkdir(parents=True)
        target = self.root / "must not create"
        self.config.symlink_to(target)
        self.assertNotEqual(self.run_plugin("--setup").returncode, 0)
        self.assertFalse(target.exists())
        self.assertTrue(self.config.is_symlink())

    def test_setup_rejects_directory_at_config_path(self):
        self.config.mkdir(parents=True)
        self.assertNotEqual(self.run_plugin("--setup").returncode, 0)
        self.assertTrue(self.config.is_dir())

    def test_setup_uses_home_when_xdg_is_unset(self):
        del self.env["XDG_CONFIG_HOME"]
        self.assertEqual(self.run_plugin("--setup").returncode, 0)
        self.assertTrue((Path(self.env["HOME"]) / ".config/translateonthego/config").is_file())

    def test_dependency_check_does_not_create_config_or_launch(self):
        result = self.run_plugin("--check")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("backend launched", result.stdout)
        self.assertFalse(self.config.parent.exists())

    def test_missing_dependency_fails_without_installing(self):
        (self.commands / "curl").unlink()
        result = self.run_plugin("--check")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("curl", result.stderr)
        self.assertFalse(self.config.exists())

    def test_missing_picker_and_gtk_report_actionable_errors(self):
        (self.commands / "fuzzel").unlink()
        result = self.run_plugin("--check")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("menu picker", result.stderr)
        self.stub("omarchy-menu-select", "exit 0")
        self.stub("python3", "exit 1")
        result = self.run_plugin("--check")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("python-gobject", result.stderr)

    def test_launch_requires_explicit_setup(self):
        result = self.run_plugin()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--setup", result.stderr)
        self.assertNotIn("backend launched", result.stdout)
        self.assertFalse(self.config.exists())

    def test_launch_uses_bundled_backend_from_arbitrary_directory(self):
        self.assertEqual(self.run_plugin("--setup").returncode, 0)
        result = self.run_plugin()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "backend launched\n")

    def test_bad_arguments_never_launch_or_write_config(self):
        for args in (("--unknown",), ("--setup", "extra"), ("--check", "extra"), ("",)):
            result = self.run_plugin(*args)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("backend launched", result.stdout)
            self.assertFalse(self.config.exists())

    def test_manifest_matches_widget_and_repository(self):
        manifest = json.loads((REPO / "manifest.json").read_text())
        self.assertEqual(manifest["schemaVersion"], 1)
        self.assertFalse(manifest["id"].startswith("omarchy."))
        self.assertEqual(manifest["kinds"], ["bar-widget"])
        widget = REPO / manifest["entryPoints"]["barWidget"]
        self.assertIn('moduleName: "' + manifest["id"] + '"', widget.read_text())
        for name in ("name", "version", "description", "author", "license"):
            self.assertTrue(manifest[name])
        self.assertEqual(manifest["barWidget"]["defaultSection"], "right")


if __name__ == "__main__":
    unittest.main()

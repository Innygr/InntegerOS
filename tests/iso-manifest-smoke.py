#!/usr/bin/env python3
"""Structural tests for the InntegerOS ISO preparation manifests."""
import json
import pathlib
import re
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]


class IsoManifestTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads((ROOT / "iso/manifest.json").read_text(encoding="utf-8"))

    def test_identity_and_initial_target(self):
        self.assertEqual(self.manifest["product"], "InntegerOS")
        self.assertEqual(self.manifest["edition"], "Plasma")
        self.assertEqual(self.manifest["architecture"], "amd64")
        self.assertEqual(self.manifest["image_type"], "live")

    def test_kubuntu_base_and_inherited_installer_are_explicit(self):
        base = self.manifest["base"]
        self.assertEqual(base["distribution"], "Kubuntu")
        self.assertEqual(base["release"], "26.04.1")
        self.assertEqual(base["status"], "selected")
        self.assertEqual(base["source_iso"], "kubuntu-26.04.1-desktop-amd64.iso")
        self.assertRegex(base["source_sha256"], r"^[0-9a-f]{64}$")
        self.assertEqual(self.manifest["build"]["tool"], "kubuntu-iso-remaster")
        self.assertIsNone(self.manifest["build"]["configuration"])
        self.assertEqual(self.manifest["build"]["status"], "not_started")
        self.assertEqual(self.manifest["installer"]["backend"], "inherit-kubuntu-live-installer")
        self.assertEqual(self.manifest["installer"]["status"], "pending_validation")
        self.assertTrue(self.manifest["installer"]["destructive_actions_require_confirmation"])

    def test_experimental_features_default_off_and_are_labelled(self):
        features = json.loads((ROOT / "config/features.json").read_text(encoding="utf-8"))
        self.assertFalse(features["default_experimental_enabled"])
        self.assertEqual(features["ui_badge"], "EXPERIMENTAL")
        self.assertTrue(features["enablement_requires_explicit_user_action"])
        self.assertGreater(len(features["features"]), 0)
        for feature in features["features"]:
            self.assertEqual(feature["status"], "experimental")
            self.assertFalse(feature["default_enabled"])

    def test_version_is_valid(self):
        version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        self.assertRegex(version, r"^\d+\.\d+(?:\.\d+)?$")

    def test_manifests_exist_and_have_valid_package_names(self):
        for relative in self.manifest["package_manifests"]:
            path = ROOT / "iso" / relative
            self.assertTrue(path.is_file(), relative)
            packages = []
            for raw in path.read_text(encoding="utf-8").splitlines():
                line = raw.strip()
                if not line or line.startswith("#"):
                    continue
                self.assertRegex(line, r"^[a-z0-9][a-z0-9+.-]*$")
                self.assertNotIn(line, packages, f"duplicate in {relative}")
                packages.append(line)
            self.assertTrue(packages, f"empty manifest: {relative}")

    def test_core_packages_are_in_their_expected_groups(self):
        base = (ROOT / "iso/manifests/base/common.txt").read_text(encoding="utf-8")
        plasma = (ROOT / "iso/manifests/profiles/plasma/packages.txt").read_text(encoding="utf-8")
        self.assertRegex(base, r"(?m)^network-manager$")
        self.assertRegex(plasma, r"(?m)^plasma-desktop$")


if __name__ == "__main__":
    unittest.main(verbosity=2)

#!/usr/bin/env python3
import argparse
import json
import shutil
import tempfile
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MOD_SRC = ROOT / "mod"
DIST = ROOT / "dist"
DEFAULT_OUT = DIST / "r2v_nutrition_overhaul.vmz"


def write_manifest(staging: Path, mod_id: str, version: str, name: str):
    manifest = {
        "mod_id": mod_id,
        "name": name,
        "version": version,
        "format": "vmz",
        "entrypoints": {
            "nutrition_system": "scripts/nutrition_system.gd"
        },
        "description": "Realistic nutrition/hydration/metabolism subsystem for testing"
    }
    (staging / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def copy_payload(staging: Path):
    if not MOD_SRC.exists():
        raise FileNotFoundError(f"Missing source directory: {MOD_SRC}")
    shutil.copytree(MOD_SRC, staging / "payload", dirs_exist_ok=True)


def build_vmz(output: Path, mod_id: str, version: str, name: str):
    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="vmz_build_") as td:
        staging = Path(td) / "vmz_root"
        staging.mkdir(parents=True, exist_ok=True)

        write_manifest(staging, mod_id, version, name)
        copy_payload(staging)

        tmp_zip = output.with_suffix(".zip")
        if tmp_zip.exists():
            tmp_zip.unlink()

        with zipfile.ZipFile(tmp_zip, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            for p in sorted(staging.rglob("*")):
                if p.is_file():
                    zf.write(p, p.relative_to(staging))

        if output.exists():
            output.unlink()
        tmp_zip.rename(output)


def main():
    ap = argparse.ArgumentParser(description="Build Road to Vostok nutrition mod .vmz package")
    ap.add_argument("--output", default=str(DEFAULT_OUT), help="Output .vmz file path")
    ap.add_argument("--mod-id", default="r2v.nutrition.overhaul", help="Unique mod id")
    ap.add_argument("--version", default="0.1.0", help="Mod version")
    ap.add_argument("--name", default="R2V Nutrition Overhaul", help="Display name")
    args = ap.parse_args()

    out = Path(args.output)
    if out.suffix.lower() != ".vmz":
        raise SystemExit("Output path must end with .vmz")

    build_vmz(out, args.mod_id, args.version, args.name)
    print(f"Built VMZ: {out}")


if __name__ == "__main__":
    main()

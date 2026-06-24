#!/usr/bin/env python3
"""
Automated publish pipeline for Arab City.

Steps:
  1. Lint all Luau source files (selene + luau-analyze)
  2. Build with Rojo (default.project.json → ArabCity.rbxlx)
  3. Post-process rbxlx (fix_rbxlx.py: namespaces, Meta, SharedStrings, Terrain)
  4. Validate XML structure
  5. Strip XML declaration if present (Roblox API rejects it)
  6. Upload to Roblox Open Cloud API

Requires:
  - Environment variable ROBLOX_PUBLISH_API_KEY  (or --key-file <path>)
  - rojo on PATH
  - selene on PATH (Luau linter)
  - luau-analyze on PATH (optional, skipped if missing)

Usage:
  python3 publish.py                        # lint + build + publish
  python3 publish.py --lint-only            # lint only, no publish
  python3 publish.py --skip-lint            # build + publish without linting
  python3 publish.py --key-file key.txt     # read API key from file
  python3 publish.py --dry-run              # lint + build + validate, skip upload
"""
import os
import sys
import glob
import subprocess
import xml.etree.ElementTree as ET
import urllib.request
import json
import argparse

# --- Configuration ---
UNIVERSE_ID = "10384297644"
PLACE_ID = "92391090144988"
PROJECT_FILE = "default.project.json"
RBXLX_RAW = "ArabCity_raw.rbxlx"
RBXLX_FINAL = "ArabCity.rbxlx"
SRC_DIR = "src"
API_URL = (
    f"https://apis.roblox.com/universes/v1/{UNIVERSE_ID}"
    f"/places/{PLACE_ID}/versions?versionType=Published"
)


def run(cmd, capture=True):
    """Run a shell command and return (returncode, stdout, stderr)."""
    result = subprocess.run(cmd, capture_output=capture, text=True)
    return result.returncode, result.stdout, result.stderr


def lint():
    """Run selene + luau-analyze on all Luau source files."""
    print("\n=== STEP 1: Linting Luau sources ===")

    lua_files = sorted(glob.glob(os.path.join(SRC_DIR, "**", "*.lua"), recursive=True))
    if not lua_files:
        sys.exit("ERROR: No .lua files found in src/")

    print(f"Found {len(lua_files)} Lua files")

    errors = 0

    # --- selene ---
    selene_path = subprocess.run(
        ["which", "selene"], capture_output=True, text=True
    ).stdout.strip()

    if selene_path:
        print(f"\nRunning selene ({selene_path})...")
        code, out, err = run(["selene", "--display-style=quiet"] + lua_files)
        lines = (out + err).strip().split("\n") if (out + err).strip() else []
        actual_errors = [l for l in lines if ": error[" in l]
        warnings = [l for l in lines if ": warning[" in l]
        if actual_errors:
            print(f"  selene: {len(actual_errors)} ERROR(s):")
            for l in actual_errors:
                print(f"    {l}")
            errors += len(actual_errors)
        else:
            print(f"  selene: 0 errors, {len(warnings)} warnings (non-blocking)")
    else:
        print("WARNING: selene not found on PATH, skipping")

    # --- luau-analyze ---
    luau_path = subprocess.run(
        ["which", "luau-analyze"], capture_output=True, text=True
    ).stdout.strip()

    if luau_path:
        print(f"\nRunning luau-analyze ({luau_path})...")
        code, out, err = run(["luau-analyze"] + lua_files)
        lines = (out + err).strip().split("\n") if (out + err).strip() else []
        actual_errors = [
            l for l in lines
            if l.strip()
            and ": Error" in l
            and "Unknown global" not in l
            and "Unknown type" not in l
            and "is not a valid member" not in l
        ]
        warnings = [l for l in lines if l.strip() and ": Warning" in l]
        if actual_errors:
            print(f"  luau-analyze: {len(actual_errors)} ERROR(s):")
            for l in actual_errors[:20]:
                print(f"    {l}")
            errors += len(actual_errors)
        else:
            print(f"  luau-analyze: 0 errors, {len(warnings)} warnings (non-blocking)")
    else:
        print("WARNING: luau-analyze not found on PATH, skipping")

    if errors > 0:
        print(f"\nLINT FAILED: {errors} error(s) found. Fix them before publishing.")
        sys.exit(1)

    print("\nLint passed! All files are clean.")
    return True


def build():
    """Run Rojo to build the rbxlx from default.project.json."""
    print("\n=== STEP 2: Building with Rojo ===")

    rojo_path = subprocess.run(
        ["which", "rojo"], capture_output=True, text=True
    ).stdout.strip()

    if not rojo_path:
        sys.exit("ERROR: rojo not found on PATH. Install it: cargo install rojo")

    print(f"  Using rojo: {rojo_path}")
    print(f"  Project: {PROJECT_FILE}")
    print(f"  Output:  {RBXLX_RAW}")

    code, out, err = run(["rojo", "build", PROJECT_FILE, "-o", RBXLX_RAW])
    if code != 0:
        print(f"BUILD FAILED:\n{out}\n{err}")
        sys.exit(1)
    print(out.strip() if out.strip() else "  Build complete.")


def postprocess():
    """Run fix_rbxlx.py to add missing elements for Roblox Studio compatibility."""
    print("\n=== STEP 3: Post-processing rbxlx ===")

    if not os.path.exists("fix_rbxlx.py"):
        print("WARNING: fix_rbxlx.py not found, copying raw file directly")
        import shutil
        shutil.copy(RBXLX_RAW, RBXLX_FINAL)
        return

    code, out, err = run([sys.executable, "fix_rbxlx.py", RBXLX_RAW, RBXLX_FINAL])
    if code != 0:
        print(f"POST-PROCESS FAILED:\n{out}\n{err}")
        sys.exit(1)
    print(out.strip())


def validate_xml():
    """Validate the rbxlx file is well-formed XML."""
    print("\n=== STEP 4: Validating XML ===")
    try:
        ET.parse(RBXLX_FINAL)
        print(f"  {RBXLX_FINAL} is valid XML")
    except ET.ParseError as e:
        print(f"XML VALIDATION FAILED: {e}")
        sys.exit(1)


def strip_xml_declaration():
    """Remove <?xml ...?> declaration if present (Roblox API rejects it)."""
    print("\n=== STEP 5: Stripping XML declaration ===")
    with open(RBXLX_FINAL, "r", encoding="utf-8") as f:
        content = f.read()

    if content.startswith("<?xml"):
        newline_idx = content.index("\n")
        content = content[newline_idx + 1:]
        with open(RBXLX_FINAL, "w", encoding="utf-8") as f:
            f.write(content)
        print("  Removed XML declaration")
    else:
        print("  No XML declaration found (already clean)")


def publish(api_key):
    """Upload rbxlx to Roblox Open Cloud API."""
    print("\n=== STEP 6: Publishing to Roblox ===")

    file_size = os.path.getsize(RBXLX_FINAL)
    print(f"  Uploading {RBXLX_FINAL} ({file_size:,} bytes)...")
    print(f"  Universe: {UNIVERSE_ID} | Place: {PLACE_ID}")

    with open(RBXLX_FINAL, "rb") as f:
        data = f.read()

    req = urllib.request.Request(
        API_URL,
        data=data,
        method="POST",
        headers={
            "x-api-key": api_key,
            "Content-Type": "application/octet-stream",
            "Content-Length": str(len(data)),
        },
    )

    try:
        with urllib.request.urlopen(req) as resp:
            body = json.loads(resp.read().decode())
            version = body.get("versionNumber", "?")
            print(f"\n  Published successfully! Version: {version}")
            return version
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        print(f"\n  PUBLISH FAILED (HTTP {e.code}): {error_body}")
        sys.exit(1)


def get_api_key(args):
    """Resolve API key from --key-file, env var, or common locations."""
    # 1. --key-file argument
    if args.key_file:
        with open(args.key_file, "r") as f:
            key = f.read().strip()
        if key:
            print(f"  API key loaded from: {args.key_file}")
            return key

    # 2. Environment variable
    key = os.environ.get("ROBLOX_PUBLISH_API_KEY")
    if key:
        print("  API key loaded from: ROBLOX_PUBLISH_API_KEY env var")
        return key

    # 3. Common file locations
    for path in ["api_key.txt", os.path.expanduser("~/Downloads/api_key.txt")]:
        if os.path.exists(path):
            with open(path, "r") as f:
                key = f.read().strip()
            if key:
                print(f"  API key loaded from: {path}")
                return key

    sys.exit(
        "ERROR: No API key found.\n"
        "  Set ROBLOX_PUBLISH_API_KEY env var, or use --key-file <path>,\n"
        "  or place api_key.txt in the project root."
    )


def main():
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    parser = argparse.ArgumentParser(description="Arab City publish pipeline")
    parser.add_argument("--lint-only", action="store_true", help="Lint only, no build/publish")
    parser.add_argument("--skip-lint", action="store_true", help="Skip linting")
    parser.add_argument("--dry-run", action="store_true", help="Lint + build + validate, skip upload")
    parser.add_argument("--key-file", type=str, help="Path to API key file")
    args = parser.parse_args()

    print("=" * 50)
    print("  Arab City - Automated Publish Pipeline")
    print("=" * 50)

    # Step 1: Lint
    if not args.skip_lint:
        lint()

    if args.lint_only:
        print("\n--lint-only: stopping after lint.")
        return

    # Step 2: Build with Rojo
    build()

    # Step 3: Post-process
    postprocess()

    # Step 4: Validate XML
    validate_xml()

    # Step 5: Strip XML declaration
    strip_xml_declaration()

    if args.dry_run:
        print("\n--dry-run: skipping upload.")
        print("=== Pipeline complete (dry run) ===")
        return

    # Step 6: Publish
    api_key = get_api_key(args)
    version = publish(api_key)

    print(f"\n{'=' * 50}")
    print(f"  Pipeline complete! Version {version} is live.")
    print(f"  https://www.roblox.com/games/{PLACE_ID}/Arab-City")
    print(f"{'=' * 50}")


if __name__ == "__main__":
    main()

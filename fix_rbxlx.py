#!/usr/bin/env python3
"""
Post-process a Rojo-built .rbxlx file to add missing elements
that Roblox Studio expects for publishing:
1. XML namespaces on <roblox> tag
2. <Meta name="ExplicitAutoJoints">true</Meta>
3. <SharedStrings></SharedStrings> before </roblox>
4. Verify Terrain exists in Workspace
"""

import sys
import re


def fix_rbxlx(input_path: str, output_path: str) -> None:
    with open(input_path, "r", encoding="utf-8") as f:
        content = f.read()

    # 1. Fix <roblox> opening tag - add XML namespaces
    old_tag = '<roblox version="4">'
    new_tag = '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="4">'
    if old_tag in content:
        content = content.replace(old_tag, new_tag, 1)
        print("[OK] Added XML namespaces to <roblox> tag")
    else:
        print("[SKIP] <roblox> tag already has namespaces or not found")

    # 2. Add <Meta> tags right after <roblox ...>
    if "<Meta " not in content:
        # Insert Meta tag right after the <roblox ...> opening tag
        roblox_tag_end = content.find(">", content.find("<roblox")) + 1
        meta_block = '\n\t<Meta name="ExplicitAutoJoints">true</Meta>'
        content = content[:roblox_tag_end] + meta_block + content[roblox_tag_end:]
        print("[OK] Added ExplicitAutoJoints Meta tag")
    else:
        print("[SKIP] Meta tags already present")

    # 3. Add <SharedStrings> section before </roblox>
    if "<SharedStrings" not in content:
        content = content.replace("</roblox>", "\t<SharedStrings>\n\t</SharedStrings>\n</roblox>")
        print("[OK] Added SharedStrings section")
    else:
        print("[SKIP] SharedStrings already present")

    # 4. Verify Terrain exists
    if 'class="Terrain"' in content:
        print("[OK] Terrain found in file")
    else:
        print("[WARN] Terrain NOT found - this may cause publish issues")

    # 5. Verify Workspace exists
    if 'class="Workspace"' in content:
        print("[OK] Workspace found in file")
    else:
        print("[WARN] Workspace NOT found!")

    # 6. Count top-level services
    top_level_classes = re.findall(r'<Item class="(\w+)" referent="\d+">', content)
    print(f"[INFO] Top-level items: {len(top_level_classes)}")
    for cls in top_level_classes:
        print(f"  - {cls}")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(content)

    print(f"\n[DONE] Fixed file written to: {output_path}")
    print(f"[SIZE] {len(content)} bytes")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: fix_rbxlx.py <input.rbxlx> <output.rbxlx>")
        sys.exit(1)
    fix_rbxlx(sys.argv[1], sys.argv[2])

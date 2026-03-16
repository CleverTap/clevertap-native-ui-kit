#!/usr/bin/env python3
"""Patch nav-overlay in 10 gallery test configs: replace HORIZONTAL with BOX + offsets."""

import json
import sys
from pathlib import Path

CONFIGS = [
    "test-157-gallery-box-freeflow-indicators-navbtns.json",
    "test-159-gallery-box-freeflow-navbtns-only.json",
    "test-161-gallery-box-freeflow-tall-images.json",
    "test-162-gallery-box-freeflow-video-items.json",
    "test-165-gallery-box-grid2col-indicators-navbtns.json",
    "test-167-gallery-box-grid2col-navbtns-only.json",
    "test-170-gallery-box-grid3col-navbtns.json",
    "test-171-gallery-box-grid2col-video.json",
    "test-173-gallery-box-snapping-indicators-navbtns.json",
    "test-175-gallery-box-snapping-navbtns-only.json",
]

NEW_NAV_OVERLAY = {
    "type": "container",
    "id": "nav-overlay",
    "containerType": "box",
    "layout": {
        "width": {"value": 100, "unit": "percent"},
        "height": {"special": "match_parent"}
    },
    "children": [
        {
            "type": "element",
            "id": "nav-prev",
            "elementType": "button",
            "bindings": {"text": "\u2039"},
            "layout": {
                "width": {"value": 11, "unit": "percent"},
                "height": {"value": 44, "unit": "dp"},
                "offset": {"x": 2, "y": 38, "unit": "percent"}
            },
            "style": {
                "backgroundColor": "#CC000000",
                "textColor": "#FFFFFFFF",
                "fontSize": 22,
                "borderRadius": 22
            }
        },
        {
            "type": "element",
            "id": "nav-next",
            "elementType": "button",
            "bindings": {"text": "\u203a"},
            "layout": {
                "width": {"value": 11, "unit": "percent"},
                "height": {"value": 44, "unit": "dp"},
                "offset": {"x": 87, "y": 38, "unit": "percent"}
            },
            "style": {
                "backgroundColor": "#CC000000",
                "textColor": "#FFFFFFFF",
                "fontSize": 22,
                "borderRadius": 22
            }
        }
    ]
}


def find_and_replace_nav_overlay(node):
    """Recursively find nav-overlay node and replace it. Returns (new_node, patched)."""
    if not isinstance(node, dict):
        return node, False

    # Check children list first
    children = node.get("children")
    if children:
        new_children = []
        patched = False
        for child in children:
            if isinstance(child, dict) and child.get("id") == "nav-overlay":
                new_children.append(NEW_NAV_OVERLAY)
                patched = True
            else:
                new_child, child_patched = find_and_replace_nav_overlay(child)
                new_children.append(new_child)
                if child_patched:
                    patched = True
        if patched:
            node = dict(node)
            node["children"] = new_children
        return node, patched

    # Recurse into all dict values (handles top-level keys like "root")
    patched = False
    new_node = {}
    for k, v in node.items():
        new_v, child_patched = find_and_replace_nav_overlay(v)
        new_node[k] = new_v
        if child_patched:
            patched = True
    return new_node, patched


def patch_file(path: Path) -> bool:
    data = json.loads(path.read_text(encoding="utf-8"))
    new_data, patched = find_and_replace_nav_overlay(data)
    if not patched:
        print(f"  WARNING: nav-overlay not found in {path.name}", file=sys.stderr)
        return False
    path.write_text(json.dumps(new_data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"  Patched: {path.name}")
    return True


def main():
    script_dir = Path(__file__).parent
    configs_dir = script_dir.parent / "test-configs"

    if not configs_dir.exists():
        print(f"ERROR: test-configs dir not found at {configs_dir}", file=sys.stderr)
        sys.exit(1)

    ok = 0
    for name in CONFIGS:
        p = configs_dir / name
        if not p.exists():
            print(f"  MISSING: {name}", file=sys.stderr)
            continue
        if patch_file(p):
            ok += 1

    print(f"\nDone: {ok}/{len(CONFIGS)} files patched.")


if __name__ == "__main__":
    main()

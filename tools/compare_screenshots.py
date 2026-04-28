#!/usr/bin/env python3
"""
compare_screenshots.py — Cross-platform screenshot comparison tool for Native Display SDK.

Compares iOS and Android screenshots to detect UI discrepancies.
Generates a self-contained HTML report with diff highlights.

Usage:
    python3 tools/compare_screenshots.py \
        --android <path>   \
        --ios <path>       \
        --output <path>    \
        --threshold 5.0    \
        --resize 400x700
"""

import argparse
import base64
import io
import os
import sys
from datetime import datetime
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("ERROR: Pillow is required. Install with: pip3 install Pillow", file=sys.stderr)
    sys.exit(2)


# ---------------------------------------------------------------------------
# Image helpers
# ---------------------------------------------------------------------------

def load_image(path: Path) -> Image.Image | None:
    """Load an image from disk, returning None on error."""
    try:
        img = Image.open(path)
        img.load()  # force decode now so errors surface here
        return img
    except Exception as exc:
        print(f"  WARNING: could not load {path.name}: {exc}", file=sys.stderr)
        return None


def resize_to_canonical(img: Image.Image, width: int, height: int) -> Image.Image:
    """Resize image to canonical comparison dimensions using LANCZOS."""
    if img.size == (width, height):
        return img.convert("RGBA")
    return img.resize((width, height), Image.LANCZOS).convert("RGBA")


def image_to_base64(img: Image.Image, fmt: str = "PNG") -> str:
    """Encode a PIL image as a base64 data URI string."""
    buf = io.BytesIO()
    img.save(buf, format=fmt)
    data = base64.b64encode(buf.getvalue()).decode("ascii")
    mime = "image/png" if fmt.upper() == "PNG" else "image/jpeg"
    return f"data:{mime};base64,{data}"


def thumbnail(img: Image.Image, width: int = 150) -> Image.Image:
    """Return a width-constrained thumbnail (preserves aspect ratio)."""
    aspect = img.height / img.width
    new_height = int(width * aspect)
    return img.resize((width, new_height), Image.LANCZOS)


# ---------------------------------------------------------------------------
# Diff computation (pure Python + Pillow, no numpy)
# ---------------------------------------------------------------------------

def compute_diff(
    android_img: Image.Image,
    ios_img: Image.Image,
    canonical_w: int,
    canonical_h: int,
    tolerance: int = 10,
) -> tuple[float, int, float, Image.Image]:
    """
    Compare two images at canonical resolution.

    Returns:
        diff_pct   — percentage of pixels with max-channel-diff > tolerance
        max_diff   — highest single-pixel max-channel-diff
        mean_diff  — average max-channel-diff across all pixels
        diff_img   — diff highlight image (iOS base + red overlay on changed pixels)
    """
    a = resize_to_canonical(android_img, canonical_w, canonical_h)
    b = resize_to_canonical(ios_img, canonical_w, canonical_h)

    # Pixel data as flat lists of (R, G, B, A) tuples
    a_pixels = list(a.getdata())
    b_pixels = list(b.getdata())

    total = canonical_w * canonical_h
    flagged_count = 0
    max_diff = 0
    total_diff_sum = 0

    # Build mask: True where pixel is "different"
    diff_mask = []
    for (ar, ag, ab, _), (br, bg, bb, _) in zip(a_pixels, b_pixels):
        d = max(abs(ar - br), abs(ag - bg), abs(ab - bb))
        total_diff_sum += d
        if d > max_diff:
            max_diff = d
        if d > tolerance:
            flagged_count += 1
            diff_mask.append(True)
        else:
            diff_mask.append(False)

    diff_pct = flagged_count / total * 100
    mean_diff = total_diff_sum / total

    # Build diff highlight image: iOS base + semi-transparent red overlay
    diff_img = b.copy()
    overlay = Image.new("RGBA", (canonical_w, canonical_h), (0, 0, 0, 0))
    red_pixel = (255, 0, 0, 180)
    overlay_pixels = [(red_pixel if flagged else (0, 0, 0, 0)) for flagged in diff_mask]
    overlay.putdata(overlay_pixels)
    diff_img = Image.alpha_composite(diff_img, overlay)

    return diff_pct, max_diff, mean_diff, diff_img


# ---------------------------------------------------------------------------
# File discovery and name matching
# ---------------------------------------------------------------------------

def collect_android_screenshots(android_dir: Path) -> dict[str, Path]:
    """
    Collect Android screenshots keyed by config base name (without .json).

    Android naming: test-001-vertical-simple.json.png
    Key becomes:    test-001-vertical-simple
    """
    result: dict[str, Path] = {}
    for p in sorted(android_dir.glob("*.png")):
        name = p.stem  # strips final .png  → test-001-vertical-simple.json
        if name.endswith(".json"):
            name = name[:-5]  # strip trailing .json
        result[name] = p
    return result


def collect_ios_screenshots(ios_dir: Path) -> dict[str, Path]:
    """
    Collect iOS screenshots keyed by config base name.

    iOS naming: test-001-vertical-simple.png
    Key becomes: test-001-vertical-simple
    """
    result: dict[str, Path] = {}
    for p in sorted(ios_dir.glob("*.png")):
        result[p.stem] = p
    return result


# ---------------------------------------------------------------------------
# HTML report generation
# ---------------------------------------------------------------------------

_CSS = """
* { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
       background: #f5f5f7; color: #1d1d1f; padding: 24px; }
h1 { font-size: 1.6rem; font-weight: 700; margin-bottom: 4px; }
.subtitle { color: #6e6e73; font-size: 0.9rem; margin-bottom: 24px; }

.summary-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
                gap: 12px; margin-bottom: 24px; }
.stat-card { background: #fff; border-radius: 10px; padding: 14px 18px;
             box-shadow: 0 1px 3px rgba(0,0,0,.1); }
.stat-card .value { font-size: 2rem; font-weight: 700; }
.stat-card .label { font-size: 0.75rem; color: #6e6e73; text-transform: uppercase;
                    letter-spacing: .05em; margin-top: 2px; }
.stat-card.red .value  { color: #ff3b30; }
.stat-card.green .value { color: #34c759; }
.stat-card.orange .value { color: #ff9500; }

.filter-bar { margin-bottom: 16px; display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
.filter-bar button { padding: 6px 14px; border: 1px solid #d1d1d6; border-radius: 20px;
                     background: #fff; cursor: pointer; font-size: 0.85rem; transition: all .15s; }
.filter-bar button.active { background: #0071e3; color: #fff; border-color: #0071e3; }
.filter-bar .search { padding: 6px 12px; border: 1px solid #d1d1d6; border-radius: 20px;
                      font-size: 0.85rem; outline: none; width: 220px; }

table { width: 100%; border-collapse: separate; border-spacing: 0 6px; }
thead th { text-align: left; font-size: 0.75rem; text-transform: uppercase;
           letter-spacing: .05em; color: #6e6e73; padding: 0 12px 4px; }
tbody tr { background: #fff; box-shadow: 0 1px 3px rgba(0,0,0,.07); }
tbody tr td { padding: 10px 12px; vertical-align: middle; }
tbody tr td:first-child { border-radius: 10px 0 0 10px; }
tbody tr td:last-child  { border-radius: 0 10px 10px 0; }
tbody tr.hidden { display: none; }

.config-name { font-size: 0.85rem; font-weight: 600; word-break: break-all; max-width: 200px; }
.thumb img { border-radius: 6px; max-width: 150px; height: auto;
             display: block; border: 1px solid #e5e5ea; }
.thumb .label { font-size: 0.65rem; color: #6e6e73; text-align: center; margin-top: 3px; }

.diff-pct { font-size: 1.1rem; font-weight: 700; }
.diff-pct.green  { color: #34c759; }
.diff-pct.yellow { color: #ff9500; }
.diff-pct.red    { color: #ff3b30; }
.subdiff { font-size: 0.75rem; color: #6e6e73; }

.badge { display: inline-block; padding: 3px 8px; border-radius: 6px;
         font-size: 0.75rem; font-weight: 600; }
.badge.pass     { background: #d1fae5; color: #065f46; }
.badge.flagged  { background: #fee2e2; color: #991b1b; }

.section-title { font-size: 1.1rem; font-weight: 600; margin: 28px 0 12px; }
.unmatched-list { background: #fff; border-radius: 10px; padding: 16px 20px;
                  box-shadow: 0 1px 3px rgba(0,0,0,.07); }
.unmatched-list h3 { font-size: 0.85rem; text-transform: uppercase; color: #6e6e73;
                     letter-spacing: .05em; margin-bottom: 8px; }
.unmatched-list ul { list-style: none; }
.unmatched-list li { font-size: 0.85rem; padding: 3px 0; border-bottom: 1px solid #f0f0f2; }
.unmatched-list li:last-child { border-bottom: none; }

.missing-thumb { width: 150px; height: 100px; background: #f0f0f2; border-radius: 6px;
                 display: flex; align-items: center; justify-content: center;
                 font-size: 0.75rem; color: #aeaeb2; }
"""

_JS = """
(function() {
    var rows = document.querySelectorAll('tbody tr[data-status]');
    var searchInput = document.getElementById('search');

    function applyFilters() {
        var filter = document.querySelector('.filter-bar button.active').dataset.filter;
        var query = searchInput ? searchInput.value.toLowerCase() : '';
        rows.forEach(function(row) {
            var statusOk = (filter === 'all') ||
                           (filter === 'flagged' && row.dataset.status === 'flagged') ||
                           (filter === 'passed'  && row.dataset.status === 'pass');
            var nameOk = !query || row.dataset.name.indexOf(query) !== -1;
            row.classList.toggle('hidden', !(statusOk && nameOk));
        });
    }

    document.querySelectorAll('.filter-bar button[data-filter]').forEach(function(btn) {
        btn.addEventListener('click', function() {
            document.querySelectorAll('.filter-bar button[data-filter]').forEach(function(b) {
                b.classList.remove('active');
            });
            btn.classList.add('active');
            applyFilters();
        });
    });

    if (searchInput) {
        searchInput.addEventListener('input', applyFilters);
    }
})();
"""


def _diff_color_class(diff_pct: float, threshold: float) -> str:
    if diff_pct < threshold:
        return "green"
    if diff_pct < threshold * 2:
        return "yellow"
    return "red"


def generate_html_report(
    results: list[dict],
    unmatched_android: list[str],
    unmatched_ios: list[str],
    threshold: float,
    canonical_w: int,
    canonical_h: int,
    output_dir: Path,
) -> Path:
    """Generate a self-contained HTML report and return its path."""

    # Sort by diff_pct descending
    results_sorted = sorted(results, key=lambda r: r["diff_pct"], reverse=True)

    total = len(results_sorted)
    flagged = sum(1 for r in results_sorted if r["flagged"])
    passed = total - flagged
    avg_diff = (sum(r["diff_pct"] for r in results_sorted) / total) if total else 0.0

    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # --- Build rows HTML ---
    rows_html = []
    for r in results_sorted:
        status = "flagged" if r["flagged"] else "pass"
        badge_cls = "flagged" if r["flagged"] else "pass"
        badge_text = "FLAGGED" if r["flagged"] else "PASS"
        diff_cls = _diff_color_class(r["diff_pct"], threshold)

        android_thumb_html = (
            f'<img src="{r["android_b64"]}" alt="android">'
            if r.get("android_b64")
            else '<div class="missing-thumb">no screenshot</div>'
        )
        ios_thumb_html = (
            f'<img src="{r["ios_b64"]}" alt="ios">'
            if r.get("ios_b64")
            else '<div class="missing-thumb">no screenshot</div>'
        )
        diff_thumb_html = (
            f'<img src="{r["diff_b64"]}" alt="diff">'
            if r.get("diff_b64")
            else '<div class="missing-thumb">no diff</div>'
        )

        rows_html.append(f"""
        <tr data-status="{status}" data-name="{r['name']}">
            <td><div class="config-name">{r['name']}</div></td>
            <td class="thumb">{android_thumb_html}<div class="label">Android</div></td>
            <td class="thumb">{ios_thumb_html}<div class="label">iOS</div></td>
            <td class="thumb">{diff_thumb_html}<div class="label">Diff</div></td>
            <td>
                <div class="diff-pct {diff_cls}">{r['diff_pct']:.2f}%</div>
                <div class="subdiff">max: {r['max_diff']} &nbsp; mean: {r['mean_diff']:.1f}</div>
            </td>
            <td><span class="badge {badge_cls}">{badge_text}</span></td>
        </tr>""")

    rows_str = "\n".join(rows_html)

    # --- Unmatched section ---
    def _list_items(names: list[str]) -> str:
        if not names:
            return "<li><em>none</em></li>"
        return "".join(f"<li>{n}</li>" for n in sorted(names))

    unmatched_html = f"""
    <div class="section-title">Unmatched Files</div>
    <div class="unmatched-list">
        <h3>Android only ({len(unmatched_android)})</h3>
        <ul>{_list_items(unmatched_android)}</ul>
        <br>
        <h3>iOS only ({len(unmatched_ios)})</h3>
        <ul>{_list_items(unmatched_ios)}</ul>
    </div>
    """

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Native Display — Screenshot Comparison Report</title>
<style>
{_CSS}
</style>
</head>
<body>

<h1>Native Display — Screenshot Comparison Report</h1>
<div class="subtitle">Generated {timestamp} &nbsp;·&nbsp; Canonical size: {canonical_w}×{canonical_h} &nbsp;·&nbsp; Threshold: {threshold:.1f}%</div>

<div class="summary-grid">
    <div class="stat-card">
        <div class="value">{total}</div>
        <div class="label">Total Pairs</div>
    </div>
    <div class="stat-card green">
        <div class="value">{passed}</div>
        <div class="label">Passed</div>
    </div>
    <div class="stat-card red">
        <div class="value">{flagged}</div>
        <div class="label">Flagged</div>
    </div>
    <div class="stat-card orange">
        <div class="value">{len(unmatched_android) + len(unmatched_ios)}</div>
        <div class="label">Unmatched</div>
    </div>
    <div class="stat-card">
        <div class="value">{avg_diff:.2f}%</div>
        <div class="label">Avg Diff</div>
    </div>
</div>

<div class="filter-bar">
    <button class="active" data-filter="all">All ({total})</button>
    <button data-filter="flagged">Flagged ({flagged})</button>
    <button data-filter="passed">Passed ({passed})</button>
    <input class="search" id="search" type="text" placeholder="Search config name…">
</div>

<table>
    <thead>
        <tr>
            <th>Config</th>
            <th>Android</th>
            <th>iOS</th>
            <th>Diff Highlight</th>
            <th>Diff %</th>
            <th>Status</th>
        </tr>
    </thead>
    <tbody>
{rows_str}
    </tbody>
</table>

{unmatched_html}

<script>
{_JS}
</script>
</body>
</html>"""

    report_path = output_dir / "report.html"
    report_path.write_text(html, encoding="utf-8")
    return report_path


# ---------------------------------------------------------------------------
# Main comparison driver
# ---------------------------------------------------------------------------

def run_comparison(
    android_dir: Path,
    ios_dir: Path,
    output_dir: Path,
    threshold: float,
    canonical_w: int,
    canonical_h: int,
) -> int:
    """
    Run the full comparison pipeline.

    Returns exit code: 0 = all passed, 1 = some flagged.
    """
    output_dir.mkdir(parents=True, exist_ok=True)

    android_files = collect_android_screenshots(android_dir)
    ios_files = collect_ios_screenshots(ios_dir)

    all_keys = sorted(set(android_files) | set(ios_files))
    matched_keys = sorted(set(android_files) & set(ios_files))
    unmatched_android = sorted(set(android_files) - set(ios_files))
    unmatched_ios = sorted(set(ios_files) - set(android_files))

    print(f"\nAndroid screenshots found : {len(android_files)}")
    print(f"iOS screenshots found     : {len(ios_files)}")
    print(f"Matched pairs             : {len(matched_keys)}")
    print(f"Android only              : {len(unmatched_android)}")
    print(f"iOS only                  : {len(unmatched_ios)}")
    print(f"Canonical size            : {canonical_w}x{canonical_h}")
    print(f"Threshold                 : {threshold:.1f}%")
    print()

    results: list[dict] = []
    any_flagged = False

    for name in matched_keys:
        android_path = android_files[name]
        ios_path = ios_files[name]

        android_img = load_image(android_path)
        ios_img = load_image(ios_path)

        if android_img is None or ios_img is None:
            print(f"  SKIP  {name}  (image load error)")
            continue

        diff_pct, max_diff, mean_diff, diff_img = compute_diff(
            android_img, ios_img, canonical_w, canonical_h
        )

        flagged = diff_pct >= threshold
        if flagged:
            any_flagged = True

        status_str = "FLAGGED" if flagged else "PASS"
        print(f"  Comparing {name}... diff={diff_pct:.2f}%  {status_str}")

        # Save diff PNG to output dir
        diff_filename = f"{name}_diff.png"
        diff_img.save(output_dir / diff_filename, "PNG")

        # Build thumbnails for HTML (keep RGBA for consistency)
        android_resized = resize_to_canonical(android_img, canonical_w, canonical_h)
        ios_resized = resize_to_canonical(ios_img, canonical_w, canonical_h)

        android_thumb = thumbnail(android_resized)
        ios_thumb = thumbnail(ios_resized)
        diff_thumb = thumbnail(diff_img)

        results.append({
            "name": name,
            "diff_pct": diff_pct,
            "max_diff": max_diff,
            "mean_diff": mean_diff,
            "flagged": flagged,
            "android_b64": image_to_base64(android_thumb),
            "ios_b64": image_to_base64(ios_thumb),
            "diff_b64": image_to_base64(diff_thumb),
        })

    # --- Summary ---
    flagged_count = sum(1 for r in results if r["flagged"])
    passed_count = len(results) - flagged_count
    avg_diff = sum(r["diff_pct"] for r in results) / len(results) if results else 0.0

    print()
    print("=" * 52)
    print(f"  Total pairs compared : {len(results)}")
    print(f"  Passed               : {passed_count}")
    print(f"  Flagged (>={threshold:.1f}%)     : {flagged_count}")
    print(f"  Average diff         : {avg_diff:.2f}%")
    if unmatched_android:
        print(f"  Android only         : {', '.join(unmatched_android)}")
    if unmatched_ios:
        print(f"  iOS only             : {', '.join(unmatched_ios)}")
    print("=" * 52)

    # --- HTML report ---
    report_path = generate_html_report(
        results=results,
        unmatched_android=unmatched_android,
        unmatched_ios=unmatched_ios,
        threshold=threshold,
        canonical_w=canonical_w,
        canonical_h=canonical_h,
        output_dir=output_dir,
    )
    print(f"\nReport written to: {report_path}")

    return 1 if any_flagged else 0


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Compare iOS and Android screenshots for the Native Display SDK.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--android",
        required=True,
        metavar="PATH",
        help="Directory containing Android Roborazzi screenshots",
    )
    parser.add_argument(
        "--ios",
        required=True,
        metavar="PATH",
        help="Directory containing iOS simulator screenshots",
    )
    parser.add_argument(
        "--output",
        default="tools/comparison_report",
        metavar="PATH",
        help="Output directory for HTML report and diff images (default: tools/comparison_report/)",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=5.0,
        metavar="PERCENT",
        help="Diff %% threshold to flag as discrepancy (default: 5.0)",
    )
    parser.add_argument(
        "--resize",
        default="400x700",
        metavar="WxH",
        help="Canonical comparison size in pixels (default: 400x700)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    # Parse canonical size
    try:
        canonical_w, canonical_h = (int(x) for x in args.resize.lower().split("x"))
    except (ValueError, AttributeError):
        print(f"ERROR: invalid --resize value '{args.resize}'. Expected format: WIDTHxHEIGHT (e.g. 400x700)", file=sys.stderr)
        sys.exit(2)

    android_dir = Path(os.path.expanduser(args.android)).resolve()
    ios_dir = Path(os.path.expanduser(args.ios)).resolve()
    output_dir = Path(os.path.expanduser(args.output)).resolve()

    if not android_dir.is_dir():
        print(f"ERROR: Android directory not found: {android_dir}", file=sys.stderr)
        sys.exit(2)
    if not ios_dir.is_dir():
        print(f"ERROR: iOS directory not found: {ios_dir}", file=sys.stderr)
        sys.exit(2)

    exit_code = run_comparison(
        android_dir=android_dir,
        ios_dir=ios_dir,
        output_dir=output_dir,
        threshold=args.threshold,
        canonical_w=canonical_w,
        canonical_h=canonical_h,
    )
    sys.exit(exit_code)


if __name__ == "__main__":
    main()

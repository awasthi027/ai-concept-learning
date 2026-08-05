#!/usr/bin/env python3
"""Summarise per-suite and combined code coverage from xccov JSON reports.

Given the JSON emitted by `xcrun xccov view --report --json <bundle>.xcresult`
for the unit-test, UI-test, and combined test runs, this prints a human-readable
report (unit %, UI %, combined %, plus a per-file table from the combined run)
and writes a machine-readable summary JSON.

It measures coverage of the **app target** only (production code), never the
test bundles. See `.claude/rules/test-coverage-standards.md` for the contract.
"""

import argparse
import json
import sys


def load_report(path):
    """Read an xccov --json report; return {} if the path is missing/empty."""
    if not path:
        return {}
    try:
        with open(path, encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError):
        return {}


def app_target(report, app_name):
    """Pick the app target from an xccov report by exact name, else *.app."""
    targets = report.get("targets", []) if report else []
    for target in targets:
        if target.get("name") == app_name:
            return target
    for target in targets:
        if str(target.get("name", "")).endswith(".app"):
            return target
    return None


def suite_summary(report, app_name):
    """Return coverage totals for the app target, or None if unavailable."""
    target = app_target(report, app_name)
    if target is None:
        return None
    covered = int(target.get("coveredLines", 0))
    executable = int(target.get("executableLines", 0))
    pct = (covered / executable * 100.0) if executable else 0.0
    return {
        "target": target.get("name"),
        "coveredLines": covered,
        "executableLines": executable,
        "lineCoverage": round(pct, 2),
    }


def file_rows(report, app_name):
    """Per-file coverage rows for the app target (used for the combined table)."""
    target = app_target(report, app_name)
    if target is None:
        return []
    rows = []
    for source in target.get("files", []):
        executable = int(source.get("executableLines", 0))
        covered = int(source.get("coveredLines", 0))
        pct = (covered / executable * 100.0) if executable else 0.0
        rows.append({
            "name": source.get("name", "?"),
            "coveredLines": covered,
            "executableLines": executable,
            "lineCoverage": round(pct, 2),
        })
    rows.sort(key=lambda row: row["lineCoverage"])
    return rows


def fmt(summary):
    """Format a suite summary as a percentage string, or 'N/A'."""
    if summary is None:
        return "N/A (no tests run)"
    return f"{summary['lineCoverage']:.2f}%  " \
           f"({summary['coveredLines']}/{summary['executableLines']} lines)"


def print_report(app_name, unit, ui, combined, combined_rows):
    """Emit the human-readable coverage report to stdout."""
    print("")
    print("=" * 68)
    print(f"  New-test code coverage — app target: {app_name}")
    print("=" * 68)
    print(f"  Unit tests      : {fmt(unit)}")
    print(f"  UI tests        : {fmt(ui)}")
    print(f"  Combined        : {fmt(combined)}")
    print("-" * 68)
    if combined_rows:
        print("  Per-file (combined run), lowest coverage first:")
        for row in combined_rows:
            print(f"    {row['lineCoverage']:6.2f}%  "
                  f"{row['coveredLines']:>4}/{row['executableLines']:<4}  "
                  f"{row['name']}")
    print("=" * 68)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", required=True, help="app target name, e.g. foo.app")
    parser.add_argument("--unit", help="xccov JSON for the unit-test run")
    parser.add_argument("--ui", help="xccov JSON for the UI-test run")
    parser.add_argument("--combined", help="xccov JSON for the combined run")
    parser.add_argument("--out", help="path to write the summary JSON")
    parser.add_argument("--min-combined", type=float, default=None,
                        help="fail (exit 3) if combined coverage is below this")
    args = parser.parse_args()

    unit = suite_summary(load_report(args.unit), args.app)
    ui = suite_summary(load_report(args.ui), args.app)
    combined = suite_summary(load_report(args.combined), args.app)
    combined_rows = file_rows(load_report(args.combined), args.app)

    print_report(args.app, unit, ui, combined, combined_rows)

    summary = {
        "appTarget": args.app,
        "unit": unit,
        "ui": ui,
        "combined": combined,
        "combinedFiles": combined_rows,
    }
    if args.out:
        with open(args.out, "w", encoding="utf-8") as handle:
            json.dump(summary, handle, indent=2)

    if args.min_combined is not None and combined is not None:
        if combined["lineCoverage"] < args.min_combined:
            print(f"  ✗ combined coverage {combined['lineCoverage']:.2f}% "
                  f"< threshold {args.min_combined:.2f}%", file=sys.stderr)
            return 3
    return 0


if __name__ == "__main__":
    sys.exit(main())

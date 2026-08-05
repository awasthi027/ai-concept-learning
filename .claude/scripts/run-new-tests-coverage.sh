#!/usr/bin/env bash
#
# run-new-tests-coverage.sh — run ONLY the given (newly written) unit and UI
# tests, and report code coverage of the app target **restricted to the
# production lines added or modified on this branch** (old, unmodified code is
# never counted), separately for the unit suite, the UI suite, and the two
# combined.
#
# The caller (the `test-coverage-runner` agent / `test-coverage-report` skill)
# is responsible for discovering which tests are new from the git diff and
# passing them here as `-only-testing` identifiers. This script only measures.
#
# Identifiers are "Target/TypeName/testName", comma-separated, e.g.:
#   --unit "ai-concept-learningTests/HomeViewModelTests/validateValues"
#   --ui   "ai-concept-learningUITests/HomeViewUITests/testListingAndNavigationflow"
#
# Usage:
#   .claude/scripts/run-new-tests-coverage.sh \
#       --unit "<ids>" --ui "<ids>" \
#       [--sim-name "iPhone 16"] [--os "18.5"] \
#       [--dest "<full xcodebuild destination>"] \
#       [--out build/coverage] [--min-combined 60] [--base main] [--keep]
#
# Diff scope: coverage is scored ONLY on production lines added/modified versus
# --base (default "main"), matched by APP_GLOB (default
# "ai-concept-learning/**/*.swift"; test dirs are excluded). Old, unmodified
# code is never counted.
#
# Simulator: choose the device with --sim-name and the iOS version with --os
# (the caller should ask the user for these). --dest overrides both with a raw
# destination string. If none are given, the first available iPhone is used and
# a warning is printed.
#
# Live status: every progress line is flushed immediately and also appended to
# "<out>/progress.log". To watch a long run, launch it in the background and
# poll that file (the agent/skill does this).
#
# Cleanup: ALL generated files (result bundles, DerivedData, logs, JSON) live
# under <out> (default build/coverage). On success they are deleted; pass
# --keep to retain them. On failure they are kept so the run can be debugged.
#
# Env overrides: UNIT_SCHEME, UI_SCHEME, COMBINED_SCHEME, APP_TARGET, BASE_REF,
#                APP_GLOB, DESTINATION, SIM_NAME, OS_VERSION.
set -euo pipefail

UNIT_SCHEME="${UNIT_SCHEME:-ai-concept-learningTests}"
UI_SCHEME="${UI_SCHEME:-ai-concept-learningUITests}"
COMBINED_SCHEME="${COMBINED_SCHEME:-ai-concept-learning}"
APP_TARGET="${APP_TARGET:-ai-concept-learning.app}"
# Coverage is scored ONLY on production lines added/modified versus this base
# ref, matched by this pathspec (test dirs are intentionally excluded).
BASE_REF="${BASE_REF:-main}"
APP_GLOB="${APP_GLOB:-:(glob)ai-concept-learning/**/*.swift}"
DESTINATION="${DESTINATION:-}"
SIM_NAME="${SIM_NAME:-}"
OS_VERSION="${OS_VERSION:-}"
OUT_DIR="build/coverage"
UNIT_IDS=""
UI_IDS=""
MIN_COMBINED=""
KEEP=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORTER="$SCRIPT_DIR/diff_coverage.py"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

usage() {
    grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
}

while [ $# -gt 0 ]; do
    case "$1" in
        --unit) UNIT_IDS="$2"; shift 2 ;;
        --ui) UI_IDS="$2"; shift 2 ;;
        --dest) DESTINATION="$2"; shift 2 ;;
        --sim-name) SIM_NAME="$2"; shift 2 ;;
        --os) OS_VERSION="$2"; shift 2 ;;
        --base) BASE_REF="$2"; shift 2 ;;
        --out) OUT_DIR="$2"; shift 2 ;;
        --min-combined) MIN_COMBINED="$2"; shift 2 ;;
        --keep) KEEP=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done

if [ -z "$UNIT_IDS" ] && [ -z "$UI_IDS" ]; then
    echo "No new unit or UI tests were provided — nothing to run."
    echo "Pass --unit and/or --ui with comma-separated test identifiers."
    exit 0
fi

# Resolve the xcodebuild destination. Precedence:
#   1. --dest (a full destination string) wins outright.
#   2. --sim-name (with optional --os) composes a name/OS destination.
#   3. Otherwise auto-pick the first available iPhone simulator (with a warning
#      to stderr — the caller is expected to ask the user for the device).
pick_destination() {
    if [ -n "$DESTINATION" ]; then
        echo "$DESTINATION"
        return
    fi
    if [ -n "$SIM_NAME" ]; then
        if [ -n "$OS_VERSION" ]; then
            echo "platform=iOS Simulator,name=$SIM_NAME,OS=$OS_VERSION"
        else
            echo "platform=iOS Simulator,name=$SIM_NAME"
        fi
        return
    fi
    local name
    name="$(xcrun simctl list devices available 2>/dev/null \
        | grep -Eo 'iPhone [0-9][0-9A-Za-z ]*' | head -1 | xargs || true)"
    [ -n "$name" ] || name="iPhone 16"
    echo "run-new-tests-coverage: no --sim-name/--os given; auto-picked" \
         "'$name'. Pass --sim-name and --os to choose the device/iOS." >&2
    echo "platform=iOS Simulator,name=$name"
}

only_testing_flags() {
    local ids="$1" id
    IFS=',' read -ra parts <<< "$ids"
    for id in "${parts[@]}"; do
        id="$(echo "$id" | xargs)"
        if [ -n "$id" ]; then
            printf ' -only-testing:%s' "$id"
        fi
    done
}

count_ids() {
    local ids="$1"
    if [ -z "$ids" ]; then
        echo 0
        return
    fi
    printf '%s\n' "$ids" | tr ',' '\n' | grep -c '[^[:space:]]' || true
}

# Filter xcodebuild output down to live progress: which test is running now and
# how far along the whole job is. Handles XCTest ("Test Case '-[...]'") and
# Swift Testing ("Test name() started/passed"). Non-test/build noise is dropped,
# with an occasional "still building" heartbeat so long builds aren't silent.
stream_progress() {
    local label="$1" n="$2" pass_index="$3" total_passes="$4"
    local gbase="$5" gtotal="$6"
    awk -v label="$label" -v n="$n" -v pi="$pass_index" -v tp="$total_passes" \
        -v gbase="$gbase" -v gtotal="$gtotal" '
    function overall(done,   pct) {
        pct = (gtotal > 0) ? int(done * 100 / gtotal) : 0
        return done "/" gtotal " (" pct "%)"
    }
    function emit(line) { printf("%s\n", line); fflush() }
    BEGIN { k = 0; built = 0; comp = 0 }
    /Test Case .* started/ {
        name = $0
        sub(/.*-\[/, "", name); sub(/\].*/, "", name)
        k++
        emit(sprintf("   ▶ [%s %d/%d · overall %s] %s",
                     label, k, n, overall(gbase + k - 1), name))
        next
    }
    /Test .*\(\) started/ && $0 !~ /Test run/ && $0 !~ /Test Suite/ {
        name = $0
        sub(/.*Test /, "", name); sub(/\(\).*/, "", name)
        k++
        emit(sprintf("   ▶ [%s %d/%d · overall %s] %s()",
                     label, k, n, overall(gbase + k - 1), name))
        next
    }
    /Test Case .* passed/ || (/Test .*\(\) passed/ && $0 !~ /Test run/) {
        emit(sprintf("      ✓ passed  (overall %s)", overall(gbase + k)))
        next
    }
    /Test Case .* failed/ || (/Test .*\(\) failed/ && $0 !~ /Test run/) {
        emit(sprintf("      ✗ FAILED  (overall %s)", overall(gbase + k)))
        next
    }
    /Compil|CompileSwift|Ld |PhaseScriptExecution|Building/ {
        if (built == 0) {
            emit(sprintf("   · building %s…", label))
            built = 1
        }
        comp++
        if (comp % 120 == 0) {
            emit(sprintf("   · still building %s…", label))
        }
        next
    }
    { next }
    '
}

run_suite() {
    local label="$1" scheme="$2" result="$3" ids="$4" n="$5"
    rm -rf "$result"
    PASS_INDEX=$((PASS_INDEX + 1))
    echo ""
    echo "▶ Pass $PASS_INDEX/$TOTAL_PASSES — $label suite ($n test(s), scheme: $scheme)" \
        | tee -a "$OUT_DIR/progress.log"
    local log="$OUT_DIR/$label.log"
    set +e
    # Each pass gets its OWN derived-data dir (still under $OUT_DIR, so cleanup
    # removes everything). Sharing one DerivedData across sequential
    # `xcodebuild test` runs corrupts the coverage-archive staging area — xccov
    # then fails with "Metadata.plist couldn't be opened" on a later pass
    # (typically the last/heaviest one, e.g. the combined multi-testable run).
    # shellcheck disable=SC2046
    xcodebuild test \
        -scheme "$scheme" \
        -destination "$dest" \
        -enableCodeCoverage YES \
        -resultBundlePath "$result" \
        -derivedDataPath "$OUT_DIR/DerivedData-$label" \
        $(only_testing_flags "$ids") 2>&1 \
        | tee "$log" \
        | stream_progress "$label" "$n" "$PASS_INDEX" "$TOTAL_PASSES" \
                          "$COMPLETED" "$GRAND_TOTAL" \
        | tee -a "$OUT_DIR/progress.log"
    local rc=${PIPESTATUS[0]}
    set -e
    if [ "$rc" -ne 0 ]; then
        echo "" >&2
        echo "✗ Pass $PASS_INDEX/$TOTAL_PASSES ($label) failed —" \
             "xcodebuild exit $rc. Last lines of $log:" >&2
        tail -n 30 "$log" >&2
        exit 1
    fi
    COMPLETED=$((COMPLETED + n))
    local pct=$(( GRAND_TOTAL > 0 ? COMPLETED * 100 / GRAND_TOTAL : 0 ))
    echo "✓ Pass $PASS_INDEX/$TOTAL_PASSES ($label) complete —" \
         "job $pct% done ($COMPLETED/$GRAND_TOTAL test-runs)" \
        | tee -a "$OUT_DIR/progress.log"
}

# Extract app-target coverage JSON from a result bundle. xccov occasionally
# fails with "Failed to load coverage archive ... Metadata.plist ... no such
# file" if the underlying .xccovarchive staging data is missing/corrupt (seen
# when passes share one DerivedData — fixed by giving each pass its own, see
# run_suite). Surface that plainly instead of letting the raw NSError through.
extract_coverage_json() {
    local label="$1" bundle="$2" out_json="$3"
    if ! xcrun xccov view --report --json "$bundle" > "$out_json" 2>"$OUT_DIR/$label-xccov.err"; then
        echo "" >&2
        echo "✗ Failed to read coverage from $bundle:" >&2
        cat "$OUT_DIR/$label-xccov.err" >&2
        echo "" >&2
        echo "This is usually a corrupt/missing coverage-archive staging area" \
             "for the $label pass, not a problem with the tests themselves." \
             "Re-running the script (each pass now gets an isolated" \
             "-derivedDataPath) usually resolves it." >&2
        exit 1
    fi
}

dest="$(pick_destination)"
mkdir -p "$OUT_DIR"

# Combined ids = unit + ui, run together for one combined-coverage number.
combined_ids="$UNIT_IDS"
if [ -n "$UI_IDS" ]; then
    if [ -n "$combined_ids" ]; then
        combined_ids="$combined_ids,$UI_IDS"
    else
        combined_ids="$UI_IDS"
    fi
fi

unit_n="$(count_ids "$UNIT_IDS")"
ui_n="$(count_ids "$UI_IDS")"
combined_n="$(count_ids "$combined_ids")"

# One pass per non-empty suite, plus the always-run combined pass. Grand total
# is test-runs across all passes (used for the overall % progress).
TOTAL_PASSES=1
GRAND_TOTAL="$combined_n"
if [ "$unit_n" -gt 0 ]; then
    TOTAL_PASSES=$((TOTAL_PASSES + 1))
    GRAND_TOTAL=$((GRAND_TOTAL + unit_n))
fi
if [ "$ui_n" -gt 0 ]; then
    TOTAL_PASSES=$((TOTAL_PASSES + 1))
    GRAND_TOTAL=$((GRAND_TOTAL + ui_n))
fi
PASS_INDEX=0
COMPLETED=0

echo "Job plan: $TOTAL_PASSES pass(es), $GRAND_TOTAL test-run(s) total."
echo "  Destination : $dest"
echo "  Unit tests  : ${unit_n} → ${UNIT_IDS:-（none）}"
echo "  UI tests    : ${ui_n} → ${UI_IDS:-（none）}"

unit_json=""
ui_json=""
combined_json=""

if [ -n "$UNIT_IDS" ]; then
    run_suite "unit" "$UNIT_SCHEME" "$OUT_DIR/unit.xcresult" "$UNIT_IDS" "$unit_n"
    unit_json="$OUT_DIR/unit.json"
    extract_coverage_json "unit" "$OUT_DIR/unit.xcresult" "$unit_json"
fi

if [ -n "$UI_IDS" ]; then
    run_suite "ui" "$UI_SCHEME" "$OUT_DIR/ui.xcresult" "$UI_IDS" "$ui_n"
    ui_json="$OUT_DIR/ui.json"
    extract_coverage_json "ui" "$OUT_DIR/ui.xcresult" "$ui_json"
fi

run_suite "combined" "$COMBINED_SCHEME" "$OUT_DIR/combined.xcresult" \
    "$combined_ids" "$combined_n"
combined_json="$OUT_DIR/combined.json"
extract_coverage_json "combined" "$OUT_DIR/combined.xcresult" "$combined_json"

echo ""
echo "✓ All $TOTAL_PASSES pass(es) complete — computing coverage report…"

report_args=(--app "$APP_TARGET" --base "$BASE_REF" --repo-root "$REPO_ROOT"
    --app-glob "$APP_GLOB" --combined-bundle "$OUT_DIR/combined.xcresult"
    --out "$OUT_DIR/summary.json")
[ -n "$UNIT_IDS" ] && report_args+=(--unit-bundle "$OUT_DIR/unit.xcresult")
[ -n "$UI_IDS" ] && report_args+=(--ui-bundle "$OUT_DIR/ui.xcresult")
[ -n "$MIN_COMBINED" ] && report_args+=(--min-combined "$MIN_COMBINED")

set +e
python3 "$REPORTER" "${report_args[@]}"
report_rc=$?
set -e

# Clean up every file this run generated (result bundles, DerivedData, logs,
# JSON) now that the report is printed. Keep them only with --keep.
if [ "$KEEP" -eq 1 ]; then
    echo ""
    echo "Artifacts kept in $OUT_DIR (summary: $OUT_DIR/summary.json)."
else
    rm -rf "$OUT_DIR"
    echo ""
    echo "Cleaned up test artifacts ($OUT_DIR). Re-run with --keep to retain them."
fi

exit "$report_rc"

---
name: run-unit-tests
description: Run the unit tests, the UI tests, and both combined on a simulator with code coverage enabled, then print a clean report of how much of the app code is covered by the unit suite, by the UI suite, and by the two combined. Use when asked to run tests and report code coverage.
tools: ["bash"]
---

You run the app's tests on an iOS simulator **with code coverage enabled** and
report the app-code line coverage three ways: **unit only**, **UI only**, and
**combined**. Stream progress, then print one clean summary.

## Defaults

- Project: `ai-concept-learning.xcodeproj`
- Schemes: unit `ai-concept-learningTests`, UI `ai-concept-learningUITests`,
  combined `ai-concept-learning`
- App target (coverage is reported for this): `ai-concept-learning.app`
- Simulator: `iPhone 17`, iOS `26.2` (override only if the user names another)
- Output dir: `build/coverage` (create it; safe to delete after)

## How to work

Run each pass with the `bash` tool in **async mode** (build + simulator takes
minutes) and **show live progress the whole time — never leave the terminal
blank.** Do not use `-quiet`; instead tee full output to a log and stream a
readable progress line for each phase (Building → Testing → per-test → coverage).

### 0. Live progress rules

- Tee every pass to a log so nothing is lost, e.g.
  `... | tee build/coverage/<suite>.log`.
- While a pass runs, poll the log with `read_bash` (or
  `tail -n 15 build/coverage/<suite>.log`) and relay short updates: which suite
  is running, the current phase, and each test as it passes/fails.
- Print an overall progress marker per suite so the user sees position, e.g.
  `[1/3] Unit ▓▓▓░░░░░░░  building…` → `[1/3] Unit ▓▓▓▓▓▓▓░░░  testing 5/8`.
- Surface these `xcodebuild` markers as they appear:
  `Test Suite … started`, `Test Case '-[… testX]' passed (0.123 seconds)`,
  `** TEST SUCCEEDED **` / `** TEST FAILED **`.
- If `xcbeautify` or `xcpretty` is installed, pipe through it for cleaner
  progress (`... | tee raw.log | xcbeautify`); otherwise stream the raw log.

### 1. Run the three passes, each into its own result bundle

```bash
DEST='platform=iOS Simulator,name=iPhone 17,OS=26.2'
mkdir -p build/coverage

# Unit  (stream progress via the log; no -quiet)
xcodebuild test -project ai-concept-learning.xcodeproj \
  -scheme ai-concept-learningTests -destination "$DEST" \
  -enableCodeCoverage YES -resultBundlePath build/coverage/unit.xcresult \
  2>&1 | tee build/coverage/unit.log

# UI
xcodebuild test -project ai-concept-learning.xcodeproj \
  -scheme ai-concept-learningUITests -destination "$DEST" \
  -enableCodeCoverage YES -resultBundlePath build/coverage/ui.xcresult \
  2>&1 | tee build/coverage/ui.log

# Combined (unit + UI together)
xcodebuild test -project ai-concept-learning.xcodeproj \
  -scheme ai-concept-learning -destination "$DEST" \
  -enableCodeCoverage YES -resultBundlePath build/coverage/combined.xcresult \
  2>&1 | tee build/coverage/combined.log
```

Skip a pass only if the user asked for just one suite. After each pass, print a
one-line result (`[1/3] Unit ✓ 8 passed in 42s`) before starting the next.

### 2. Extract app-target coverage from each result bundle

For each bundle, read the app target's line coverage:

```bash
for s in unit ui combined; do
  pct=$(xcrun xccov view --report --json "build/coverage/$s.xcresult" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); \
t=[x for x in d['targets'] if x['name']=='ai-concept-learning.app']; \
print(f\"{(t[0]['lineCoverage']*100):.2f}\" if t else 'N/A')")
  echo "$s: $pct%"
done
```

If the app target name differs, list targets with
`xcrun xccov view --report --json <bundle> | python3 -c "import sys,json;
print([t['name'] for t in json.load(sys.stdin)['targets']])"` and use the app
one.

### 3. Print the report

```
Code coverage (target: ai-concept-learning.app)
  +------------+---------------+
  | Suite      | Line coverage |
  +------------+---------------+
  | Unit tests |    <pct>%     |
  | UI tests   |    <pct>%     |
  | Combined   |    <pct>%     |
  +------------+---------------+
```

Optionally add the lowest-covered files from the combined report:

```bash
xcrun xccov view --report "build/coverage/combined.xcresult" | head -40
```

## Principles

- Report the **actual** percentages from `xccov`; never fabricate. Use `N/A` for
  a suite you did not run.
- **Combined** comes from its own combined run — never present it as
  unit + UI added together.
- On a build/test failure, stop and print the failing test identifier and the
  error verbatim; a failed run has no valid coverage.
- If the simulator is invalid (`Unable to find a device …`), list devices with
  `xcrun simctl list devices available | grep -Ei "iPhone"` and retry.
- Only run `xcodebuild test`, `xcrun xccov`, and `xcrun simctl list`. Do not
  modify source. Clean up `build/coverage` when done (it is git-ignored).

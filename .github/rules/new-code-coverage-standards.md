# New-code coverage standards

Source of truth for the `run-unit-tests` agent and the `new-code-coverage`
skill. Defines **what** to measure and **which** tests to run. The skill defines
**how** (exact commands); the agent orchestrates.

## 1. Goal

Measure how well the **newly written / modified production code** on this branch
is covered by tests — never the whole target, never old/unmodified code.

## 2. Scope: only added/modified production lines

- Coverage is scored on **only the lines added or modified versus the base ref**
  (default `main`), in production sources matched by
  `:(glob)ai-concept-learning/**/*.swift`. Files under `*Tests/` / `*UITests/`
  are excluded from the scored code.
- A changed line counts only if it is **executable** (has an `xccov` hit count);
  non-executable lines (`*`) are ignored.

## 3. Test selection: only tests that cover the change

- Run **only** the unit and UI tests that exercise the changed code — **not** the
  full suite. Tests may be **existing or newly written**.
- Discover them from the changed **symbols** (types/functions/properties) and the
  screen/feature the changed view belongs to. When unsure whether a test covers
  the change, **include it** — the coverage numbers confirm it.
- Identifiers are `Target/TypeName/testName` (single test) or `Target/TypeName`
  (whole class); **both are valid**. Resolve method names by reading the file —
  **never run a throwaway "probe" test** to discover them.
- `ai-concept-learningTests/` → **unit**; `ai-concept-learningUITests/` → **UI**.

## 4. Suites and the overall number

- Run at most **two passes**: unit and UI (skip a suite with no selected tests).
- **Do not run a separate "combined" scheme/pass.**
- **Overall (new)** = the **union** of unit and UI coverage over the changed
  lines: a changed line is covered if **any** selected test hit it. Never present
  it as unit + UI numerically added.

## 5. Reporting

- Report the **actual** numbers from `xccov`; never fabricate. Use `N/A` for a
  suite that was not run, or when the branch changed no executable lines.
- Always report three figures — **Unit**, **UI**, **Overall (new)** — plus the
  lowest-covered changed files.
- Always report the **total time taken** (wall-clock for the whole job) on the
  last line.
- On any build/test failure, stop and report the failing identifier and the
  compiler/test error **verbatim**; a failed run has no valid coverage.

## 6. Environment & safety

- Defaults: project `ai-concept-learning.xcodeproj`; schemes
  `ai-concept-learningTests` (unit) and `ai-concept-learningUITests` (UI); app
  target `ai-concept-learning.app`; simulator **iPhone 17 / iOS 26.2**; base
  `main`; output dir `build/coverage`.
- **Stay inside the repo working directory for all files.** Never write to
  `/tmp` or any path outside the repo — the CLI sandbox denies it and a
  sub-agent cannot prompt for permission. All logs/result bundles live under
  `build/coverage/`.
- Only run `git`, `grep`, `xcodebuild test`, `xcrun xccov`, `xcrun simctl list`,
  and `python3`. Never modify source.

## 7. Cleanup

- **After** printing the report, delete `build/coverage` (and `build/` if empty)
  — it is git-ignored. Keep the artifacts only when the run **failed**, so the
  failure can be inspected.

## 8. Not a gate

This is a **report-only** measurement. It is manual (run on request); it is not
a git-push hook or a CI blocker.

---
name: test-coverage-report
description: Run only the newly written unit tests and UI tests on this iOS app and report app-code coverage separately for the unit suite, the UI suite, and the two combined. Use when asked to run new tests or measure new-test coverage, or from the test-coverage-runner agent.
---

# New-Test Coverage Report

Run **only the tests added or modified on this branch** and report coverage of
**only the production lines that branch added or modified** (old, unmodified
code excluded) three ways: **unit only**, **UI only**, and **combined**.

The rules are in
[the new-test coverage standards](../../../.claude/rules/test-coverage-standards.md).
Read that file first — it is the source of truth. This skill defines the
*procedure* and the *output format*.

> Running these tests builds the app and launches a simulator. That is the whole
> point of invoking this skill, so it is the explicit request the repo requires —
> but do not trigger it as a side effect of unrelated work.

> **Permissions.** Copilot CLI prompts to approve each new shell command. Approve
> the `git diff` discovery command(s) and the single `bash` call that runs
> `.claude/scripts/run-new-tests-coverage.sh ...`; that one approval covers
> simulator access too, since `xcodebuild`/`xcrun simctl` run as subprocesses of
> the already-approved script, not as separate tool calls.

## Procedure

**Announce before you act, and narrate throughout.** The build + test run takes
minutes, so never leave the terminal blank. Open with a one-line status and keep
the user posted as you enter each phase (discovering → asking which simulator →
building/running → reporting → cleanup). If there are no new tests, say so and stop.

### 1. Discover the new tests (from git, not memory)

```bash
git diff --name-only main... -- \
  'ai-concept-learningTests/**/*.swift' 'ai-concept-learningUITests/**/*.swift'
```

- **New file** → every test in it.
- **Modified file** → only added/changed tests: `git diff -U0 main... -- <file>`.

### 2. Build `-only-testing` identifiers

For each in-scope test, form `Target/TypeName/testName`. **Read the file** to
resolve the enclosing type — do not guess.

- Unit (Swift Testing, `@Test`): e.g.
  `ai-concept-learningTests/HomeViewModelTests/validateValues`
- UI (XCTest, `func test…`): e.g.
  `ai-concept-learningUITests/HomeViewUITests/testListingAndNavigationflow`

Everything under `ai-concept-learningTests/` is **unit** (including
`UIScreenValidationTests/` snapshot tests); under `ai-concept-learningUITests/`
is **UI**. Echo the plan before running.

### 3. Ask which simulator to use

**Ask the user for the simulator name and the iOS version** — do not guess or
silently auto-pick. Use the `ask_user` tool, e.g. "Which simulator and iOS
version should I run on? (e.g. iPhone 16, iOS 18.5)". List a few installed
options from `xcrun simctl list devices available` when you can. Pass the
answers as `--sim-name` and `--os`.

### 4. Run in the background and relay live progress

```bash
.claude/scripts/run-new-tests-coverage.sh \
  --unit "<unit-id-1>,<unit-id-2>" \
  --ui   "<ui-id-1>" \
  --sim-name "<device the user chose>" --os "<iOS version the user chose>"
```

- Omit `--unit`/`--ui` if that suite has no new tests. With only one suite, the
  combined number equals that suite's.
- `--dest "<full string>"` overrides `--sim-name`/`--os`.
- Add `--min-combined <pct>` to gate (exit non-zero if combined coverage is
  below it), or `--keep` to retain artifacts (default is to delete them).

Run the script with the `bash` tool in **async mode** (a foreground run returns
no output until the whole job finishes, several minutes). While it runs, poll
progress with `read_bash` or `tail -n 20 build/coverage/progress.log` and
**relay it to the user** — post a short update after each pass and whenever the
running test changes, e.g. "Pass 2/3 (UI) — running `testLaunchPerformance`,
~50% done". Progress lines look like
`▶ [ui 2/2 · overall 3/6 (50%)] testLaunchPerformance` and
`✓ Pass 2/3 (ui) complete — job 50% done`.

### 5. Handle failures honestly

If a pass fails to build or a test fails, stop and report the failing identifier
and the compiler/test error verbatim (`build/coverage/<suite>.log`, kept on
failure). A failed run has no valid coverage. If the failure is a bad
simulator/iOS (`Unable to find a device …`), re-ask the user for a valid device
and re-run.

### 6. Clean up

All generated files — result bundles, `DerivedData`, logs, `summary.json` —
live under `build/coverage/`. On a successful run the script **deletes that
directory itself** after printing the report; confirm to the user that
artifacts were cleaned up. If anything was left behind (a `--keep`, interrupted,
or failed run), remove `build/coverage/`. Never commit these files
(`.gitignore` already excludes `build/`).

## Output format

```
New tests run
  Unit (N): <ids…>
  UI   (M): <ids…>

Coverage of added/modified code in ai-concept-learning.app
  Unit tests : <pct>%  (<covered>/<changed-executable> changed lines)
  UI tests   : <pct>%  (<covered>/<changed-executable> changed lines)
  Combined   : <pct>%  (<covered>/<changed-executable> changed lines)

Lowest-covered changed files (combined):
  <pct>%  <file>
  …
```

- Numbers cover **only the lines this branch added or modified** — never the
  whole target, never old/unmodified code.
- Report the **actual** numbers from `summary.json` / the script output. Use
  `N/A` for a suite with no new tests, or when the branch changed no production
  lines — never fabricate.
- Combined is measured from its own run; never present it as unit + UI added
  together.
- If `--min-combined` was set and the run exited non-zero, state clearly that
  the combined coverage is **below the requested threshold**.

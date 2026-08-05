# New-Test Coverage Standards

Rules for running **only the newly written tests** and reporting their code
coverage. This is the source of truth for the `test-coverage-report` skill and
the `test-coverage-runner` agent. Read it first, every run.

The goal is narrow and specific: given the changes on a branch, run just the
unit tests and UI tests that were **added or modified**, and report app-code
coverage three ways — **unit only**, **UI only**, and **combined**.

## 1. Project shape (do not hardcode elsewhere)

| Concept | Value |
|---|---|
| App target (coverage is measured on this) | `ai-concept-learning` → product `ai-concept-learning.app` |
| Unit-test target | `ai-concept-learningTests` (Swift Testing — `@Test`) |
| UI-test target | `ai-concept-learningUITests` (XCTest — `func testXxx`) |
| Unit scheme | `ai-concept-learningTests` |
| UI scheme | `ai-concept-learningUITests` |
| Combined scheme (both testables) | `ai-concept-learning` |

Coverage is always reported for the **app target only** — never for the test
bundles. Test code is not production code and must not inflate the numbers.

## 2. What counts as a "new" test

A test is in scope when it was **added or modified** relative to the base branch
(`main` by default). Determine this from git, not from memory:

```bash
git diff --name-only main... -- \
  'ai-concept-learningTests/**/*.swift' 'ai-concept-learningUITests/**/*.swift'
```

- A **newly added test file** → every test in it is in scope.
- A **modified test file** → only the tests whose bodies/signatures were added
  or changed (inspect `git diff -U0 main... -- <file>`). Do not run untouched
  tests in a modified file.
- Deleted tests are ignored.

## 3. Classifying unit vs UI

Classification is by **target membership**, not by file name or intent:

- Anything under `ai-concept-learningTests/` (including the
  `UIScreenValidationTests/` snapshot tests) is a **unit** test.
- Anything under `ai-concept-learningUITests/` is a **UI** test.

## 4. Building `-only-testing` identifiers

Each selected test becomes one identifier of the form
`Target/TypeName/testFunctionName` (no parentheses, no arguments):

- **Swift Testing** (unit): the enclosing `struct`/`@Suite`/`class` name and the
  `func` name under a `@Test` attribute. Example —
  `ai-concept-learningTests/HomeViewModelTests/validateValues`.
- **XCTest** (UI): the enclosing `XCTestCase` subclass and the `test…` method.
  Example — `ai-concept-learningUITests/HomeViewUITests/testListingAndNavigationflow`.

Resolve each function's enclosing type by reading the file — do not guess. If a
whole new type/file is added, you may list its identifiers at method granularity
(preferred) or use `Target/TypeName` to select the whole suite.

## 5. Measuring coverage (three passes)

Never diff-estimate coverage. Run the tests and read it from the result bundle.
Use the provided script, which runs three isolated passes with
`-enableCodeCoverage YES` and extracts app-target coverage via `xcrun xccov`:

```bash
.claude/scripts/run-new-tests-coverage.sh \
  --unit "<comma-separated unit ids>" \
  --ui   "<comma-separated ui ids>"
```

- **Unit pass** → `build/coverage/unit.xcresult` → unit-only coverage.
- **UI pass** → `build/coverage/ui.xcresult` → UI-only coverage.
- **Combined pass** → `build/coverage/combined.xcresult` → combined coverage.

If only one suite has new tests, run only that suite; the combined number then
equals that suite. The script writes a machine-readable
`build/coverage/summary.json` and prints the human report.

The run must be **observable**: the script prints a job plan (passes and total
test-runs) and streams live progress — the current pass (`Pass k/3`), the test
currently executing with its position, an overall percentage, and a per-pass
`job N% done` line. Every progress line is flushed immediately and mirrored to
`build/coverage/progress.log`.

Because a foreground command returns nothing until it finishes (the build plus
three passes take minutes), the agent/skill **must run the script in the
background and poll** its output / `progress.log`, relaying status to the user
as it happens — not withhold output until the end. Running it foreground and
silent is the bug this is meant to prevent.

## 6. Simulators and builds

Running these tests **builds the app and launches a simulator**. Per the repo
CLAUDE.md, that only happens on an explicit request — invoking this agent/skill
**is** that explicit request. Do not run it as a side effect of unrelated work.

**Manual only — never on `git push`.** This coverage run must not be added to
`.githooks/pre-push` or any other git hook or CI gate. The pre-push hook runs
only the `swift-code-reviewer`. Verifying new-test coverage before pushing is
the developer's choice, done by hand — invoke the `test-coverage-runner` agent
or the `test-coverage-report` skill when you want it, and never automatically.

**Ask the user which simulator to run on.** Before running, the agent/skill must
ask the user for the **simulator name** and **iOS version** and pass them as
`--sim-name` and `--os` — do not guess. The script composes these into the
xcodebuild destination (`platform=iOS Simulator,name=<name>,OS=<version>`); a
raw `--dest "<string>"` overrides them. If neither is given the script falls
back to the first available iPhone and prints a warning — that fallback is a
safety net, not the intended path.

## 6a. Clean up after the job

Every generated file — the `{unit,ui,combined}.xcresult` bundles, `DerivedData`,
per-suite `.log` files, `progress.log`, and `summary.json` — is contained under
`build/coverage/` (the script sets `-derivedDataPath` there so nothing escapes).
On a **successful** run the script deletes `build/coverage/` itself after
printing the report; on **failure** it keeps it for debugging. Pass `--keep` to
retain on success. The agent/skill must ensure nothing is left behind after
reporting — if artifacts remain (a `--keep`, interrupted, or failed run), remove
`build/coverage/`. These files are never committed (`.gitignore` excludes
`build/`).

## 7. Thresholds (optional gate)

Reporting is the default; there is **no** blocking gate unless a threshold is
requested. When one is, pass `--min-combined <pct>`; the script exits non-zero
if combined app coverage is below it. Recommended informational target: **60%**
combined for the app target on touched code — advisory, not enforced.

## 8. Honesty

- Report the **actual** numbers from the result bundles. If a suite had no new
  tests, say `N/A`, do not fabricate a value.
- If a test run fails to build or a test fails, report that plainly with the
  failing identifier and the error — a failed run has no valid coverage.
- Never present combined coverage as the sum of unit and UI percentages; it is
  measured from its own run.

# New-Test Coverage Standards

Rules for running **only the newly written tests** and reporting their code
coverage. This is the source of truth for the `test-coverage-report` skill and
the `test-coverage-runner` agent. Read it first, every run.

The goal is narrow and specific: given the changes on a branch, run just the
unit tests and UI tests that were **added or modified**, and report coverage of
**only the production lines that branch added or modified** — old, unmodified
code is never counted — three ways: **unit only**, **UI only**, and **combined**.

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
bundles — and, within it, **only for the lines this branch added or modified**
(see §5a). Test code is not production code and old, untouched production code
is out of scope; neither may inflate the numbers.

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

Run the tests and read per-line hits from the result bundle — never guess a
number. The reported percentage is then **scoped to only the changed lines**
(§5a), not the whole target. Use the provided script, which runs three isolated
passes with `-enableCodeCoverage YES` and scores coverage via `xcrun xccov`:

```bash
.claude/scripts/run-new-tests-coverage.sh \
  --unit "<comma-separated unit ids>" \
  --ui   "<comma-separated ui ids>" \
  --base main
```

- **Unit pass** → `build/coverage/unit.xcresult` → unit-only coverage.
- **UI pass** → `build/coverage/ui.xcresult` → UI-only coverage.
- **Combined pass** → `build/coverage/combined.xcresult` → combined coverage.

If only one suite has new tests, run only that suite; the combined number then
equals that suite. The script writes a machine-readable
`build/coverage/summary.json` and prints the human report.

## 5a. Scope: only added/modified production lines

The reported coverage is **not** whole-target coverage. For every suite the
script:

1. Computes the set of production lines this branch **added or modified** —
   `git diff -U0 <base>... -- <app sources>` (default base `main`, default
   sources `:(glob)ai-concept-learning/**/*.swift`; the test targets are
   **excluded**). Only lines on the `+` side of the diff are in scope.
2. Reads **per-line** hit counts for those files from the run's `.xcresult`
   (`xcrun xccov view --file <src> <bundle>`), keeping only executable lines.
3. Reports, of those changed executable lines, how many were exercised.

So a suite's number answers "of the code I just wrote/changed, how much did
these tests cover" — old, unmodified lines are never in the numerator or the
denominator. Pass `--base <ref>` to diff against something other than `main`,
`APP_GLOB` to change the source pathspec. If a branch changed no production
lines, the script says so and there is nothing to score.

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

The agent/skill must also **announce before the first tool call** — a one-line
statement of intent (e.g. "Evaluating the changed tests before running the newly
added ones and reporting coverage…") — and narrate each phase (discovering,
choosing the simulator, building/running, reporting, cleanup). The terminal must
never look frozen with nothing printed.

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

**Run interactively so the terminal can ask for permission.** Building and
booting a simulator needs the user's consent, granted through Claude Code's
normal tool-approval prompt — invoke this as `claude --agent
test-coverage-runner` (not `-p`) so that prompt can appear. Expect it roughly
twice: once for the `git diff` discovery command(s), and once for the single
Bash call that runs `run-new-tests-coverage.sh` — approving that one call also
covers simulator access, since `xcodebuild`/`xcrun simctl` run inside it as
subprocesses, not as separate tool calls. Do not pass `--allowedTools` to try
to pre-grant this instead; many orgs restrict permission rules to managed
settings, so the flag is silently ignored. Headless `-p` mode shows no prompt
at all, so prefer interactive mode whenever the user needs to grant this
themselves.

## 6a. Clean up after the job

Every generated file — the `{unit,ui,combined}.xcresult` bundles, a **separate**
`DerivedData-<suite>` per pass, per-suite `.log` files, `progress.log`, and
`summary.json` — is contained under `build/coverage/` (the script sets
`-derivedDataPath` there so nothing escapes). Each pass gets its own derived-data
directory rather than sharing one — see §9 for why. On a **successful** run the
script deletes `build/coverage/` itself after printing the report; on
**failure** it keeps it for debugging. Pass `--keep` to retain on success. The
agent/skill must ensure nothing is left behind after reporting — if artifacts
remain (a `--keep`, interrupted, or failed run), remove `build/coverage/`. These
files are never committed (`.gitignore` excludes `build/`).

## 7. Thresholds (optional gate)

Reporting is the default; there is **no** blocking gate unless a threshold is
requested. When one is, pass `--min-combined <pct>`; the script exits non-zero
if combined app coverage is below it. Recommended informational target: **60%**
combined for the app target on touched code — advisory, not enforced.

## 8. Honesty

- Report the **actual** numbers from the result bundles, scoped to the changed
  lines (§5a). If a suite had no new tests, say `N/A`; if the branch changed no
  production lines, say so — do not fabricate a value.
- Coverage is over **added/modified production lines only**. Never report
  whole-target coverage, and never let old/unmodified lines enter the numerator
  or denominator.
- If a test run fails to build or a test fails, report that plainly with the
  failing identifier and the error — a failed run has no valid coverage.
- Never present combined coverage as the sum of unit and UI percentages; it is
  measured from its own run.

## 9. Troubleshooting

**"Ignoring --allowedTools ...: permission rules are restricted to managed
settings"** (headless `-p` runs) — the org restricts tool permissions to managed
settings, so CLI `--allowedTools` grants nothing. Run the agent interactively
instead (`claude --agent test-coverage-runner`) and approve tool prompts as they
appear, or have an admin add the needed tools to managed settings.

**`CoreSimulatorService connection became invalid` /
`Operation not permitted` on `~/Library/Logs/CoreSimulator/...`** — this happens
when `xcrun`/`xcodebuild` run inside an agent's sandboxed Bash tool whose
filesystem write-allowlist doesn't include CoreSimulator's log/device-set
directories. Any simulator lookup fails the same way regardless of the
`--sim-name`/`--os` given. There is no script-level fix: either run the script
by hand in a plain (non-sandboxed) terminal, or have an admin add
`~/Library/Logs/CoreSimulator/**` and `~/Library/Developer/CoreSimulator/**` to
the sandbox's write-allowlist.

**`xcrun xccov view` fails with `Failed to load coverage archive ... Metadata.plist
couldn't be opened`** — caused by sequential `xcodebuild test` passes sharing one
`-derivedDataPath`; the coverage-archive staging data can go stale between
passes and this surfaces on a later (often the last/combined) pass. The script
gives every pass its own `DerivedData-<suite>` directory specifically to avoid
this. If it recurs anyway: delete any stale `build/coverage/` from a prior
failed run before retrying (`rm -rf build/coverage`), then re-run.

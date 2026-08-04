---
name: swift-code-review
description: Review Swift/SwiftUI changes against this repo's coding standards (MVVM, function/line length, naming, no dead or commented-out code). Use before pushing, in the pre-push hook, or when asked to review Swift code.
---

# Swift Code Review

Review Swift code against
[the repo coding standards](../../../.claude/rules/swift-coding-standards.md).
Read that file first — it is the source of truth. This skill defines the
*procedure* and the *output format*.

## Scope

Review only the files you are given (the pre-push hook passes the changed
`*.swift` files). If none are specified, review the files changed on the current
branch (`git diff --name-only main... -- '*.swift'`).

**Exclude test code.** Do not review or flag files under any `*Tests/` or
`*UITests/` directory (unit tests, UI tests, snapshot tests, test fixtures /
helpers). These are out of scope — skip them entirely even if they appear in the
diff.

## Procedure

For each file, read it fully, then check every rule below. Report a violation
with `file:line`, the rule it breaks, and a concrete fix.

| # | Rule | How to check |
|---|------|--------------|
| 1 | **MVVM + clean layering** | Views must not do data access directly; logic belongs in a ViewModel; data access behind a protocol. Model / ViewModel / Service concerns should be separated, not mixed in one type. Dependencies injected via `init`. |
| 2 | **Function ≤ 20 lines** | Count body lines between `{` and `}`, excluding signature and closing brace. |
| 3 | **Line ≤ 100 chars** | Flag any line whose length exceeds 100. |
| 4 | **No unused** | Variables, params, properties, imports, types, or functions never referenced. Flag types defined but never instantiated. |
| 5 | **No commented-out code** | Comment lines that are disabled code (not prose). Prose comments explaining *why* are fine. |
| 6 | **Naming** | Types `UpperCamelCase`, no `Class`/`Struct` suffix, no stdlib shadowing (`Result`), no typos. Properties `lowerCamelCase`, named for role not type. Booleans as assertions. |
| 7 | **No single-line control flow** | Flag `if`/`else`/`guard`/`for`/`while`/`switch` cases whose body is on the same line as the statement (e.g. `if x { "" } else { print("") }`). |
| 8 | **No hardcoded URLs** | Flag URL/endpoint string literals — as an argument (`doSomething(url: "https://...")`) or a stored constant (`static let url = "https://..."`). Must come from config. |
| 9 | **Cyclomatic complexity ≤ 15** | Count branching points per function (`if`, `else if`, `for`, `while`, `case`, `catch`, `&&`, `\|\|`, `?:`, `guard`); flag > 15. |
| 10 | **File ≤ 500 lines** | Flag any `*.swift` file longer than 500 lines. |
| 11 | **No retain cycles** | Escaping closures capturing `self` (Combine sinks, completion handlers, long-lived `Task`s) must use `[weak self]`; delegate/parent refs must be `weak`. |
| 12 | **Main-thread safety** | UI / `@Published` mutation must be on the main thread — `@MainActor`, `MainActor.run`, or `DispatchQueue.main.async`. Flag background-context mutation. |
| 13 | **No deprecated APIs** | Flag deprecated/superseded classes, functions, initializers, properties, or modifiers. **Name the modern replacement and show corrected syntax** (e.g. `NavigationView` → `NavigationStack`, two-parameter `onChange`). |
| 14 | **Hygiene** | Imports at top; no force-unwrap `!` / force-`try`; no redundant `do/catch` that only rethrows; consistent 4-space indent. |

## Severity

- **Blocking**: the deterministic rules (2–14) and clear MVVM violations.
- **Advisory**: subjective structure/readability suggestions — report but do not
  fail the review on these alone.

## Output format

Print findings grouped by file, most severe first:

```
<path>:<line>  [rule N]  <what is wrong> → <fix>
```

Then a one-line summary. **The final line of your output must be exactly one of:**

```
COPILOT_REVIEW_VERDICT: PASS
COPILOT_REVIEW_VERDICT: FAIL
```

Emit `FAIL` if there is **one or more blocking** violation; otherwise `PASS`.
The pre-push hook greps for this token to decide whether to block the push, so
it must be the last line and must match exactly.

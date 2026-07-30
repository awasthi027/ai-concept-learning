# ai-concept-learning

A SwiftUI iOS app (MVVM). Source lives in `ai-concept-learning/`.

## Coding standards (mandatory)

All Swift code must follow the standards in
[.claude/rules/swift-coding-standards.md](.claude/rules/swift-coding-standards.md).
Read that file before writing or editing Swift and apply every rule. In short:

- **MVVM + clean layering** — Views stay declarative; logic lives in ViewModels;
  data access sits behind a protocol-based Service / DataSource layer.
- **Functions ≤ 20 lines**, **lines ≤ 100 characters**, **files ≤ 500 lines**,
  **cyclomatic complexity ≤ 15** per function.
- **No unused** variables, imports, types, or functions; **no commented-out code**.
- **Names justify the type/role** — no `Class` suffixes, no stdlib shadowing
  (`Result` → `ToDoStatus`), no typos, properties named for role not type.
- **No single-line control-flow bodies**; **no hardcoded URLs/endpoints**
  (source them from config).
- **No retain cycles** (`[weak self]` in escaping closures, `weak` delegates);
  **main-thread safety** for all UI / `@Published` mutation (`@MainActor`).
- **No deprecated APIs** — replace with the modern equivalent and show the
  corrected syntax (e.g. `NavigationView` → `NavigationStack`).
- Imports at top; avoid force-unwrap / force-`try`; no redundant `do/catch`.

## Enforcement

On `git push`, `.githooks/pre-push` runs the **`swift-code-reviewer`** agent
against the pushed changes and blocks the push if any rule is violated. You can
run the same review any time with the `swift-code-review` skill.

## Building / testing

CI is defined under `.github/workflows/` (Fastlane-based). Do not run builds or
simulators unless the user explicitly asks.

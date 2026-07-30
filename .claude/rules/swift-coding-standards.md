# Swift Coding Standards

These are the mandatory rules for all Swift code in this repository. They are
enforced on `git push` by the `swift-code-reviewer` agent (see
`.githooks/pre-push`) and must be followed when writing or editing code.

## 1. Architecture — MVVM + Clean layering

- Follow **MVVM**: Views are declarative and stateless beyond `@State` /
  `@StateObject` / bindings; all logic and mutable state live in a
  `ViewModel` (an `ObservableObject`).
- A View must not talk to a data source, network, or persistence directly — it
  goes through its ViewModel.
- Keep the layers separated: **Model** (plain data types), **ViewModel**
  (presentation logic), **Service / DataSource** (data access behind a
  protocol). Prefer one primary type per file, grouped by layer.
- Depend on protocols, not concrete types. Inject dependencies through `init`
  (as already done with `ToDoServiceProtocol`).

## 2. Function length

- A function body must not exceed **20 lines** (excluding the signature line and
  the closing brace). Extract helpers when it grows beyond that.

## 3. Line length

- A line must not exceed **100 characters**. Wrap arguments, chained modifiers,
  or expressions onto multiple lines.

## 4. No unused code

- No unused variables, parameters, properties, types, imports, or functions.
- No dead code: a type or function that is never referenced must be removed.

## 5. No commented-out code

- Do not commit commented-out code. Delete it — git history is the archive.
- Explanatory comments that describe *why* are allowed; disabled code is not.

## 6. Naming

Names must justify the type and role of what they label:

- **Types**: `UpperCamelCase`. The name must describe the concept, not the
  language construct — no `Class`/`Struct` suffixes (`DatalayerClass` ✗).
  Avoid shadowing standard-library types (`Result` ✗ → `ToDoStatus` ✓).
- **Properties / variables / functions**: `lowerCamelCase`, named for their
  **role**, not their type (`toDoService` ✓, not `toDoServiceProtocol`).
- No abbreviations or typos in identifiers (`ToDoNetworkServic` ✗).
- Booleans read as assertions (`isLoading`, `hasError`).

## 7. No single-line control-flow bodies

- The body of an `if` / `else` / `guard` / `for` / `while` / `switch` case must
  be on its own line, not collapsed onto the statement line.

```swift
// ✗ Wrong
if isTrue { "" } else { print("") }

// ✓ Correct
if isTrue {
    ""
} else {
    print("")
}
```

## 8. No hardcoded URLs / endpoints

- Never inline a URL or endpoint string literal in code — neither as an
  argument nor as a stored constant.
- Source URLs from configuration (Info.plist, an environment/config type, or a
  build setting) so they are not baked into the source.

```swift
// ✗ Wrong
doSomething(url: "https://www.google.com")
static let url = "https://www.google.com"

// ✓ Correct
doSomething(url: AppConfig.current.searchEndpoint)
```

## 9. Cyclomatic complexity

- A function's cyclomatic complexity must not exceed **15**. Count each
  branching point (`if`, `else if`, `for`, `while`, `case`, `catch`, `&&`,
  `||`, `?:`, `guard`). Beyond that, decompose the function.

## 10. File length

- A source file must not exceed **500 lines**. Split by responsibility
  (typically one primary type per file) when it grows past that.

## 11. No retain cycles

- Do not create strong reference cycles. In escaping closures that capture
  `self` (e.g. Combine sinks, completion handlers, `Task` closures that outlive
  the scope), capture `[weak self]` (or `[unowned self]` where lifetime is
  guaranteed) and `guard let self else { return }`.
- Delegate properties and parent back-references must be `weak`.

## 12. Main-thread safety

- All UI / published state mutation must happen on the main thread. Annotate UI
  types or methods with `@MainActor`, or hop with
  `await MainActor.run { ... }` / `DispatchQueue.main.async { ... }` before
  touching `@Published` properties or the view hierarchy from a background
  context.

## 13. No deprecated APIs

- Do not use deprecated classes, functions, initializers, properties, or
  modifiers (anything marked `@available(..., deprecated:)`, or superseded by a
  newer API).
- When one is found, name the **modern replacement** and show the corrected
  syntax, not just the warning.

```swift
// ✗ Deprecated (iOS 17)
NavigationView { ... }
.onChange(of: value) { newValue in ... }

// ✓ Replacement
NavigationStack { ... }
.onChange(of: value) { oldValue, newValue in ... }
```

## 14. General hygiene

- Imports at the top of the file, below the header comment.
- Avoid force-unwrapping (`!`) and force-`try`; handle `nil` / errors explicitly.
- No redundant `do/catch` that only rethrows — let it propagate.
- Keep indentation consistent (4 spaces).

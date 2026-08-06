---
name: new-code-coverage
description: Find the production code changed on this branch, run only the unit and UI tests that cover it, and report changed-line code coverage (unit, UI, overall) with live progress and total time taken. Use when asked to measure how well newly written code is covered.
---

# New-code coverage — procedure

Implements the [new-code coverage standards](../../rules/new-code-coverage-standards.md).
Read that rule first — it is the source of truth for **what** to measure. This
skill is the **procedure and exact commands**. Report-only; runs on request.

> Running this builds the app and launches a simulator. Approve the single
> `bash` invocations. Keep everything under `build/coverage/` — never `/tmp`.

## 1. Find the production code that changed

**Start a wall-clock timer now** (note the time; report elapsed at the end).

```bash
git diff --name-only main... -- ':(glob)ai-concept-learning/**/*.swift'
```

Exclude `*Tests/` / `*UITests/`. For each changed file, read the hunks
(`git diff -U0 main... -- <file>`) and note the changed **symbols**
(types/functions/properties) and the file's base type (e.g. `HomeViewModel`,
`HomeView`). If nothing changed, say so and stop.

## 2. Select only the tests that cover that changed code

- **Existing tests referencing the changed symbols** — grep the test tree:
  ```bash
  grep -rnl -e 'HomeViewModel' -e '<other-changed-symbol>' \
    ai-concept-learningTests ai-concept-learningUITests
  ```
  For UI tests, also match by the screen/feature the changed view belongs to
  (change in `HomeView.swift` → `HomeViewUITests`).
- **New/modified tests** on the branch:
  ```bash
  git diff --name-only main... -- \
    'ai-concept-learningTests/**/*.swift' 'ai-concept-learningUITests/**/*.swift'
  ```

Read each candidate to resolve its type and form `-only-testing` identifiers:
`Target/TypeName/testName` (one test) or `Target/TypeName` (whole class) — both
valid. Resolve method names by **reading the file**, never a "probe" run.
`ai-concept-learningTests/` → unit, `ai-concept-learningUITests/` → UI. When
unsure, include the test. If none cover the change, say so and stop.

## 3. Announce the selected tests (before running)

```
Changed production files:
  ai-concept-learning/<file>.swift

Tests selected to cover the changed code:
  Unit (N):
    ai-concept-learningTests/HomeViewModelTests/validateValues   (existing)
  UI (M):
    ai-concept-learningUITests/HomeViewUITests/testHomeFlow      (new)
```

Mark each id `(existing)` or `(new)`. Then proceed.

## 4. Run only the selected tests (coverage + live progress)

Run with the `bash` tool in **async mode** and **stream progress — never leave
the terminal blank.** No `-quiet`; tee to a log and relay each phase
(Building → Testing → per-test) plus a per-suite bar like
`[1/2] Unit ▓▓▓▓▓▓░░░ testing 4/6`.

```bash
DEST='platform=iOS Simulator,name=iPhone 17,OS=26.2'
mkdir -p build/coverage
JOB_START=$(date +%s)   # overall timer (used in the final report)
onlys() { for id in "$@"; do printf ' -only-testing:%s' "$id"; done; }

UNIT_IDS=( <selected unit ids> )
UI_IDS=( <selected ui ids> )

# Unit pass (only if UNIT_IDS non-empty)
xcodebuild test -project ai-concept-learning.xcodeproj \
  -scheme ai-concept-learningTests -destination "$DEST" \
  -enableCodeCoverage YES -resultBundlePath build/coverage/unit.xcresult \
  $(onlys "${UNIT_IDS[@]}") 2>&1 | tee build/coverage/unit.log

# UI pass (only if UI_IDS non-empty)
xcodebuild test -project ai-concept-learning.xcodeproj \
  -scheme ai-concept-learningUITests -destination "$DEST" \
  -enableCodeCoverage YES -resultBundlePath build/coverage/ui.xcresult \
  $(onlys "${UI_IDS[@]}") 2>&1 | tee build/coverage/ui.log
```

**No separate combined pass.** Skip a suite whose id list is empty. Poll the logs
with `read_bash`/`tail`; after each pass print a one-liner
(`[1/2] Unit ✓ 6 passed in 38s`).

## 5. Compute coverage of ONLY the changed lines

```bash
python3 - main ':(glob)ai-concept-learning/**/*.swift' build/coverage <<'PY'
import os, re, subprocess, sys
base, glob, out = sys.argv[1], sys.argv[2], sys.argv[3]
repo = subprocess.check_output(["git","rev-parse","--show-toplevel"]).decode().strip()
def sh(a): return subprocess.run(a, cwd=repo, capture_output=True, text=True).stdout
files = [f for f in sh(["git","diff","--name-only",base+"...","--",glob]).splitlines()
         if f.strip() and "Tests/" not in f and "UITests/" not in f]
HUNK = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")
def changed(f):
    s=set()
    for ln in sh(["git","diff","-U0",base+"...","--",f]).splitlines():
        m=HUNK.match(ln)
        if m:
            st=int(m.group(1)); n=int(m.group(2) or "1"); s|=set(range(st,st+n))
    return s
chg={f:changed(f) for f in files}; chg={f:s for f,s in chg.items() if s}
XL=re.compile(r"^\s*(\d+)\s*:\s*(\*|\d+)")
def hits(b,f):
    t=sh(["xcrun","xccov","view","--file",os.path.join(repo,f),os.path.join(repo,b)])
    d={}
    for ln in t.splitlines():
        m=XL.match(ln)
        if m: d[int(m.group(1))]=None if m.group(2)=="*" else int(m.group(2))
    return d
def scan(b):
    if not os.path.exists(os.path.join(repo,b)): return None
    data={}
    for f,ls in chg.items():
        h=hits(b,f); execs=set(); covs=set()
        for n in ls:
            c=h.get(n)
            if c is None: continue
            execs.add(n)
            if c>0: covs.add(n)
        if execs: data[f]=(execs,covs)
    return data
scans={n:scan(os.path.join(out,n+".xcresult")) for n in ("unit","ui")}
def totals(data):
    if data is None: return None
    ex=sum(len(e) for e,_ in data.values())
    cov=sum(len(c) for _,c in data.values())
    return {"ex":ex,"cov":cov,"pct":(cov/ex*100 if ex else None)}
# Overall = union across suites: covered if ANY suite hit the changed line.
allf=set()
for d in scans.values():
    if d: allf|=set(d)
ov=[]; ov_ex=ov_cov=0
for f in allf:
    execs=set(); covs=set()
    for d in scans.values():
        if d and f in d:
            e,c=d[f]; execs|=e; covs|=c
    if execs:
        ov_ex+=len(execs); ov_cov+=len(covs); ov.append((f,len(covs),len(execs)))
OV={"ex":ov_ex,"cov":ov_cov,"pct":(ov_cov/ov_ex*100 if ov_ex else None)}
def cell(r):
    if r is None: return "N/A (not run)"
    if not r["ex"]: return "N/A (no changed exec lines)"
    return f"{r['pct']:6.2f}%  ({r['cov']}/{r['ex']} changed lines)"
print("")
print(f"New-code coverage (changed lines vs {base}, target ai-concept-learning.app)")
print(f"  Unit tests    : {cell(totals(scans['unit']))}")
print(f"  UI tests      : {cell(totals(scans['ui']))}")
print(f"  Overall (new) : {cell(OV)}")
if ov:
    print("\n  Lowest-covered changed files (overall):")
    for f,fc,fe in sorted(ov, key=lambda x:(x[1]/x[2] if x[2] else 1)):
        print(f"    {fc/fe*100:6.2f}%  {fc}/{fe}  {f}")
PY
```

## 6. Report

```
Tests selected to cover the changed code
  Unit (N): <ids…>
  UI   (M): <ids…>

New-code coverage (changed lines vs main, target ai-concept-learning.app)
  Unit tests    : <pct>%  (<covered>/<changed> changed lines)
  UI tests      : <pct>%  (<covered>/<changed> changed lines)
  Overall (new) : <pct>%  (<covered>/<changed> changed lines)

  Lowest-covered changed files (overall):
    <pct>%  <file>

Time taken: <Xm Ys>   (total agent run time)
```

Print the elapsed time on the last line:
`echo "Time taken: $(( ($(date +%s) - JOB_START) / 60 ))m $(( ($(date +%s) - JOB_START) % 60 ))s"`
(or compute from the start timestamp if the timer isn't in scope).

## 7. Clean up the build folder (after reporting)

```bash
rm -rf build/coverage
rmdir build 2>/dev/null || true
```

Confirm the build folder was cleaned. Skip cleanup **only** if the run failed
(keep `build/coverage/` for inspection).

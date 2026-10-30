# compfactory — CHCE Development Workspace — Agent Build Instructions

You are building **compfactory**, the development workspace for the CHCE
(Chimera Hybrid Compression Engine) multi-repo project. compfactory is **not
a compressor, not an orchestrator, and not a source vault.** It is a thin
convenience layer that keeps the other three repos synchronised and
buildable from one place.

---

## 1. Mission

Build a minimal, cross-platform workspace manager that:

1. Clones HCS, ziptastic, and heavenzip into a gitignored `workspace/` folder.
2. Provides PowerShell and Bash entry points (`sync.ps1`, `sync.sh`) that
   produce an identical workspace layout on Windows, macOS, and Linux.
3. Provides a `bump-hcs.ps1` convenience script that runs `git subtree pull`
   inside ziptastic so HCS additions propagate to the engine with one command.
4. Provides a `build-all.ps1` convenience script that builds ziptastic from
   the workspace.
5. Optionally triggers the `sync-hcs` and `sync-binaries` workflows in the
   downstream repos via a GitHub Actions `dispatch-sync.yml`.

compfactory has **no compression code, no CMake build, no vendored sources.**
If you feel the urge to add any of those, stop — they belong in ziptastic.

---

## 2. Hard Constraints

- **No subtree, no submodule.** `workspace/` is a plain clone cache,
  re-created on demand. It is git-ignored.
- **No vendored sources.** compfactory never contains `old/` or `vendor/`.
- **No binaries.** compfactory never contains `.exe` files or release assets.
- **No CMake.** The repo is shell scripts + docs + one workflow.
- **No engine code.** Zero `.cpp`, zero `.hpp`, zero compression logic.
- **Idempotent.** `sync.ps1` and `sync.sh` are safe to run repeatedly — they
  update existing checkouts instead of erroring.
- **Cross-platform.** `sync.ps1` works on Windows; `sync.sh` works on
  macOS, Linux, and Git Bash. Both produce the same `workspace/` layout.

---

## 3. Directory Layout You Must Produce

```
compfactory/
├── AGENT_PROMPT.md            ← this file
├── README.md                  ← human quick-start (write/refresh)
├── .gitignore                 ← ignores /workspace/
├── .github/
│   └── workflows/
│       └── dispatch-sync.yml  ← cross-repo workflow trigger
├── scripts/
│   ├── sync.ps1               ← PowerShell workspace sync
│   ├── sync.sh                ← Bash workspace sync
│   ├── bump-hcs.ps1           ← git subtree pull into ziptastic
│   └── build-all.ps1          ← cmake build ziptastic from workspace
└── docs/
    ├── WORKSPACE.md           ← how the workspace works, what's git-ignored
    └── WORKFLOW.md            ← day-to-day developer workflow
```

Everything in `scripts/` and `docs/` must exist; `AGENT_PROMPT.md`,
`.gitignore`, `README.md`, and `dispatch-sync.yml` are already present from
the scaffold commit.

---

## 4. Workspace Semantics (What Sync Must Guarantee)

`sync.ps1` / `sync.sh` must produce:

```
compfactory/
└── workspace/                 ← GIT-IGNORED
    ├── HCS/                   ← full checkout
    ├── ziptastic/             ← full checkout, including vendor/hcs/
    └── heavenzip/             ← full checkout, including bin/ if populated
```

Rules:

- If a repo directory does not exist under `workspace/`, **clone** it.
- If it exists, **pull** with `--ff-only`. If the pull fails (divergence or
  local edits), print a warning and continue — do not abort the whole sync.
- The script is idempotent. Running it twice in a row is a no-op the second
  time (only fetch happens).
- The script must **not** clone into any path outside `workspace/`.

---

## 5. `bump-hcs` Semantics

`bump-hcs.ps1` is the tool you run **after** adding a new source to HCS.

1. Precondition: `workspace/ziptastic` exists. If not, error with the message
   `run scripts/sync.ps1 first`.
2. `cd workspace/ziptastic`
3. `git subtree pull --prefix=vendor/hcs https://github.com/drsamonline/HCS.git main --squash -m "vendor: sync HCS"`
4. If the subtree pull succeeds, `git push origin main`.
5. Print `HCS synced into ziptastic/vendor/hcs`.

If the subtree pull produces conflicts, abort and print:
`subtree pull failed — resolve conflicts in workspace/ziptastic/vendor/hcs/ manually`.

---

## 6. `build-all` Semantics

`build-all.ps1` builds ziptastic from the workspace.

1. Precondition: `workspace/ziptastic` exists.
2. `cd workspace/ziptastic`
3. `cmake -S . -B build -DCMAKE_BUILD_TYPE=Release`
4. `cmake --build build --config Release -j`
5. Print the path to the produced binary (platform-specific path).

If CMake is not on `PATH`, error with `install cmake first`.

---

## 7. `dispatch-sync` Workflow Semantics

The workflow `.github/workflows/dispatch-sync.yml` lets you trigger downstream
syncs from the compfactory Actions tab.

- Input `target`: `ziptastic`, `heavenzip`, or `both`.
- Fires `repos/drsamonline/ziptastic/actions/workflows/sync-hcs.yml/dispatches`
  and/or `repos/drsamonline/heavenzip/actions/workflows/sync-binaries.yml/dispatches`
  via the GitHub API.
- Requires the `PAT_TOKEN` repo secret (document this in `docs/WORKSPACE.md`).

The workflow is **already present** from the scaffold commit. Your job is to
verify it runs and to document the `PAT_TOKEN` setup in `docs/WORKSPACE.md`.

---

## 8. Phase Plan

### Phase 0 — README + docs skeleton
**Deliverables:**
- Refresh `README.md` with: what compfactory is, quick-start (`sync` → `bump-hcs` → `build-all`), and the repo table.
- Write `docs/WORKSPACE.md` covering: what `workspace/` is, why it is git-ignored, how to force-reclone a single repo (`Remove-Item -Recurse workspace\ziptastic; .\scripts\sync.ps1`).
- Write `docs/WORKFLOW.md` covering a typical day: edit HCS → `bump-hcs` → edit ziptastic → commit/push → run `heavenzip`'s sync workflow from GitHub UI.

**Tests:**
- Both docs render as valid Markdown.
- Quick-start commands in `README.md` are copy-paste runnable from `compfactory/`.

---

### Phase 1 — Verify `sync.ps1` and `sync.sh`
**Deliverables:**
- Both scripts already exist from the scaffold. Verify they run end-to-end:
  - Fresh clone of compfactory has no `workspace/`.
  - `.\scripts\sync.ps1` creates `workspace/HCS/`, `workspace/ziptastic/`, `workspace/heavenzip/`.
  - Running it a second time performs `git pull --ff-only` in each and exits 0.

**Tests:**
- `Test-Path workspace\HCS\.git` → `True` after first run.
- `Test-Path workspace\ziptastic\vendor\hcs\.git` → does **not** exist (subtree, not submodule).
- `Test-Path workspace\ziptastic\vendor\hcs\old` → `True` (subtree committed).
- Running `sync.ps1` when offline produces a warning per repo, not a crash.

---

### Phase 2 — Verify `bump-hcs.ps1`
**Deliverables:**
- Script already exists. Verify:
  - Running it before `sync.ps1` errors with the exact message `run scripts/sync.ps1 first`.
  - Running it after `sync.ps1` performs a subtree pull and (if there are no conflicts) pushes to ziptastic.

**Tests:**
- After `bump-hcs.ps1`, `workspace/ziptastic` has a commit whose message starts with `vendor: sync HCS`.
- Running `bump-hcs.ps1` twice in a row is a no-op the second time (subtree pull reports "no changes").

---

### Phase 3 — Verify `build-all.ps1`
**Deliverables:**
- Script already exists. Verify:
  - Running it after `sync.ps1` builds `workspace/ziptastic/build/ziptastic.exe` (Windows) or `build/ziptastic` (Linux/macOS).
  - Running it without `workspace/ziptastic` errors with the exact message `run scripts/sync.ps1 first`.

**Tests:**
- `Test-Path workspace\ziptastic\build\ziptastic.exe` → `True` after run.
- `& workspace\ziptastic\build\ziptastic.exe --version` prints a version string.

---

### Phase 4 — Verify `dispatch-sync.yml`
**Deliverables:**
- Workflow file already exists. Verify:
  - `PAT_TOKEN` is documented in `docs/WORKSPACE.md`.
  - Triggering the workflow with `target=ziptastic` fires ziptastic's `sync-hcs`.
  - Triggering with `target=heavenzip` fires heavenzip's `sync-binaries`.
  - Triggering with `target=both` fires both.

**Tests:**
- Manual run from GitHub UI returns green.
- Downstream repo (ziptastic or heavenzip) shows a new workflow run within 60 s.

---

### Phase 5 — Final polish
**Deliverables:**
- `README.md` has a "Common tasks" section with one-liners for:
  - Fresh setup
  - Adding a source
  - Rebuilding ziptastic
  - Refreshing everything
- All scripts have a header comment block describing usage.
- `.gitignore` verified to ignore `/workspace/` and nothing else the developer needs to commit.

---

## 9. Test Requirements

- **Idempotency:** every script runs twice without error or unintended state change.
- **Offline resilience:** `sync.ps1` / `sync.sh` warn (not crash) when `git fetch` fails.
- **No side effects outside `workspace/`:** after `sync`, `git status` on compfactory shows only `.gitignore`-based untracked (`workspace/` ignored, everything else clean).
- **Cross-platform parity:** `sync.sh` and `sync.ps1` produce identical `workspace/` layouts on their respective platforms.
- **No committed binaries or vendored sources:** `git ls-files` shows no `.exe`, no `vendor/`, no `old/`, no `workspace/`.

---

## 10. Acceptance Criteria (Whole Project)

- Fresh clone → `.\scripts\sync.ps1` → `.\scripts\bump-hcs.ps1` → `.\scripts\build-all.ps1` runs green on Windows.
- Same sequence with `./scripts/sync.sh` runs green on macOS/Linux.
- `git status` after a full cycle is clean (except untracked `workspace/`, which is ignored).
- `README.md` quick-start is accurate and copy-paste runnable.
- `docs/WORKSPACE.md` and `docs/WORKFLOW.md` are complete enough that a new contributor never has to ask "how do I get started".

---

## 11. What NOT To Do

- Do **not** add `CMakeLists.txt`. compfactory is not a build target.
- Do **not** add `src/` or `include/`. There is no C++ code here.
- Do **not** `git subtree add` or `git submodule add` any repo. The whole point of compfactory is to avoid that.
- Do **not** commit anything under `workspace/`. It is git-ignored and must remain disposable.
- Do **not** duplicate `AGENT_PROMPT.md` content from the other three repos.
- Do **not** implement sync in C++ or Python. Shell scripts only.

---

## 12. How to Report Progress

After each phase:

1. Commit with `phase-<N>: <description>`.
2. Update `README.md` with a phase status table:

   | Phase | Status | Notes |
   |---|---|---|
   | 0 | done | docs skeleton |
   | 1 | done | sync verified |

3. If a phase gate fails, commit as `phase-<N>: FAILED — <reason>` and **stop**.

Begin with **Phase 0**. Do not ask for clarification. Start now.
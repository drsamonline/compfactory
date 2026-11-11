# The workspace

`workspace/` is where the other CHCE repositories are checked out as **plain clones**, side by side, so
that a single session can edit HCS, build ziptastic and run heavenzip without juggling three
terminals.

```
compfactory/
├── scripts/            sync.ps1  sync.sh  bump-hcs.ps1  build-all.ps1
├── tests/check-scripts.sh
└── workspace/          git-ignored — three clones, not a repository
    ├── HCS/            the source vault
    ├── ziptastic/      the engine
    └── heavenzip/      the orchestrator
```

`workspace/` is created by `scripts/sync.ps1` or `scripts/sync.sh` and by nothing else. If it is
missing, every other script fails with `run scripts/sync.ps1 first` rather than guessing.

## Why it is git-ignored

`.gitignore` carries `/workspace/`, anchored to the repository root. Two reasons:

1. **A clone inside a repository is not content.** Committing it would either nest a `.git`
   directory — which git refuses to track usefully — or silently strip it and turn a clone into a
   frozen copy nobody can pull.
2. **The scripts must agree on one location.** They did not, once. `sync.ps1` joined `workspace` to
   the *scripts* directory, so a sync materialised `scripts/workspace` while `build-all.ps1`,
   `bump-hcs.ps1` and `sync.sh` all looked at `../workspace` from the same starting point — and
   `.gitignore`'s anchored `/workspace/` did not cover the misplaced tree either. The second step of
   the documented flow could not find what the first step had just made.

`tests/check-scripts.sh` exists to keep that from happening again. It reads the workspace expression
out of each script, asserts all four resolve to `../workspace` (or `../workspace/ziptastic`), and
asserts `.gitignore` covers the result. It runs in CI on every push.

```bash
bash tests/check-scripts.sh     # exit 0 = the scripts agree
```

## The scripts

| Script | What it does | What it guarantees |
|---|---|---|
| `scripts/sync.ps1` (Windows) | Creates `workspace/`, clones `HCS`, `ziptastic`, `heavenzip` into it | Re-running performs `git pull --ff-only` in each; it never force-updates or discards local work |
| `scripts/sync.sh` (macOS/Linux) | Same, bash | Same |
| `scripts/bump-hcs.ps1` | `git subtree pull --prefix=vendor/hcs https://github.com/drsamonline/HCS.git main --squash`, then pushes ziptastic | The commit message starts `vendor: sync HCS`; a second run in a row is a no-op |
| `scripts/build-all.ps1` | Configures and builds ziptastic in `workspace/ziptastic/build` | Fails with `run scripts/sync.ps1 first` if the clone is absent |

`sync` is deliberately shallow in what it will do: `--ff-only` means a diverged clone stops and tells
you rather than merging on your behalf. If a clone has local work you want gone, delete it and sync
again (below).

## Force-recloning a single repository

The workspace is disposable. Any clone can be thrown away and remade:

```powershell
Remove-Item -Recurse -Force workspace\ziptastic
.\scripts\sync.ps1
```

```bash
rm -rf workspace/ziptastic
bash scripts/sync.sh
```

The same move fixes the common failure of a `--ff-only` pull refusing because the clone has diverged.

## `PAT_TOKEN`

`.github/workflows/dispatch-sync.yml` dispatches workflows in *other* repositories. The default
`GITHUB_TOKEN` is scoped to the repository that runs the job, so it cannot do that: the workflow reads
a repository secret named **`PAT_TOKEN`**, a fine-grained personal access token with `Actions: write`
on `drsamonline/ziptastic` and `drsamonline/heavenzip`.

Set it in **Settings → Secrets and variables → Actions → New repository secret**. Without it the
dispatch steps fail with `Resource not accessible by integration`; the workflow itself stays green on
checkout, which is why the failure is easy to miss.

## What the workspace is not

- **Not a subtree.** `workspace/ziptastic/vendor/hcs` is ziptastic's own vendored copy, committed
  there. Do not add it as a submodule and do not `git subtree add` in compfactory — compfactory
  clones, it does not vendor.
- **Not shared state.** Editing `workspace/HCS` and then running `bump-hcs.ps1` pushes HCS's
  `main` into ziptastic, but nothing pushes HCS itself. HCS changes are committed and pushed from
  `workspace/HCS` in the normal way, first.
- **Not required for CI.** The three workflows here need a checkout and nothing else; the workspace
  is a local convenience.

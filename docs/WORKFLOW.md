# A day in the CHCE workspace

The four repositories are ordered by dependency, and the order is not negotiable:

**HCS** (sources) → **ziptastic** (engine, vendors HCS) → **heavenzip** (orchestrator, consumes
ziptastic's binaries). **compfactory** coordinates all three and ships no product.

Every task below starts from a synced workspace:

```powershell
.\scripts\sync.ps1          # or: bash scripts/sync.sh
```

## Add a source to HCS

```powershell
cd workspace\HCS
# vendor it under old/<id>/, add its row to SOURCES, add its licence text
git add -A; git commit -m "sources: <id>"
git push
```

HCS's `vendor-check` workflow proves the new source materialises on a clean checkout. Do not edit
`SOURCES` without the directory, and do not add a directory without the row: the checker compares the
two, and the failure it guards against is a manifest that describes a vault nobody can clone.

## Propagate HCS into ziptastic

```powershell
.\scripts\bump-hcs.ps1
```

That is `git subtree pull --prefix=vendor/hcs https://github.com/drsamonline/HCS.git main --squash`
followed by a push. The commit message begins `vendor: sync HCS`. Running it twice in a row is a
no-op the second time.

**This is a local step, not a workflow.** There is no `sync-hcs` workflow in ziptastic. If the vendor
copy needs refreshing and you are not at a Windows shell, do the same subtree pull by hand:

```bash
git subtree pull --prefix=vendor/hcs https://github.com/drsamonline/HCS.git main --squash \
  -m "vendor: sync HCS"
git push origin main
```

`ziptastic`'s `vendor-check` workflow then verifies that every pinned source under
`vendor/hcs/old/` materialises and that `scripts/check-vendor.sh` passes. It checks the *pins*, not
their freshness — a vendor copy that is months behind still passes, so the pull above is the thing
that keeps it current.

## Edit the engine

```powershell
cd workspace\ziptastic
# edit; build and test
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
ctest --test-dir build --output-on-failure
```

or, from compfactory, `.\scripts\build-all.ps1` for the build alone.

Then commit and push to ziptastic. `ci.yml` builds from cold and runs the full suite; `vendor-check`
proves the sources materialise. Both must be green before a release is tagged — and note that a
workflow file that GitHub's parser rejects produces a run with **no jobs and no failing check**, so a
commit page full of green ticks is not evidence that anything ran. Look at the run, not the ticks.

## Cut a ziptastic release

1. Bump `VERSION` in `CMakeLists.txt` (`project(ziptastic VERSION x.y.z ...)`). The CLI's version
   string is compiled from it, and CI reads the same line — one edit, not two.
2. Update `CHANGELOG.md` from the commits, not from memory.
3. Tag and push: `git tag vX.Y.Z && git push --tags`. The release workflow attaches the Linux binary
   and `SHA256SUMS`.

## Refresh heavenzip's binaries

heavenzip never builds a compressor; it spawns prebuilt ones. Its `bin/` is populated from ziptastic's
release assets:

```powershell
gh workflow run sync-binaries.yml -R drsamonline/heavenzip
```

or from the GitHub UI, or through compfactory's dispatch (below). The workflow downloads
`ziptastic*` from the latest release with `--clobber` and commits whatever it found. If `bin/` is
unchanged afterwards, the release had no matching asset — check the release page before assuming the
workflow ran.

## Dispatch from compfactory

`.github/workflows/dispatch-sync.yml` is the button for the two steps above that live in other
repositories:

```powershell
gh workflow run dispatch-sync.yml -f target=ziptastic    # verify ziptastic's vendor tree
gh workflow run dispatch-sync.yml -f target=heavenzip    # pull ziptastic binaries
gh workflow run dispatch-sync.yml -f target=both
```

It needs the `PAT_TOKEN` secret (see [WORKSPACE.md](WORKSPACE.md)). The ziptastic branch dispatches
`vendor-check.yml`, which **verifies**; it does not sync. Propagation from HCS is `bump-hcs.ps1`
above, and that is a deliberate boundary: a workflow that rewrites `vendor/hcs` and pushes to `main`
on a schedule is a machine that can rewrite the source vault unattended.

## The order, and why

| Step | Repo | Gate before the next step |
|---|---|---|
| 1 | HCS | `vendor-check` green; `SOURCES` matches `old/` |
| 2 | ziptastic | `bump-hcs` done; `ci` green; suite passes |
| 3 | heavenzip | a real ziptastic release exists and `bin/` is populated |

Do not start heavenzip work that assumes a real binary until step 3 is done. Phases 0–3 are the
exception: they run against a stub, so they are not blocked by ziptastic at all.

## When something is wrong

| Symptom | Cause | Fix |
|---|---|---|
| `run scripts/sync.ps1 first` | no `workspace/` | run the sync |
| `git pull --ff-only` refuses | the clone has diverged | delete the clone, sync again |
| dispatch step fails `set the GH_TOKEN environment variable` | `PAT_TOKEN` is not set at all — GitHub substitutes an empty string | set the secret; the workflow now fails at the first step and names it |
| dispatch step fails `Resource not accessible by integration` | `PAT_TOKEN` is set but lacks `Actions: write` on the target repository | rescope the token |
| a workflow run completes in 0 s with no jobs | the workflow file is invalid | fix the YAML; the commit page will still show green |
| `check-vendor.sh` red | a pinned source does not materialise | `git submodule update --init --recursive`, then check the pin has a URL |

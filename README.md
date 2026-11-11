# compfactory

[![License: PolyForm Noncommercial 1.0.0](https://img.shields.io/badge/license-PolyForm%20Noncommercial%201.0.0-blue)](LICENSE)
Development workspace for the **CHCE** multi-repo compression project — the repository that
coordinates `ziptastic`, `heavenzip` and the shared compression sources (`HCS`) rather than shipping
an app of its own. Three repositories and this coordinator; there is no fourth. `preflate` is not a
repository: it lives inside ziptastic as `src/precompressors/preflate_wrap.cpp`.

## What this repository is for

CHCE (Holistic Compression Sources) is four things that have to agree: a source vault (`HCS`), the
engine built from it (`ziptastic`), the orchestrator that chains prebuilt binaries (`heavenzip`), and
this coordinator. It holds the phase plan, the hard rules all of them follow, and the per-repo agent
prompts that keep the work in order.

## The rules that matter

- **Keep each repository single-purpose.** If a file does not belong here, it does not go here.
- **Follow the phases in order.** Each repository's `AGENT_PROMPT.md` lists them, and a phase's exit
  tests must pass before the next one starts.
- **A failed gate is a commit, not a silence.** `phase-<N>: FAILED — <reason>`, then stop and report.
- **`vendor/hcs/` is read-only.**
- **Offline at runtime.** No network calls, no downloads, no models.

## Why the architecture looks like this

`heavenzip` never opens a compressor. It spawns processes — which is why it can stay GPL-safe while
driving GPL tools: there is no linking, only process boundaries.

The full plan is in [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md); the per-repository instructions are in
each repository's `AGENT_PROMPT.md`. The workspace itself is documented in
[docs/WORKSPACE.md](docs/WORKSPACE.md) and a working day in [docs/WORKFLOW.md](docs/WORKFLOW.md).

## Phases

`AGENT_PROMPT.md` §8 is the six-phase plan. The rule the project sets for itself is that a phase's
exit tests pass before the next one starts, and that this table is updated after every phase — so it
is written down here rather than inferred from the tree.

| Phase | What it delivers | State |
|---|---|---|
| 0 | README, `docs/WORKSPACE.md`, `docs/WORKFLOW.md` | **Done** — the two documents exist and describe the scripts as written, including `PAT_TOKEN` |
| 1 | `sync.ps1` / `sync.sh` verified end to end | **Verified on Linux** (`sync.sh`: fresh clone, then a second run that pulls `--ff-only`); `sync.ps1` unrun — it needs a Windows shell |
| 2 | `bump-hcs.ps1` verified | **Unverified** — it needs `workspace/` from phase 1 and a Windows shell. Its subtree pull has not been run since the initial import |
| 3 | `build-all.ps1` verified | **Unverified** — Windows shell; on Linux the equivalent is `cmake -S workspace/ziptastic -B workspace/ziptastic/build` |
| 4 | `dispatch-sync.yml` verified | **Partly** — the ziptastic branch used to dispatch a workflow that does not exist (`sync-hcs.yml`); it now dispatches `vendor-check.yml`. The heavenzip branch is valid but has never been triggered |
| 5 | Polish: "Common tasks" in the README, script headers, `.gitignore` check | **Not started** |

`tests/check-scripts.sh` runs on every push and holds the one invariant all four scripts share: the
workspace lives at `../workspace` from `scripts/`, and `.gitignore` covers it.

## Support

<img src="docs/assets/support-portrait.jpg" width="72" height="72" alt="Dr. Sohil Momin" align="left" style="border-radius:50%;margin-right:1rem">

Free, offline, accountless — and staying that way. If it earned its keep:

| | |
|---|---|
| UPI (India) | `drsohilboi@ybl` — payee Dr. Sohil Momin, open amount, or scan [the QR](docs/assets/upi-qr.svg) |
| GitHub Sponsors | [github.com/sponsors/drsamonline](https://github.com/sponsors/drsamonline) |
| Ko-fi | [ko-fi.com/matneo](https://ko-fi.com/matneo) |
| PayPal | [paypal.me/drsohilmomin](https://paypal.me/drsohilmomin?locale.x=en_GB&country.x=IN) |
| My books | [Amazon author store](https://www.amazon.com/stores/author/B08ZT331LY/allbooks?ccs_id=aed72b9f-71d9-41dc-adee-e9368a317acc) |
| More apps | [drsamonline.github.io](https://drsamonline.github.io/) |
| Email | [sohilmomin2000@gmail.com](mailto:sohilmomin2000@gmail.com) |

Nothing is gated behind it: no accounts, no tracking, no network requests.

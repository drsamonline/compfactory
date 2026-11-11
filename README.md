# compfactory

[![License: PolyForm Noncommercial 1.0.0](https://img.shields.io/badge/license-PolyForm%20Noncommercial%201.0.0-blue)](LICENSE)
Development workspace for the **CHCE** multi-repo compression project — the repository that
coordinates `heavenzip`, `ziptastic`, `preflate` and the shared compression sources rather than
shipping an app of its own.

## What this repository is for

CHCE (Holistic Compression Sources) is four repositories that have to agree: a coordinator, a
container format, a recompressor, and the reference sources they are built from. This is the
coordinator — it holds the phase plan, the hard rules every one of the four must follow, and the
per-repo agent prompts that keep the work in order.

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
each repository's `AGENT_PROMPT.md`.

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

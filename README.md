# WaveCrux Beta

Welcome to the home of the **WaveCrux public beta** — this is where you report
bugs, request features, get help, and browse the test-fixture corpus WaveCrux is
validated against.

> **WaveCrux** is a modern, high-performance, multi-platform waveform viewer for
> HDL engineers — VCD / FST / GHW, protocol decoding, and animated signal
> visualization, on Linux, macOS, Windows, and the web.

**This repository contains no application source code.** During the public beta
the WaveCrux source is closed; this repo exists purely as the public meeting
point for the beta:

- 🐞 **[Report a bug](../../issues/new?template=bug_report.yml)** — or just use
  **Help → Submit Issue** inside the app (recommended; it attaches diagnostics
  for you — see below).
- 🧪 **[Submit a test fixture](../../issues/new?template=fixture_submission.yml)** —
  hand us a waveform that breaks a decoder and we'll fold it into the suite.
- 💡 **[Request a feature / share an idea](../../discussions/categories/ideas)** —
  in Discussions, so it can be discussed and upvoted.
- 🙋 **[Ask a question / get help](../../discussions/categories/q-a)** — in Discussions.
- 📂 **[Browse the test fixtures](fixtures/)** — *this is what WaveCrux tests
  against.* See [`fixtures/README.md`](fixtures/README.md).

> **Two places, clear split.** The **[Issues](../../issues)** tab is a work
> queue — **bugs and fixture submissions only**. Everything conversational —
> questions, feature ideas, announcements, show-and-tell — lives in
> **[Discussions](../../discussions)**, the single community hub for the beta.
> (No Discord or Slack — Discussions keeps every answer searchable and in one
> place.)

---

## Reporting a bug — the easy way

The best bug reports come straight from the app, because they carry the
reproduction context automatically:

1. In WaveCrux, open **Help → Submit Issue** (also in the command palette and the
   About box).
2. Pick which context to attach — app & environment, session state, a diagnostics
   snapshot, and (on desktop) a screenshot. App & environment is always on.
3. Hit **Submit**. WaveCrux copies a formatted report to your clipboard and opens
   a pre-filled new-issue form **in this repository**. Paste if needed, drag in
   the screenshot, and submit.

No private file contents, signal values, or file paths are included — only
counts, formats, and environment metadata. See the in-app privacy callout for
exactly what each toggle adds.

Prefer to file by hand? Use the [bug report form](../../issues/new?template=bug_report.yml).

## Getting help

**[GitHub Discussions](../../discussions) is the community hub** — it's where all
the conversation happens:

- **[Q&A](../../discussions/categories/q-a)** — questions, "how do I…", workflow tips.
- **[Ideas](../../discussions/categories/ideas)** — feature requests and suggestions, upvotable.
- **[Show and tell](../../discussions/categories/show-and-tell)** — share what you've built.
- **[Announcements](../../discussions/categories/announcements)** — updates from us.

**Bugs and crashes** → file an [Issue](../../issues) (above) instead, so they land
in the triage queue, not the discussion stream.

## What's in this repo

| Path | What it is |
|------|------------|
| [`README.md`](README.md) | This file. |
| [`docs/BETA_GUIDE.md`](docs/BETA_GUIDE.md) | How to join the beta, what to test, how feedback is handled, what you get for contributing. |
| [`docs/SUBMITTING_FIXTURES.md`](docs/SUBMITTING_FIXTURES.md) | How to contribute a waveform fixture (and the license rules). |
| [`fixtures/`](fixtures/) | The decoder + Stage test-fixture corpus WaveCrux is tested against. |
| [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/) | Bug / fixture issue forms (feature ideas go to Discussions). |

## After the beta

When WaveCrux opens its source post-beta, the canonical repository becomes
[`Ferrite-Engineering/wavecrux`](https://github.com/Ferrite-Engineering/wavecrux),
and the open-core test fixtures live there alongside the code. This beta repo is
archived at that point; the in-app issue reporter automatically retargets the
open repo. Until then, **everything happens here.**

---

*WaveCrux is built by [Ferrite Engineering](https://ferriteengineering.com).
Thanks for helping us make the beta better.*

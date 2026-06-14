# WaveCrux Public Beta — Participant Guide

Thanks for taking part in the WaveCrux public beta. This guide explains what the
beta is, how to get the most out of it, and how your feedback turns into a better
release.

## What the beta is

WaveCrux is in **free, all-features-unlocked public beta**. Every capability —
including the Pro decoders and the Pro Stage widget pack — is enabled for every
beta user, with no license key required. We want you to push on everything and
tell us where it breaks.

The application source is closed during the beta. This repository
(`wavecrux-beta`) is the public channel for bug reports, feature requests, help,
and the test-fixture corpus.

## Installing

Download the latest beta build for your platform from the WaveCrux website. Beta
builds self-identify in **About WaveCrux** (look for the beta badge and build
SHA — you'll want that SHA in bug reports, and the in-app reporter fills it in
for you).

Supported platforms: **Linux**, **macOS**, **Windows**, and **Web**.

## What's most useful to test

All feedback is welcome, but these areas move the needle most during beta:

- **Open your real waveforms.** VCD, FST, and GHW from your actual simulations —
  especially large files. Tell us about load time, memory, and any signal that
  renders wrong versus GTKWave.
- **Protocol decoding.** Bind the decoders (SPI, I²C, UART, AXI, USB, Ethernet,
  PCIe, CAN, JTAG, and more) to your buses and check the decoded transactions.
  A trace that decodes wrong is the single most valuable bug you can file — see
  [fixtures](../fixtures/) for the kind of traces we already test, and
  [SUBMITTING_FIXTURES.md](SUBMITTING_FIXTURES.md) to contribute yours.
- **GTKWave migration.** Import your `.gtkw` sessions and translate-filter files.
  Anything that doesn't carry over is a bug.
- **WaveCrux Stage.** Try the animated signal widgets against your buses.
- **Cross-platform + cross-window.** Resize aggressively, go full-screen, try a
  tablet or a narrow window, switch light/dark themes.

## How to report

### Bugs and crashes — from inside the app (best)

Use **Help → Submit Issue** (also in the command palette and the About box). It
assembles a report with your app version, platform, OS, locale, and an optional
diagnostics snapshot and screenshot, then opens a pre-filled new-issue form in
this repo. This is the highest-signal way to report, because the reproduction
context is captured automatically.

**Privacy:** the report never includes signal values, file contents, or file
paths — only counts, formats, and environment metadata. Each toggle in the
dialog shows exactly what it adds, and you see the full body before it's sent.

Filing by hand works too: [bug report form](../../issues/new?template=bug_report.yml).

### Feature requests

Use the [feature request form](../../issues/new?template=feature_request.yml).
Tell us the workflow you're trying to complete, not just the widget you want — it
helps us find the best solution.

### Questions and discussion

Use [GitHub Discussions](../../discussions). Keep crashes and defects in Issues
so they hit the triage queue.

## How feedback is handled

- Issues are triaged and labelled (`bug`, `beta-feedback`, platform). The in-app
  reporter applies these automatically.
- Reproducible reports — *especially ones with an attached fixture* — are
  prioritized, because we can turn them into a regression test.
- Fixture submissions that pass the license check are folded into the WaveCrux
  test suite, so the bug you found stays fixed.

## Contributor recognition

The beta runs on community help, and we don't take it for granted. Meaningful
contributions during the beta — solid reproducible bug reports, fixture
donations that expose real decoder/parser edge cases, translations, and
community help — are recognized when WaveCrux launches. Details of the
contributor program are announced on the WaveCrux website and in Discussions.

## After the beta

When WaveCrux opens its source, the canonical repo becomes
[`Ferrite-Engineering/wavecrux`](https://github.com/Ferrite-Engineering/wavecrux)
and the in-app reporter retargets it automatically. This beta repo is archived
at that point. Until then, everything happens here.

Thank you for helping shape WaveCrux. 🌊

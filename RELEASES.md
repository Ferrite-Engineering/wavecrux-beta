# WaveCrux Release Notes

All notable changes between beta builds. Download the latest build from
[wavecrux.app/download](https://wavecrux.app/download) or run it in the
browser at [app.wavecrux.app](https://app.wavecrux.app).

---

## 0.2.5 — 2026-07-14

- **The About box is a proper dialog on web.** In a desktop browser, About
  now opens as a modal dialog (matching the desktop apps) instead of the
  mobile full-screen slide-in. Phones and tablets keep the slide-in. Reach
  it on web via the command palette (Ctrl/Cmd+Shift+P → "About") or the
  toolbar's ☰ menu.
- **The version is now always visible.** The welcome screen shows the
  running version under its header — handy on web, where there's no native
  menu bar.
- Housekeeping: internal documentation and text cleanup.

## 0.2.4 — 2026-07-14

The gate-level hierarchy release: opening a scope with tens of thousands of
variables is now instant.

- **Signal tree virtualization.** The hierarchy renders as a flat lazy list
  that builds only the rows on screen, so expanding a scope costs the same
  whether it holds 40 variables or 64,000. On the 1.3-million-variable
  gate-level reference trace, expanding the 64k-variable scope dropped from
  a multi-minute frozen frame to ~70 ms, search stays responsive per
  keystroke, and scrolling deep into huge scopes is smooth. All hierarchy
  interactions (multi-select, ranges, context menus, drag-to-Stage) are
  unchanged.
- **Fixed: gate-level traces could crash the hierarchy on expansion.**
  Netlists can dump the same escaped identifier twice in one scope; row
  identity now tolerates duplicate names and aliased signals everywhere.
- **Web: no more "new version available" banner.** The web app updates
  itself on every deploy, so the download banner (which could appear briefly
  around releases) is gone on web. Desktop update notifications are
  unchanged.

## 0.2.3 — 2026-07-13

- **Fixed: "Apply Decoder to Selection…" picked the wrong signals on FST
  files with aliased nets.** FST traces report a net wired through module
  ports as multiple hierarchy entries sharing one underlying signal (e.g. a
  testbench `clk` and the DUT's `wb_clk_i`). Selecting signals in one scope
  could resolve to their aliases in another scope, so the decoder's
  configuration dialog listed names from scopes you never clicked and the
  auto-bind heuristic matched almost nothing. Hierarchy selection is now
  keyed by the row you actually clicked, everywhere: highlights, bulk add,
  decoder-from-selection, and format changes all operate on the exact rows
  selected. (Thanks to Kevin Laeufer for the report and the reproduction
  trace.)

## 0.2.2 — 2026-07-13

- **Clicking a signal in the hierarchy now highlights it** as the current
  selection (as well as adding it to the timeline). The highlight is also
  the visible anchor for Shift+click range selection — click a signal,
  Shift+click another, and the range grows from the highlighted row,
  matching the file-manager convention.

## 0.2.1 — 2026-07-13

Hotfix on top of 0.2.0.

- **Fixed: "Check for Updates" always failed.** A lifecycle bug made every
  update check — automatic and manual — report "Couldn't check for updates"
  in all previous builds. If you're on 0.1.0 or 0.2.0, the check now works
  again without any action on your part (a compatible server-side change
  covers existing installs), and this release fixes it permanently.
- Opening a file now shows the parsing overlay with the file's name on all
  platforms.

## 0.2.0 — 2026-07-13

A beta-feedback release: hierarchy workflow features requested by early
testers, plus a deep performance pass driven by a 1.3-million-variable
gate-level netlist (thanks to Kevin Laeufer — wellen's author — for the
feedback and the stress-test trace).

### New features

- **Multi-select in the signal hierarchy.** Ctrl/Cmd+click toggles rows,
  Shift+click selects the visible range, and the context menu gains
  **"Add N Selected to Viewer"** — signals land in tree order, and anything
  already on the canvas is skipped rather than duplicated.
- **Parameters show their values inline.** HDL parameters display their
  constant value directly in the hierarchy tree (`WIDTH = 8`), without
  adding them to the timeline.
- **Apply a decoder straight from a selection.** Select the signals of a bus
  in the hierarchy, right-click → **"Apply Decoder to Selection…"** — the
  decoder picker is scoped to your selection and the configuration dialog
  opens with channel bindings pre-filled by the name-matching heuristic
  (exact/prefix/alias/fuzzy, width-aware).

### Performance — gate-level scale

- A 1.3M-variable / 142k-scope gate-level FST now **opens in about a
  second natively** (the hierarchy build was accidentally quadratic; the
  underlying wellen engine was never the bottleneck — it parses the file in
  under 200 ms).
- The file-open watchdog now **scales with file size** instead of rejecting
  large-but-valid files after a fixed 5 seconds.
- **"Add All in Scope" at million-signal scale** is chunked and
  progress-indicated end to end, and the waveform canvas never does
  per-signal UI work proportional to the total count — only to what's on
  screen. Adding all 1.3M signals takes a few seconds, with live progress.
- **Web:** the browser now paints between signal decompressions, so
  progress indicators and incremental waveform fill-in are visible during
  large loads instead of the page appearing frozen.
- Session autosave of very large signal lists moved off the UI thread.

### Fixes

- Opening a file now shows immediate feedback — a tab with
  "Loading *filename*…" appears the moment the pick lands (previously the
  welcome screen sat unchanged for the whole parse of a large file).
- Fixed a console 404 on every web session (app-icon asset probing).
- Fixed a progress-indicator race that could hide the loading bar during
  bulk adds.

### Known limitation

- On the web, the spinner freezes *during* the parse itself: the WASM
  engine runs on the browser's main thread. Moving it to a Web Worker is on
  the roadmap if in-browser gate-level work turns out to be a common flow.
  Native builds are unaffected (parsing runs on a background thread).

---

## 0.1.0 — 2026-07-12

Initial public beta. Linux, macOS, Windows, and web. VCD / FST / GHW /
LXT / LXT2 support, eight protocol decoders (SPI, I²C, UART, AXI4-Lite,
APB, AHB-Lite, Wishbone, RISC-V instruction trace), waveform diff,
X-trace, FSM visualization, cocotb log correlation, GTKWave `.gtkw` and
translate-filter compatibility, WaveCrux Stage with the Rive widget SDK,
and four display languages (English, 简体中文, 日本語, 한국어).

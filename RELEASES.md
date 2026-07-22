# WaveCrux Release Notes

All notable changes between beta builds. Download the latest build from
[wavecrux.app/download](https://wavecrux.app/download) or run it in the
browser at [app.wavecrux.app](https://app.wavecrux.app).

---

## 0.3.0 — 2026-07-22

The DSP Scope release — three new signal-analysis Stage widgets — on top of a
week-long responsiveness and correctness pass across the whole viewer.

### New

- **DSP Scope: three new Stage widgets (Pro).** Point them at a numeric
  sample bus and watch it the way you would on bench equipment.
  - **Spectrum Analyzer** — magnitude-vs-frequency plus a rolling
    time × frequency spectrogram, with a peak marker and readout, a
    physical-Hz or normalized (f/fs) axis, and complex IQ input
    (real + imaginary bus) alongside plain real sample streams.
  - **X-Y / Constellation** — plot two sample buses against each other as a
    phosphor-decay Lissajous trail, or symbol-clock them into a constellation
    with density, persistence, and an optional ideal 4/16/64-QAM grid overlay.
  - **Eye Diagram** — fold a sampled serial line modulo one unit interval into
    a density-shaded eye, referenced to a recovered clock or a fixed period,
    with a mid-UI eye-height / eye-width measurement overlay.
- **A turnkey DSP demo.** A choreographed 200 ms capture and a preloaded
  session drop all three widgets onto one Stage panel, pre-bound: a chirping
  spectrogram, a QPSK → 16-QAM constellation that blooms into noise and
  clears, and a serial eye that closes at mid-timeline and reopens — all on a
  single time axis. Open it and press play.
- **Disabled shortcuts now tell you why.** Pressing a key for an action that
  isn't currently available used to do nothing at all, which reads as a broken
  keyboard. It now says what's missing — "Load a waveform file to use protocol
  decoders", and so on — resolved from the actual unmet precondition, so
  actions with several requirements name the one that's blocking you.
- **Unreachable CXP peers are visible.** The cross-probe panel gained an
  "Unreachable peers" section, so a one-way link — a peer that dialled you but
  that you can't dial back — no longer looks healthy.
- **Remote control speaks the WCP spec envelope.** The server now accepts the
  upstream Waveform Control Protocol envelope alongside WaveCrux's own dialect
  on the same port, advertises protocol version 0, and unifies the default port
  at 54321 across the suite. Batch commands are atomic — a partial failure adds
  nothing. It also starts on its own when you enable remote control, instead of
  waiting for the next launch.

### Faster

- **Clicking is instant again.** Signal-tree scope headers and Stage tab
  strips each sat behind a double-tap recognizer, so every single click waited
  out the ~300 ms double-tap window before anything happened. Both now respond
  the moment you release.
- **Pixel Stage widgets redraw incrementally.** The framebuffer, OLED, and
  character-LCD renderers re-emulated the entire capture from t=0 on every
  frame and drew one rectangle per pixel. They now resume forward from the last
  emulated time and blit an image, so scrubbing a long capture no longer gets
  progressively slower.
- **Spectrum, audio, and PS/2 renderers memoize their pipelines**, so a
  rebuild that changes nothing costs nothing.
- **Transaction lanes and hierarchy search scale.** Decoded-transaction
  painting now binary-searches the visible window and coalesces sub-pixel
  transactions into density columns — draw cost is bounded by lane width, not
  transaction count — and the signal-tree search filter no longer rescans each
  subtree once per level.
- **Long collaboration sessions stay light.** The recording buffer is bounded
  (structural events always kept, cursor moves progressively thinned), inbound
  cursor updates coalesce to one per frame, and the presenter's view
  composition is encoded once instead of per snapshot.

### Fixed

- **Three-or-more-party LAN sessions sync.** A LAN host didn't relay a
  client's frames to the *other* clients, so anything past a two-party session
  saw a partial picture.
- **Resizing the window could break open tabs.** Persisting window geometry
  replaced the workspace document wholesale, which tore down the live state of
  tabs that were still on screen — occasionally throwing mid-layout.
- **Decoder configuration lands in the right tab.** Both the "Add decoder"
  dialog and "Configure" from the transaction table could write their settings
  into whichever tab was active when the dialog opened rather than the one that
  launched it.
- **Resetting a lane height honours your setting.** Double-clicking a signal
  name reset the lane to a hardcoded 30 dp instead of the default from
  **Settings → Waveform Defaults**.
- **Decoders:** RGMII's automatic phase-mode detection now identifies an RX
  delay correctly (by matching the preamble); AXI4-Full collapses error storms,
  caps outstanding joins, and bounds overflow instead of flooding the lane;
  Avalon-ST no longer flags an undriven active-low error bus as an error; and
  payload display caps sit above real-world packet sizes.
- **The AI assistant survives a closed tab.** Closing a tab mid-conversation
  (or mid tool-use) now aborts the run cleanly instead of writing into a
  disposed tab.
- **Fixed: the update check could crash** when a response arrived after its
  dialog had gone away.
- **Japanese, Korean, and Chinese wording** got a full review pass —
  terminology (clock, signal, cross-probe, custom, history depth), punctuation,
  and dialog register are now consistent across the app.

## 0.2.7 — 2026-07-15

- **Import Verilator's elaborated AST for exact RTL source tracing**
  (desktop only). Run your design through `verilator --json-only`, then use
  **Tools → Import Verilator AST (JSON)…** and pick the `V<top>.tree.json`
  it emits (the sibling `.tree.meta.json` is found automatically). Because
  the dump is Verilator's own post-elaboration AST, generate loops arrive
  unrolled (`gen_blink[0]`, `gen_blink[1]`, …) and every mapping carries the
  exact per-instance path your waveform uses — accuracy the built-in
  source-tree parser can't reach. The result is also saved as a portable
  GTKWave-compatible `.stems` file, which matters more than it used to:
  Verilator 5.x removed the XML output that GTKWave's `xml2stems` consumed,
  so this import is the working replacement. (Thanks to Hong Ping Tan for
  the suggestion.)

## 0.2.6 — 2026-07-14

- **The hierarchy now sorts alphanumerically.** Numbered names order the way
  you'd expect — bit 2 before bit 11 — instead of the file's dump order
  (`[0] [1] [10] [11] [2]`), which is what gate-level netlists with
  bit-blasted names used to show. Scopes and signals both sort; range
  selection and bulk add follow the on-screen order; signals that share a
  name keep their relative file order. Prefer the file's declaration order?
  **Settings → Waveform Defaults → "Sort hierarchy alphanumerically"**
  switches back, live. (Thanks to Kevin Laeufer for the suggestion.)

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

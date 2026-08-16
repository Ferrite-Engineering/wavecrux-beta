# WaveCrux Release Notes

All notable changes between beta builds. Download the latest build from
[wavecrux.app/download](https://wavecrux.app/download) or run it in the
browser at [app.wavecrux.app](https://app.wavecrux.app).

---

## 0.8.0 — 2026-08-16

Waveform annotations. Notes anchored to the edges they describe, that survive a
re-simulation and tell you when they no longer hold — alone, or with two other
people looking at the same trace.

### New

- **Annotate a waveform.** Callouts, arrows, full-height bands and lane bands,
  each anchored to a `(time, signal)` pair rather than to pixels, so they stay
  glued to the edge they describe as you pan and zoom. Author them from the
  canvas, from a selected region, or from the two cursors; edit the text in
  place by double-tapping it. **Edit ▸ Add Annotation at Cursor** and
  **Annotate Selected Range** are the menu routes, and the **Annotations**
  panel lists every note in time order with its signal, tick and author.
- **A note that knows when it has gone stale.** Each annotation records the
  value the signal actually had when you wrote it. Re-simulate, reopen, and any
  note whose signal no longer does what it claimed flags itself as **drifted**
  instead of quietly going on asserting something the design stopped doing. The
  panel filters to drifted-only, which is the review you want after a change.
- **Notes belong to the file, not to the tab.** Close a tab, reopen the same
  waveform days later, and your annotations are still on it.
- **Send an annotated waveform as one file.** **File ▸ Share Annotated
  Waveform…** writes a `.wavecruxpack` — the notes, the slice of the trace they
  refer to, and a rendered preview, in a single self-contained file small enough
  to email. The recipient opens it and sees exactly what you were looking at,
  with no access to your filesystem and nothing to reconstruct. The preview is
  also written beside the pack as a `.png`, so the image is there to paste into
  the ticket or the mail body without unpacking anything.
- **Open a pack in the browser.** [app.wavecrux.app](https://app.wavecrux.app)
  now opens a `.wavecruxpack` directly — pick it or drop it on the window.
  Somebody who was sent one can read the review without installing anything.
- **Walk somebody through a trace.** `[` and `]` step through the notes in the
  order the events happened, centring each one; there is a play control for an
  unattended run. A recorded argument, in sequence, instead of a screenshot with
  an arrow drawn on it.
- **Annotate together, live** (Enterprise). Everyone in a collaborative session
  sees everyone else's notes appear as they are written, colour-coded by author.
  Joining is by host approval, WAN sessions are end-to-end encrypted so the
  relay carries ciphertext it cannot read, and a peer that dies without
  disconnecting cleanly now leaves the roster on its own. When the session ends
  you choose what to keep.
- **Write up the meeting.** **File ▸ Export Review Minutes…** turns a session's
  annotations into a document you paste into a ticket — every note with its
  signal and time in the file's own timescale, deduplicated so an edited note
  appears once as it ended up, and one that was deleted does not appear at all.
  Markdown or CSV, and it works after the session has ended, which is when
  minutes actually get written. **Export Session Recording…** sits beside it
  with the raw event log for an audit trail.
- **A new Stage widget: the Elevator** (Pro). A lift car, doors, call buttons
  and floor indicator driven straight from your controller's signals — the
  canonical FSM teaching design, animated from the trace instead of read out of
  a state-encoding table.

### Fixed

- **A double-clicked waveform now opens on macOS.** WaveCrux has always
  registered as the handler for `.vcd`, `.fst`, `.ghw`, `.wavecrux` and
  `.wavecruxpack` — the files carry the icon — but a double-click, an `open -a`
  or a drag onto the Dock icon did nothing at all. Files only arrived if they
  were passed on the command line.
- **An exported image now looks like the app and contains what it draws.** PNG
  and SVG exports of "All Signals" rendered every lane in the same colour, and
  annotations fell outside the exported area.
- **Opening a file no longer breaks on macOS.** A file-picker dependency
  update turned every Open File into a plugin error; backed out and pinned, in
  all four products.

### Also

- Other performance and quality enhancements.

---

## 0.7.1 — 2026-08-11

Bring-your-own-ISA gets the piece it was missing: a way to install a table
without building WaveCrux from source.

### New

- **Point WaveCrux at your own encoding tables.** **Settings → Extensions → ISA
  encoding tables** takes a directory of TOML tables and WaveCrux decodes your
  core's instruction stream with them — a custom sequencer, a VLIW accelerator,
  a teaching CPU, any instruction set you can describe. `WAVECRUX_ISA_PATH`
  does the same for CI and shared team checkouts. The panel reports what
  actually loaded and names any file that failed with the offending key,
  because the question while authoring a table is never what you typed into
  settings — it is whether the file parsed. Open Core, for any instruction set;
  the format is documented in `docs/ISA_TABLE_AUTHORING.md`.

### Fixed

- **A mistyped field type is now an error instead of wrong output.** In this
  format a part's type is either a builtin or the name of a mapping table, so a
  typo is not a syntax error — it became a reference to a mapping that does not
  exist, and the disassembly rendered a raw number where a register name
  belonged. Along with two others of the same kind: a table whose slices do not
  account for every bit of the instruction word is rejected rather than
  silently mis-reading every field after the gap, and schema errors now name
  the file they came from.

### Also

- Other performance and quality enhancements.

---

## 0.7.0 — 2026-08-11

A release about reading a trace in the design's own units: datapaths drawn as
curves instead of hex, UART timing stated the way an HDL testbench states it,
instruction streams for cores that are not RISC-V, and switching activity
handed off to a power tool. Alongside it, one small file that opens a design in
all four Crux products at once.

### New

- **One file opens a design in all four products.** Write a `.crux-project`
  manifest at the root of your design — naming the dump, the RTL, the lint
  project and the regression config — check it in next to the RTL, and open it
  in any Crux product. Each one opens the part it owns; WaveCrux loads the
  `waveform` artifact. All four derive the same design identity from it, so
  cross-probing between them works exactly as it does when you open each file
  by hand. Every path resolves against the manifest's own directory, so the
  file travels with the repository, and everything except `version` is
  optional. Open Core in all four products.
- **Draw a bus as an analog curve.** Right-click a signal — in the signal list
  or in the value column — and choose **Render as analog** to plot a
  fixed-point or floating-point datapath instead of reading it as hex. The
  toggle is deliberately separate from the display format: the format says what
  number the bits are, the toggle says how to draw it. Unknown and
  high-impedance stretches render as gaps rather than as zero, Gray code is
  decoded before plotting, and a `.gtkw` session that marks a trace analog
  imports already switched on. Pro adds the ML float formats (bf16, FP16, FP8
  E4M3/E5M2).
- **UART bit timing, stated three ways.** UART has no clock on the wire, so the
  decoder has to be told how long a bit lasts — and the natural unit depends on
  where the trace came from. Choose **baud rate** for a captured trace,
  **clocks per bit** for a simulation (bind your design's clock and enter the
  same `CLKS_PER_BIT` constant the RTL uses; WaveCrux measures the period from
  the trace), or **auto-detect from the line** when you know neither.
- **SAIF switching-activity export.** **File → Export…** now offers SAIF
  alongside VCD, PNG and SVG, over the same signal and time-range choices as a
  VCD export. It is the half of a power calculation that requires actually
  running a simulation — time at 0, 1, `x` and `z` per bit, plus toggle counts
  — in the format PrimePower, Joules and PowerArtist read. WaveCrux does not
  estimate power and this is not a power report.
- **Bring your own ISA.** Point WaveCrux at a TOML encoding table and it
  decodes your core's fetch stream as instructions. The loader, the schema and
  the diagnostics are Open Core, for any instruction set you like, and RISC-V's
  own tables stay free.
- **The curated ISA pack — MicroBlaze and LatticeMico32 (Pro).** 137 and 57
  instructions, derived from and checked against GNU binutils rather than
  transcribed from a manual, then verified across tens of thousands of
  instruction words — every operand, register for register. A handful of
  instructions in each are deliberately absent rather than approximated,
  chiefly the control-and-status-register accesses, where an approximate decode
  would name the wrong control register.
- **RISC-V pseudo-instructions (Pro).** The same fetch trace reads `mv a0, a1`,
  `nop`, `ret` and `li a0, 42` instead of the `addi`/`jalr` forms they assemble
  to. Curated from Table 25 of the Unprivileged ISA manual, because the hard
  part is precedence — `addi rd, x0, 0` is simultaneously a valid `li`, `mv`
  and `nop`, and only the specification says which one to print.

### Fixed

- **Cross-probe lands on the right wire.** The inbound matcher took the
  trailing segment of a peer's hierarchical path and broke ties by shortest
  path, which picks the *parent's* net whenever a submodule port name also
  exists in the parent — the common case, not the corner. It never failed
  loudly; it answered confidently and sometimes wrongly. Matches are now ranked
  by how much of the scope agrees. Measured against picorv32 across 229 nets:
  86.0% exactly correct with eight wrong wires, to 95.2% with none.
- **AXI4 reconstructs out-of-order and interleaved traffic (Pro).** Write
  responses were completing whichever burst was at the head of the queue rather
  than the one naming that BID, and read beats ignored `rid` entirely, so
  interleaved reads from two IDs were concatenated into a single burst with
  fabricated data. Both now route by ID; a response naming an ID with nothing
  outstanding is reported rather than silently consuming an unrelated burst.

### Also

- **Android release builds can reach the network.** The Flutter template
  declares the `INTERNET` permission for debug and profile builds only, so the
  release APK shipped without it and the in-app update check could never
  succeed — silently, because it swallows its own errors.
- Other performance and quality enhancements.

---

## 0.6.0 — 2026-08-04

A RISC-V release. WaveCrux now understands RVFI — the RISC-V Formal Interface
that cores expose for verification — and can tell you not just what your core
committed, but where it disagreed with the specification. Around that sit a
new family of Stage widgets built for core designers, and a hand-off from
SimCrux that drops you on the exact cycle a proof failed.

### New

- **RVFI Commit Inspector.** Point WaveCrux at a core exposing an RVFI port and
  get a per-commit view of what actually retired: instruction, decoded
  operands, register writeback, memory access, and trap state. Six consistency
  rules run over the stream and flag commits that contradict the interface's
  own contract — the kind of thing that otherwise surfaces days later as a
  mystery mismatch. Pointed at a real Ibex trace during development, the
  checker found two genuine deviations.
- **A Stage widget family for core designers.** The **Pipeline Diagram**
  renders instructions moving through your pipeline stage by stage, and is
  architecture-neutral — it works on any design whose stages you can bind. Pro
  adds four more: the **Tag-Tracked Pipeline Diagram** for superscalar,
  out-of-order and SMT designs; a **CSR & Trap Inspector** that decodes control
  and status registers bitfield by bitfield so you can check them against the
  spec; a **Branch-Predictor Scoreboard** that reports the hit rate and, just
  as importantly, the three ways its denominator can fail to exist; and
  **Cycle Accounting**, which shows where the cycles went and states plainly
  what the number is divided by.
- **SimCrux hands you the failing cycle.** When a SimCrux formal proof or
  regression produces a counterexample, opening it in WaveCrux now lands you on
  the exact step that failed, with the relevant signals already on the canvas —
  not merely somewhere in the same trace.
- **Two example sessions you can open immediately.** No capture, no toolchain:
  open them from the welcome screen and there is a waveform in front of you.

### Fixed

- **Zoom-out stops at the trace**, instead of continuing to a useless one tick
  per pixel.
- **The cross-probe landing scrolls into view.** It was being selected in the
  list without being brought on screen.
- **RISC-V immediates decode against the documented schema**, not an assumed
  one — affecting some instruction operand displays.
- **Resizable Stage widgets stop clipping their own contents.**
- **The pipeline grid's horizontal scroll has a visible scrollbar.**
- **Counts read correctly in every language.** The plural handling sweep is
  now closed out across the RISC-V, Stage and core UI.

### Also

- **Linux requirements are now measured, not asserted.** Our published glibc
  figure had drifted from what we actually shipped; every release build now
  verifies it. WaveCrux's Linux build requires glibc 2.38 (Ubuntu 24.04+,
  Fedora 39+, Debian 13+) because of a third-party graphics dependency, and it
  will not run on RHEL / Rocky 9 — see
  [issue #10](https://github.com/Ferrite-Engineering/wavecrux-beta/issues/10)
  for the detail and the upstream fix we are waiting on. NetCrux, LintCrux and
  SimCrux need only glibc 2.34 and do run there.
- Other performance and quality enhancements.

---

## 0.5.0 — 2026-07-31

A Stage release. The headline is a second curated Rive widget for the Stage —
a full traffic-light intersection — alongside a Stage that finally has one
obvious place to drive playback from. Underneath it, the four apps took a
concerted pass at looking and behaving like one product.

### New

- **Traffic Light Intersection — a new Stage widget.** A signed, curated Rive
  widget that renders a full intersection: vehicle aspects, pedestrian walk,
  and flash mode, driven straight from your design's signals. Bind the aspect
  codes and the boolean levels, scrub the waveform, and watch the intersection
  step through its states. It joins the tachometer as the second curated Pro
  Stage widget, and went through two rounds of designer refinement so the
  ambient motion keeps running independently of state changes.
- **One playback transport for the Stage.** Stage playback is now driven from
  a single set of dock-strip actions, replacing the panel row and the separate
  toolbar glyph that used to compete for the same job.
- **Turning the Stage on gives you a Stage.** Enabling it seeds a default
  panel instead of dropping you on a create-something-first empty state.
- **The toolbar shows your CXP peer count**, so you can tell at a glance how
  many sibling apps are connected.

### Fixed

- **Quit works from every route.** The menu item did nothing on some screens.
- **The APB decoder accepts any address-bus width** when binding `paddr`,
  instead of insisting on one width.
- **The BLDC Stage widget holds the rotor still** while playback is paused,
  rather than drifting.
- **Loading overlays no longer clip their action button** in a short pane.
- **The web app no longer hangs on startup** — a desktop-only integration path
  was running in the browser.

### Also

- **One consistent suite.** The menu bar, toolbar, status bar and Settings are
  now shared components across all four apps, and panels moved to a
  VS Code-style dock model: bottom, right and left regions, tabs you can drag
  between docks, restore bars for collapsed regions, and direction-aware hide
  controls. The welcome screen gained an animated app logo and now shows the
  running version — handy in the browser, where there is no menu bar to check.
- Other performance and quality enhancements.

---

## 0.4.0 — 2026-07-28

The suite release. WaveCrux 0.4.0 ships alongside the first public betas of
its three sibling apps — **NetCrux** (schematic / netlist exploration),
**LintCrux** (lint triage), and **SimCrux** (regression running) — and almost
everything in this build is about making the four apps work as one tool:
cross-probing got a ground-up reliability pass, exercised end-to-end against
real designs until every direction between every pair of apps behaved.

### New

- **Cross-probe with the rest of the suite.** Click a net in NetCrux's
  schematic, a violation in LintCrux, or a failing test in SimCrux, and the
  corresponding signal lands in WaveCrux — added to the canvas, selected,
  and revealed in the hierarchy, visibly. The Cross-Probe panel is now the
  shared suite component, with per-peer send, an auto-send toggle for your
  live selection, and a ⇧⌘X / Ctrl+Shift+X shortcut. Clicking a signal's
  name on the canvas now selects it, so what you send is always what you
  see.
- **Every cross-probe send is acknowledged.** An explicit send now waits for
  the receiving app's answer and tells you what happened — highlighted,
  rejected (with the peer's reason), or no response — instead of silently
  doing nothing. WaveCrux's own sends also carry the signal's canonical
  hierarchical path rather than an internal handle, so peers can actually
  resolve them.
- **Inbound cross-probes open what they need.** If the target waveform isn't
  open, WaveCrux opens it; if it's already open in a background tab, that
  tab is activated instead of a duplicate opening. This completes the
  **Debug in WaveCrux** handoff from SimCrux: a failing test's captured
  waveform opens with the test's scopes expanded onto the canvas and its
  primary signal selected.
- **Suite-consistent window chrome.** The title bar and the bottom status
  bar are now the shared suite components, so layout, typography, and
  behavior match across all four apps.
- **Linux feels installed.** The AppImage offers desktop integration on
  first run (menu entry and icon), and the app icon now appears in the
  dock / taskbar instead of the generic placeholder.

### Fixed

- **Intermittent crash on launch (macOS).** A threading race in Flutter's
  accessibility bridge could crash the app a few seconds after launching
  from Finder. All four suite apps now opt out of the merged UI/platform
  thread mode that triggered it.

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

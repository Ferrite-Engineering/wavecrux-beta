# WaveCrux Examples

**This is what a WaveCrux window looks like once it's set up.** Each directory
here is a complete saved session — signals picked and grouped, value formats
chosen, decoders bound to pins, Stage widgets configured — committed next to
the trace it reads. We publish them so the first thing you see isn't an empty
window: open one file and you're looking at a working WaveCrux, then take it
apart to see how it was put together.

> ⚙️ **This tree is generated.** It's mirrored out of the WaveCrux source tree
> by tooling — don't edit it here. If an example is wrong, stale, or you'd like
> a different one, open an [issue](../../issues) or say so in
> [Discussions](../../discussions).

## Opening one

Launch WaveCrux, then **File → Open File** (`Cmd/Ctrl+O`) and pick the
`.wavecrux` file inside one of the directories below. There is no separate
"open session" command — the file picker accepts `.wavecrux` alongside `.vcd`,
`.fst` and `.ghw`, and WaveCrux recognizes the session, restores the layout,
and opens the trace named inside it in one step.

Each session names its trace by a path **relative to its own directory**, which
is why these work from any checkout on any platform with nothing to edit. Keep
the `.wavecrux` and its `.vcd` next to each other and the session travels; move
one without the other and it won't open.

| Example | What it demonstrates |
|---|---|
| [`five-buses/`](five-buses/five-buses.wavecrux) | Five protocol decoders — SPI, I²C, UART, AXI4-Lite and APB — decoding five independent buses in one 60 µs trace, simultaneously, with the **Transactions** panel already populated. |
| [`pipeline-diagram/`](pipeline-diagram/pipeline-diagram.wavecrux) | Stage: a Pipeline Diagram tile that reconstructs a classic five-stage in-order pipeline out of plain `valid` / `stall` / `flush` pins, shown beside the raw lanes it was built from. |

**Both are open core.** Every decoder and every widget these sessions use is in
the free tier — they don't depend on the beta unlocking the Pro tiers, and they
will keep working unchanged after the beta ends.

**Neither needs a toolchain.** No simulator, no cross-compiler, no plugin to
build, no network. The traces are committed here beside the sessions.

## `five-buses/` — five decoders at once

The five buses are five sibling scopes in one dump (`spi_tb`, `i2c_tb`,
`uart_tb`, `axi4lite_tb`, `apb_tb`) — the "one file, several unrelated
interfaces" shape a real testbench actually produces.

1. The **Transactions** panel is already populated. Five decoder instances are
   stored in the session and re-run against the trace the moment it opens.
2. Click any row: the cursor jumps to that transaction and the waveform scrolls
   to meet it.
3. The **APB** group opens collapsed while the other four are expanded —
   collapsed/expanded state is part of the session, not a fresh default. Click
   the group header to expand it.
4. The AXI4-Lite address and data lanes are set to hexadecimal while the
   handshake lanes stay binary. To change one, right-click its row in the
   **Values** panel and pick **Display Format**; the waveform and the value
   column both follow.

One detail worth keeping: `uart_tb` runs at **1 Mbaud**, not the 9600 default,
and the session carries that parameter. Point a fresh UART decoder at this
trace with default settings and it finds nothing at all — which is the single
most common reason a real UART decode comes up empty, and cheaper to learn here
than on your own design.

## `pipeline-diagram/` — a Stage panel

1. The session opens with one Stage panel in the bottom dock. Its tab reads
   **Pipeline** — Stage tabs carry the panel's own name, and this session named
   it — and it holds a single Pipeline Diagram tile. Rows are in-flight
   instructions, columns are cycles, and each cell is the stage that
   instruction occupied on that cycle.
2. Click a cell. The cursor moves to that cycle, and the raw `stage*_valid` /
   `stage*_stall` / `stage*_flush` lanes on the left show you the bits the cell
   was derived from.
3. The trace contains a stall and a flush — both show up as a *shape* in the
   grid rather than as a number you have to go looking for.

The widget is architecture-neutral. Its id is the bare `pipeline`, there is no
ISA content in it, and the stage names `IF` / `ID` / `EX` / `MEM` / `WB` are
free-text configuration you overwrite for your own design. It's set up for the
classic five-stage pipeline here only because that's the shape most people
recognize on sight.

Its instruction-tracking model is a shift register: right for a single-issue
in-order core, wrong for anything wider. The widget checks its own model
against the observed `valid` bits every cycle and raises a banner when they
disagree, rather than drawing a plausible lie.

## Where the traces come from

Both `.vcd` files are copies of traces already in the WaveCrux test suite, and
a test in the source repo fails if either copy drifts:

- **`pipeline-diagram.vcd`** is byte-identical to
  [`fixtures/open-core/protocol/riscv/generated/riscv_pipeline_5stage.vcd`](../fixtures/open-core/protocol/riscv/generated/riscv_pipeline_5stage.vcd),
  published in this repo — so you can compare the picture the widget draws
  against the expectations the pipeline reconstruction is tested to meet.
- **`five-buses.vcd`** is emitted by a generator that splices the five
  single-bus decoder fixtures — [`spi`](../fixtures/open-core/protocol/spi/),
  [`i2c`](../fixtures/open-core/protocol/i2c/),
  [`uart`](../fixtures/open-core/protocol/uart/),
  [`axi4lite`](../fixtures/open-core/protocol/axi4lite/) and
  [`apb`](../fixtures/open-core/protocol/apb/) — into one dump with the VCD
  identifier codes remapped so no two buses collide. Decoding each bus out of
  the combined file has to reproduce its single-bus expectations exactly; that
  is the point of the fixture and what the test checks.

The copies live here rather than under [`fixtures/`](../fixtures/) on purpose.
A corpus and an invitation are different things, and a directory named
"fixtures" reads as internal scaffolding to someone opening WaveCrux for the
first time.

## Not here yet

WaveCrux also ships two decoder-plugin demonstrators — a 1-Wire decoder written
against the plugin C ABI, and the same plugin in Rust. Those are source you
compile rather than sessions you open, and the C one builds against the ABI
header that lives with the application source, so they're not in this repo.
They land alongside the code when WaveCrux opens its source after the beta.

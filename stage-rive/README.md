# Stage custom widget — Tachometer gauge (Rive)

A ready-to-load **custom Stage widget** so you can try WaveCrux's animated
signal-visualization capability without authoring anything first. It's a
Rive-backed tachometer: a needle driven by an RPM signal, a redline zone that
glows when asserted, and an amber shift-light that flashes on each rising edge.

> The Stage custom-widget capability is **free / open core** — anyone can load
> and run `.wcrux-widget` bundles (no Pro license required). Only the curated
> Pro widget *pack* is a paid add-on.

## What's here

| File | What it is |
|---|---|
| `community-gauge.wcrux-widget` | The loadable widget bundle (a manifest + a Rive `.riv`, zipped). Loads as **Community Gauge** in the picker. |
| `gauge-demo.vcd` | A tiny demo waveform whose signals are named `rpm`, `redline`, and `shift` so the bindings are obvious. |

## Try it (≈ 1 minute)

1. **Install the widget.** In WaveCrux: **Settings → Custom Widgets → Load
   widget bundle…**, then pick `community-gauge.wcrux-widget`. It appears in the
   loaded-bundles list with no error.
2. **Open the demo waveform** `gauge-demo.vcd` (File → Open, or drag it in).
3. **Add the widget.** Open a **Stage** panel (desktop/tablet) → **Add Widget**
   → **Community Gauge** (under *Instrument*).
4. **Bind the three pins** — they line up by name with the demo's signals:
   - `rpm` → `rpm`
   - `redline` → `redline`
   - `shift` → `shift`
5. **Scrub the timeline.** You should see:
   - the **needle sweep** the full dial as `rpm` ramps 0 → 255,
   - the **redline arc glow** once `rpm` enters the upper range (`redline` high),
   - an **amber flash** pop on each `shift` pulse — including one inside the
     redline zone near the top.

Remove it any time via **Settings → Custom Widgets → Remove**.

## Author your own

This widget is just a manifest + a Rive artboard whose state-machine inputs
(`rpm` Number, `redline` Boolean, `shift` Boolean) match the manifest's signal
bindings. The full authoring guide — Rive contract, manifest schema, normalizers,
and packaging — is at **<https://docs.wavecrux.com/docs/authoring-rive-widgets>**.

Found a bug or have an idea? See the repo root
[`README.md`](../README.md) for where to file it.

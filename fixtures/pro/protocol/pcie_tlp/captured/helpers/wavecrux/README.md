# PCIe TLP captured-fixture helpers (own exerciser)

The PCIe TLP captured fixture (`wavecrux_pcie_tlp_exerciser.fst`)
exercises an in-house pure-Verilog TLP-stream exerciser
(`tb_pcie_tlp_exerciser.v`, SPDX `CC0-1.0`) emitting four canonical
TLP packets on the 32-bit DW AXIS-style interface that the wavecrux
Pro PCIe decoder consumes. The packet shapes follow the public PCIe
Base Specification (PCI-SIG, §2.2 TLP header formats).

Same rationale as the Avalon and JTAG exercisers — Corundum's TLP
layer is buried inside a multi-thousand-line FPGA SoC under
Apache-2.0 (allow-listed) but too coupled to be vendored as a
self-contained testbench; the simpler path is a CC0-1.0 in-house
exerciser of the documented packet formats.

## Files committed here

- `tb_pcie_tlp_exerciser.v` — CC0-1.0 master that emits:
  1. **MWr32** — Memory Write 32-bit, address `0x10000000`, payload `0xDEADBEEF`
  2. **MRd32** — Memory Read 32-bit, address `0x20000000`, tag `0x06`
  3. **CplD** — Completion with Data, status `SC` (Successful Completion),
     byte count `4`, requester tag `0x06`, payload `0xCAFEBABE`
  4. **CfgWr0** — Configuration Write Type 0, target ID `02:00.0`,
     register `0x001`, payload `0x00000506`
- `Makefile` — `make` builds + runs; `make install` mirrors the FST
  into both fixture trees.

Each TLP is emitted as SOP on the first DW, body DWs, EOP on the last
DW, with `tlp_valid` deasserted for two cycles between packets.
`tlp_ready` is held high (no backpressure exercised here — the
generated/ corpus covers tlp_ready throttling).

## Decoded stream

| t (ns)        | Decoded                | Notes                                                       |
|---------------|------------------------|-------------------------------------------------------------|
| 55  → 85      | `MWr32 0x10000000 ×1`  | data `0xDEADBEEF`, requester `01:00.0`, tag `0x05`, first BE `1111` |
| 115 → 135     | `MRd32 0x20000000`     | tag `0x06`, requester `01:00.0`                             |
| 165 → 195     | `CplD [SC] ×1`         | byte_count `4`, requester tag `0x06` (matches MRd), data `0xCAFEBABE` |
| 225 → 255     | `CfgWr0 reg=0x001 ×1`  | target_id `02:00.0`, requester tag `0x07`, data `0x00000506` |

The MRd → CplD pair is a complete read-completion round trip, with the
completion's requester tag matching the original MRd's tag. The CfgWr0
register decode `0x001` corresponds to the second DW (Command/Status)
of PCIe configuration space.

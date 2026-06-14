# USB 2.0 captured-fixture helpers (ulixxe/usb_cdc host emitters)

The USB 2.0 captured fixture (`ulixxe_usb_cdc_host_tx.fst`) exercises
the wavecrux Pro USB 2.0 decoder against real Full-Speed (12 Mb/s) USB
packets emitted by the host-side TX tasks from
[ulixxe/usb_cdc](https://github.com/ulixxe/usb_cdc) (MIT). The TX
tasks (`usb_tasks.v` + its includes) generate NRZI-encoded,
bit-stuffed, CRC-computed packets byte-for-byte per the USB 2.0 spec.

## Files committed here

- `usb_tasks.v`, `usb_rx_tasks.v`, `sim_tasks.v` — vendored verbatim
  from ulixxe/usb_cdc commit `6798bf42` (`examples/common/hdl/`, MIT).
  Provide PID constants, CRC5/CRC16 functions, NRZI encoder with bit
  stuffing, and `usb_tx` / `handshake_tx` / `token_tx` / `sof_tx` /
  `data_tx` tasks.
- `tb_usb_cdc_host_tx.v` — our 0BSD testbench. Wires `dp_force` /
  `dn_force` through pull-up/pull-down to `dp_sense` / `dn_sense`,
  declares the constants the vendored tasks expect (`MAX_BITS`,
  `MAX_BYTES`, `BIT_TIME`, `errors`, `warnings`, `power_on`, a dummy
  `USB_CDC_INST` hierarchy so the unused `test_*` tasks compile),
  and walks the packet sequence:
    1. SOF for frame `0x123`
    2. SETUP token to address 0, endpoint 0
    3. DATA0 carrying the 8-byte GET_DESCRIPTOR(DEVICE) setup packet
       (bmRequestType=0x80, bRequest=0x06, wValue=0x0100, wIndex=0,
       wLength=0x0040)
    4. ACK handshake
- `Makefile` — `make` builds + runs; `make install` copies the FST
  into both fixture trees.

Rebuild: `cd helpers/ulixxe && make && make install`.

## Decoded stream

| t (ns)         | Decoded                                    | Notes                                                              |
|----------------|--------------------------------------------|--------------------------------------------------------------------|
| 1743 → 4648    | `USB SOF · frame=291`                      | `0x123 = 291` ✓                                                    |
| 5395 → 8300    | `USB SETUP · addr=0x00 ep=0`               | addr=0, ep=0 ✓ (default control endpoint)                          |
| 8549 → 16766   | `USB DATA0 · 8 B: 0x80 0x06 0x00 0x01 ...` | exactly the GET_DESCRIPTOR(DEVICE) setup packet                    |
| 17015 → 18592  | `USB ACK`                                  | handshake terminator                                                |

## bit_period_ticks parameter

The fixture pins `bit_period_ticks: 83000` explicitly in the
`fixture.json` rather than letting the decoder auto-derive. The
testbench's `bit_time = 1000.0 / 12.0` ns gets rounded to 83 ns by
iverilog's integer-`time` semantics; the FST timescale is 1 ps, so
each bit spans 83 000 ps. Auto-derivation from `bus_speed = full`
would produce 83 333 ps, which differs by 0.4% — within real-world
USB tolerance but enough to confuse the decoder's strict SE0 EOP
window. Pinning the actual rounded value lets the decoder track the
trace exactly.

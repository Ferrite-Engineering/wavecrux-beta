# Bus Dashboard fixtures

Hand-crafted VCDs used by the Pro SPI/I²C Bus Dashboard service tests.
Each VCD has a companion `.expected_entries.json` documenting the
`BusDashboardEntry` rows the service must produce when the bound
signals are decoded with the dashboard's default configuration.

| Fixture | Protocol | Scenario |
|---|---|---|
| `spi_eight_bytes.vcd` | SPI mode 0, MSB first, 8-bit | Single CS-framed transfer of 8 MOSI bytes (0x00..0x07) with no MISO bound. |
| `i2c_write_then_read.vcd` | I²C 7-bit | Two separate transactions to 0x50: a write of `0x00 0x01`, then a read of `0xAA 0xBB`. |
| `i2c_nack.vcd` | I²C 7-bit | Address-phase NACK at 0x42 (no slave responds) — exactly one error row. |

The fixtures are committed alongside the dashboard's service tests so
the round-trip "VCD → decoder → BusDashboardEntry" path is verifiable
without requiring any external simulator.

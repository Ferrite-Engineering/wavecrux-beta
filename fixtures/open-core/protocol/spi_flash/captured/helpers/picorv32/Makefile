# Rebuild the captured SPI-Flash fixture.
#
# Produces picorv32_spiflash_single_wire.fst by simulating Claire Wolf's
# `spiflash` behavioral flash model (vendored verbatim from picorv32's
# picosoc/, ISC) driven by a single-wire-only testbench we author here
# under SPDX 0BSD. The custom testbench replaces upstream's
# `spiflash_tb.v`, which mixes single-wire SPI with quad / DDR-quad reads
# that the WaveCrux SPI-Flash decoder (single-wire only) cannot decode.
#
# Sequence: Reset (0xFF) → Power Up (0xAB) → READ (0x03) at 0x100000
# with 8 data bytes. `firmware.hex` places the byte sequence
# `93 00 00 00 93 01 00 00` at offset 0x100000 so READ data is non-X.
#
# Pipeline: pure iverilog + vvp + vcd2fst (no cocotb).
#
# Usage:
#   make            # compile + run + emit picorv32_spiflash_single_wire.fst
#   make install    # copy the FST into both fixture trees
#   make clean

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/spi_flash/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/spi_flash/captured

FIXTURE := picorv32_spiflash_single_wire.fst
SRCS    := tb_picorv32_spiflash_single_wire.v spiflash.v

all: $(FIXTURE)

$(FIXTURE): $(SRCS) firmware.hex
	iverilog -o tb.vvp $(SRCS)
	vvp tb.vvp
	vcd2fst -v tb_picorv32_spiflash_single_wire.vcd -f $(FIXTURE) -Z -c
	rm -f tb.vvp tb_picorv32_spiflash_single_wire.vcd

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb.vvp tb_picorv32_spiflash_single_wire.vcd $(FIXTURE)

.PHONY: all install clean

# Rebuild the captured SPI fixture.
#
# Produces nandland_spi_master_mode3_loopback.fst by simulating Russell
# Merrick's `SPI_Master_With_Single_CS` (vendored verbatim from nandland's
# spi-master, MIT). The supplied SystemVerilog testbench
# `SPI_Master_With_Single_CS_TB.sv` ties MISO ← MOSI in loopback, sends
# two back-to-back bytes (0xC1, 0xC2) at SPI_MODE=3 (CPOL=1 / CPHA=1) with
# CLKS_PER_HALF_BIT=4, and self-checks via `$display`. Pipeline matches
# the other captured pilots: pure iverilog + vvp + vcd2fst (no cocotb).
#
# Usage:
#   make            # compile + run + emit nandland_spi_master_mode3_loopback.fst
#   make install    # copy the FST into both fixture trees
#   make clean

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/spi/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/spi/captured

FIXTURE := nandland_spi_master_mode3_loopback.fst
SRCS    := SPI_Master_With_Single_CS_TB.sv SPI_Master_With_Single_CS.v SPI_Master.v

all: $(FIXTURE)

$(FIXTURE): $(SRCS)
	iverilog -g2012 -I. -o tb_spi.vvp SPI_Master_With_Single_CS_TB.sv SPI_Master_With_Single_CS.v
	vvp tb_spi.vvp
	vcd2fst -v dump.vcd -f $(FIXTURE) -Z -c
	rm -f dump.vcd tb_spi.vvp

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb_spi.vvp dump.vcd $(FIXTURE)

.PHONY: all install clean

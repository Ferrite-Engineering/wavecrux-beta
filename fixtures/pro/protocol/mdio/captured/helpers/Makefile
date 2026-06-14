# Rebuild the captured MDIO fixture.
#
# Produces mdio_forencich_clause22.fst by simulating Forencich's
# mdio_master.v (vendored as forencich_mdio_master.v, MIT) driven by the
# in-tree tb_mdio_master.v testbench. Toolchain: icarus-verilog + GTKWave
# (for the fst2vcd inspector). No Python / cocotb dependencies.
#
# Usage:
#   make            # compile + run, emit mdio_forencich_clause22.fst
#   make install    # copy the FST into both fixture trees
#   make clean

REPO_ROOT := $(realpath $(CURDIR)/../../../../../..)
TEST_DST := $(REPO_ROOT)/test/fixtures/protocol/mdio/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/mdio/captured

FIXTURE := mdio_forencich_clause22.fst
SRCS := tb_mdio_master.v forencich_mdio_master.v

all: $(FIXTURE)

$(FIXTURE): $(SRCS)
	iverilog -g2012 -o tb_mdio_master.vvp $(SRCS)
	vvp tb_mdio_master.vvp -fst

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -f tb_mdio_master.vvp $(FIXTURE)

.PHONY: all install clean

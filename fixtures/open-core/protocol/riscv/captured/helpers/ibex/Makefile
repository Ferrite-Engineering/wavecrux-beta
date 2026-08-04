# Rebuild the captured Ibex RVFI fixture.
#
# Produces riscv_ibex_rvfi_trap.fst by simulating lowRISC's ibex_top with
# the RISC-V Formal Interface compiled in (+define+RVFI), running a small
# hand-assembled RV32I program, and trimming the resulting waveform down to
# clock, reset and the 21 RVFI channels WaveCrux knows about.
#
# Unlike the sibling picorv32 helper, Ibex is NOT vendored into this repo:
# ibex_top pulls in ~30 RTL files plus lowRISC's prim library, which is far
# too much to carry in a fixture directory. The core is cloned at a pinned
# commit instead, so the build is still exactly reproducible.
#
# No RISC-V toolchain is required: assemble.py hand-encodes the program.
#
# Requirements: verilator (>= 5.0, built with FST support), gtkwave's
# fst2vcd + vcd2fst, python3, git.
#
# Usage:
#   make            # clone + build + run + trim, emit riscv_ibex_rvfi_trap.fst
#   make install    # copy the FST into both fixture trees
#   make clean      # remove build products (keeps the ibex clone)
#   make distclean  # also remove the ibex clone

REPO_ROOT := $(realpath $(CURDIR)/../../../../../../..)
TEST_DST  := $(REPO_ROOT)/test/fixtures/protocol/riscv/captured
VERIF_DST := $(REPO_ROOT)/verification/fixtures/protocol/riscv/captured

FIXTURE  := riscv_ibex_rvfi_trap.fst
IBEX_URL := https://github.com/lowRISC/ibex.git
IBEX_SHA := 3250d99482f1963891ef1cf19356eeaeeaa71d30
IBEX     := ibex

# Homebrew keeps lz4 (needed by Verilator's FST writer) outside the default
# search paths on macOS. Harmless elsewhere.
LZ4_PREFIX ?= $(shell brew --prefix lz4 2>/dev/null)
ifneq ($(LZ4_PREFIX),)
  LZ4_CFLAGS  := -CFLAGS "-I$(LZ4_PREFIX)/include"
  LZ4_LDFLAGS := -LDFLAGS "-L$(LZ4_PREFIX)/lib"
endif

PRIM  := $(IBEX)/vendor/lowrisc_ip/ip/prim/rtl
PRIMG := $(IBEX)/vendor/lowrisc_ip/ip/prim_generic/rtl

PKGS := \
  $(PRIM)/prim_util_pkg.sv \
  $(PRIM)/prim_cipher_pkg.sv \
  $(PRIM)/prim_secded_pkg.sv \
  $(PRIM)/prim_mubi_pkg.sv \
  $(PRIM)/prim_count_pkg.sv \
  $(PRIM)/prim_alert_pkg.sv \
  $(PRIM)/prim_esc_pkg.sv \
  $(PRIM)/prim_subreg_pkg.sv \
  $(PRIMG)/prim_pkg.sv \
  $(PRIMG)/prim_ram_1p_pkg.sv \
  $(PRIMG)/prim_ram_1r1w_pkg.sv \
  $(PRIMG)/prim_ram_2p_pkg.sv \
  $(IBEX)/rtl/ibex_pkg.sv

all: $(FIXTURE)

# Shallow single-commit fetch: pins exactly, without pulling Ibex's history.
$(IBEX)/.pinned:
	rm -rf $(IBEX)
	git init -q $(IBEX)
	cd $(IBEX) && git remote add origin $(IBEX_URL)
	cd $(IBEX) && git fetch -q --depth 1 origin $(IBEX_SHA)
	cd $(IBEX) && git checkout -q --detach FETCH_HEAD
	touch $@

prog.hex prog.lst: assemble.py
	python3 assemble.py prog.hex prog.lst

# Verilator ignores the scope/level arguments to $dumpvars, and --trace-depth
# cannot separate ibex_top from its (inlined) children, so the raw dump holds
# the whole hierarchy. trim.py does the selection afterwards.
raw.fst: $(IBEX)/.pinned tb_ibex_rvfi.sv prog.hex
	verilator --binary --timing --trace-fst \
	  -Wno-fatal -Wno-PINMISSING \
	  +define+RVFI \
	  $(LZ4_CFLAGS) $(LZ4_LDFLAGS) \
	  +incdir+$(PRIM) \
	  +incdir+$(IBEX)/vendor/lowrisc_ip/dv/sv/dv_utils \
	  -y $(PRIM) -y $(PRIMG) -y $(IBEX)/rtl \
	  --top tb_ibex_rvfi -o ibexsim \
	  $(PKGS) $(IBEX)/rtl/ibex_top.sv tb_ibex_rvfi.sv
	./obj_dir/ibexsim
	mv $(FIXTURE) raw.fst

$(FIXTURE): raw.fst trim.py
	fst2vcd raw.fst > raw.vcd
	python3 trim.py raw.vcd trimmed.vcd
	vcd2fst trimmed.vcd $(FIXTURE)

install: $(FIXTURE)
	cp $(FIXTURE) $(TEST_DST)/
	cp $(FIXTURE) $(VERIF_DST)/

clean:
	rm -rf obj_dir raw.fst raw.vcd trimmed.vcd prog.hex prog.lst $(FIXTURE)

distclean: clean
	rm -rf $(IBEX)

.PHONY: all install clean distclean

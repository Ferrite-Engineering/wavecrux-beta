// Drop-in replacement for the auto-generated `iverilog_dump.v` under
// `verilog-axis/tb/axis_register/` (commit 48ff7a7e). Augments the FST
// dump scope with `aresetn = !axis_register.rst` so the WaveCrux Pro
// AXIS decoder's active-low reset binding has a native net to bind to.
//
// Mirror of the active-high → active-low trick used by the AXI4-Full
// fixtures (see `test/fixtures/protocol/axi4_full/captured/helpers/`).
module iverilog_dump();
wire aresetn = !axis_register.rst;
initial begin
    $dumpfile("axis_register.fst");
    $dumpvars(0, axis_register);
    $dumpvars(0, iverilog_dump.aresetn);
end
endmodule

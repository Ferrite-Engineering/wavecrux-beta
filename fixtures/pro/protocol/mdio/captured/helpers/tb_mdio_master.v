/*

Copyright (c) 2026 Martin Fink

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

*/

// Standalone Verilog testbench wrapping Forencich's mdio_master.v (MIT) and
// a minimal MDIO slave model. Drives a deterministic sequence of Clause-22
// transactions and dumps mdc/mdio to FST for use as a captured fixture for
// the WaveCrux Pro MdioDecoder.

`timescale 1ns / 1ps
`default_nettype none

module tb_mdio_master;

    // ── system clock + reset ──────────────────────────────────────────────
    reg clk = 1'b0;
    always #5 clk = ~clk;             // 100 MHz
    reg rst = 1'b1;

    // ── master command interface ──────────────────────────────────────────
    reg  [4:0]  cmd_phy_addr = 5'd0;
    reg  [4:0]  cmd_reg_addr = 5'd0;
    reg  [15:0] cmd_data     = 16'd0;
    reg  [1:0]  cmd_opcode   = 2'b00;
    reg         cmd_valid    = 1'b0;
    wire        cmd_ready;

    wire [15:0] data_out;
    wire        data_out_valid;
    reg         data_out_ready = 1'b1;

    wire        mdc;
    wire        mdio;
    wire        m_mdio_o;
    wire        m_mdio_t;

    wire        busy;
    reg  [7:0]  prescale = 8'd3;       // ≈12.5 MHz MDC (well under spec 2.5 MHz cap,
                                        // but the decoder is rate-agnostic and a faster
                                        // MDC keeps the FST small)

    // ── pull-up on MDIO (models board pull-up so tri-state floats high) ──
    pullup pu (mdio);

    // ── master DUT ────────────────────────────────────────────────────────
    mdio_master u_master (
        .clk(clk),
        .rst(rst),
        .cmd_phy_addr(cmd_phy_addr),
        .cmd_reg_addr(cmd_reg_addr),
        .cmd_data(cmd_data),
        .cmd_opcode(cmd_opcode),
        .cmd_valid(cmd_valid),
        .cmd_ready(cmd_ready),
        .data_out(data_out),
        .data_out_valid(data_out_valid),
        .data_out_ready(data_out_ready),
        .mdc_o(mdc),
        .mdio_i(mdio),
        .mdio_o(m_mdio_o),
        .mdio_t(m_mdio_t),
        .busy(busy),
        .prescale(prescale)
    );

    // Master tri-state drive onto the shared MDIO net.
    assign mdio = m_mdio_t ? 1'bz : m_mdio_o;

    // ── slave model ───────────────────────────────────────────────────────
    //
    // A minimal Clause-22 slave that:
    //   * counts MDC rising edges from the master's `busy` rising edge,
    //   * if the issued command is a read (cmd_opcode = 2'b10), drives MDIO
    //     low on the second TA cycle and then shifts out a per-transaction
    //     response value MSB-first across the 16 DATA cycles.
    //
    // Frame layout (1-indexed MDC rising edges within a transaction):
    //   1..32  preamble (master drives 1)
    //   33..34 ST
    //   35..36 OP
    //   37..41 PHYAD
    //   42..46 REGAD
    //   47     TA[0] (master tri-states; line floats high via pull-up)
    //   48     TA[1] (slave drives 0)
    //   49..64 DATA (slave drives, MSB first)
    //
    // The slave's response value is staged in `slave_response_data` by the
    // stimulus block one clk cycle before each read's cmd_valid handshake.

    reg [15:0] slave_response_data = 16'h0000;
    reg slave_armed = 1'b0;
    reg [6:0] mdc_count = 7'd0;
    reg mdc_d = 1'b0;
    wire mdc_rising = mdc & ~mdc_d;

    always @(posedge clk) begin
        mdc_d <= mdc;

        if (rst) begin
            slave_armed <= 1'b0;
            mdc_count   <= 7'd0;
        end else begin
            if (cmd_valid && cmd_ready) begin
                mdc_count   <= 7'd0;
                slave_armed <= (cmd_opcode == 2'b10);  // read
            end else if (mdc_rising) begin
                if (mdc_count != 7'd127) mdc_count <= mdc_count + 7'd1;
            end

            if (!busy && mdc_count >= 7'd64) begin
                slave_armed <= 1'b0;
            end
        end
    end

    reg slave_drive_val;
    wire slave_drive_en = slave_armed && (mdc_count >= 7'd47) && (mdc_count <= 7'd63);

    // Drive bit during slave window. MDC cycles 47..63 (0-indexed counter
    // after rising edge n equals n+1 in 1-indexed terms — we drive when the
    // counter reads 47..63 which represents transmitted bits 48..64, i.e.
    // TA[1] + DATA[15:0]).
    always @* begin
        if (mdc_count == 7'd47) begin
            slave_drive_val = 1'b0;                       // TA[1] = 0
        end else begin
            slave_drive_val = slave_response_data[63 - mdc_count];
        end
    end

    assign mdio = slave_drive_en ? slave_drive_val : 1'bz;

    // ── stimulus ──────────────────────────────────────────────────────────
    initial begin
        // Hold reset for 100 ns, then start.
        #100 rst = 1'b0;
        #50;

        // T1: Write to PHYAD=5, REGAD=0x00 (control), DATA=0x1140
        //     (== standard 1000Mbps + auto-neg enable bit pattern)
        @(posedge clk);
        cmd_phy_addr <= 5'd5;
        cmd_reg_addr <= 5'd0;
        cmd_data     <= 16'h1140;
        cmd_opcode   <= 2'b01;   // write
        cmd_valid    <= 1'b1;
        @(posedge clk);
        while (!cmd_ready) @(posedge clk);
        cmd_valid <= 1'b0;
        // wait for transaction to finish
        while (busy) @(posedge clk);
        repeat (20) @(posedge clk);

        // T2: Read from PHYAD=5, REGAD=0x01 (status), expect 0x796D
        //     (link-up, auto-neg complete, copper, 100/full + 1000/full)
        slave_response_data <= 16'h796D;
        @(posedge clk);
        cmd_phy_addr <= 5'd5;
        cmd_reg_addr <= 5'd1;
        cmd_data     <= 16'h0000;
        cmd_opcode   <= 2'b10;   // read
        cmd_valid    <= 1'b1;
        @(posedge clk);
        while (!cmd_ready) @(posedge clk);
        cmd_valid <= 1'b0;
        while (busy) @(posedge clk);
        repeat (20) @(posedge clk);

        // T3: Write to PHYAD=1, REGAD=0x09 (1000BASE-T Control), DATA=0x0200
        //     (advertise 1000-full only)
        @(posedge clk);
        cmd_phy_addr <= 5'd1;
        cmd_reg_addr <= 5'd9;
        cmd_data     <= 16'h0200;
        cmd_opcode   <= 2'b01;   // write
        cmd_valid    <= 1'b1;
        @(posedge clk);
        while (!cmd_ready) @(posedge clk);
        cmd_valid <= 1'b0;
        while (busy) @(posedge clk);
        repeat (20) @(posedge clk);

        // T4: Read from PHYAD=1, REGAD=0x02 (PHY identifier 1), expect 0x0141
        //     (Marvell OUI high word)
        slave_response_data <= 16'h0141;
        @(posedge clk);
        cmd_phy_addr <= 5'd1;
        cmd_reg_addr <= 5'd2;
        cmd_data     <= 16'h0000;
        cmd_opcode   <= 2'b10;   // read
        cmd_valid    <= 1'b1;
        @(posedge clk);
        while (!cmd_ready) @(posedge clk);
        cmd_valid <= 1'b0;
        while (busy) @(posedge clk);
        repeat (50) @(posedge clk);

        $finish;
    end

    // ── FST dump ─────────────────────────────────────────────────────────
    initial begin
        $dumpfile("mdio_forencich_clause22.fst");
        $dumpvars(0, tb_mdio_master);
    end

    // safety net
    initial begin
        #200000;
        $display("[tb_mdio_master] TIMEOUT");
        $finish;
    end

endmodule

`default_nettype wire

// SPDX-License-Identifier: Apache-2.0
//
// Pure-Verilog testbench driving Gisselquist Technology's axil2apb +
// apbslave (both vendored verbatim from ZipCPU/wb2axip, Apache-2.0) so
// that the bus traffic on the APB side of the bridge can be captured
// as an FST for the WaveCrux APB protocol decoder corpus.
//
// Stimulus is a small sequence of AXI-Lite writes and reads issued to
// the bridge's slave port. The bridge translates each into a single
// APB setup/access cycle pair (apbslave is always-ready, so PREADY is
// asserted on the access edge — two-cycle transactions).
//
// No cocotb. iverilog + vvp only.

`timescale 1ns/1ps

module tb_apb;

    // ── parameters ────────────────────────────────────────────────────
    localparam C_AXI_ADDR_WIDTH = 12;   // match apbslave default
    localparam C_AXI_DATA_WIDTH = 32;
    localparam STRB_WIDTH = C_AXI_DATA_WIDTH / 8;

    // ── clock + reset ────────────────────────────────────────────────
    reg s_axi_aclk = 1'b0;
    always #5 s_axi_aclk = ~s_axi_aclk;   // 100 MHz

    reg s_axi_aresetn = 1'b0;

    // ── AXI-Lite master signals (driven by stimulus block) ───────────
    reg                          s_axi_awvalid = 1'b0;
    wire                         s_axi_awready;
    reg  [C_AXI_ADDR_WIDTH-1:0]  s_axi_awaddr  = 0;
    reg  [2:0]                   s_axi_awprot  = 3'b000;

    reg                          s_axi_wvalid  = 1'b0;
    wire                         s_axi_wready;
    reg  [C_AXI_DATA_WIDTH-1:0]  s_axi_wdata   = 0;
    reg  [STRB_WIDTH-1:0]        s_axi_wstrb   = 0;

    wire                         s_axi_bvalid;
    reg                          s_axi_bready  = 1'b0;
    wire [1:0]                   s_axi_bresp;

    reg                          s_axi_arvalid = 1'b0;
    wire                         s_axi_arready;
    reg  [C_AXI_ADDR_WIDTH-1:0]  s_axi_araddr  = 0;
    reg  [2:0]                   s_axi_arprot  = 3'b000;

    wire                         s_axi_rvalid;
    reg                          s_axi_rready  = 1'b0;
    wire [C_AXI_DATA_WIDTH-1:0]  s_axi_rdata;
    wire [1:0]                   s_axi_rresp;

    // ── APB wires between bridge and slave ──────────────────────────
    wire                         m_apb_psel;
    wire                         m_apb_penable;
    wire                         m_apb_pready;
    wire [C_AXI_ADDR_WIDTH-1:0]  m_apb_paddr;
    wire                         m_apb_pwrite;
    wire [C_AXI_DATA_WIDTH-1:0]  m_apb_pwdata;
    wire [STRB_WIDTH-1:0]        m_apb_pwstrb;
    wire [2:0]                   m_apb_pprot;
    wire [C_AXI_DATA_WIDTH-1:0]  m_apb_prdata;
    wire                         m_apb_pslverr;

    // ── DUT: AXI-Lite to APB bridge ─────────────────────────────────
    axil2apb #(
        .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
        .C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
        .OPT_OUTGOING_SKIDBUFFER(1'b0)
    ) bridge (
        .S_AXI_ACLK   (s_axi_aclk),
        .S_AXI_ARESETN(s_axi_aresetn),
        .S_AXI_AWVALID(s_axi_awvalid),
        .S_AXI_AWREADY(s_axi_awready),
        .S_AXI_AWADDR (s_axi_awaddr),
        .S_AXI_AWPROT (s_axi_awprot),
        .S_AXI_WVALID (s_axi_wvalid),
        .S_AXI_WREADY (s_axi_wready),
        .S_AXI_WDATA  (s_axi_wdata),
        .S_AXI_WSTRB  (s_axi_wstrb),
        .S_AXI_BVALID (s_axi_bvalid),
        .S_AXI_BREADY (s_axi_bready),
        .S_AXI_BRESP  (s_axi_bresp),
        .S_AXI_ARVALID(s_axi_arvalid),
        .S_AXI_ARREADY(s_axi_arready),
        .S_AXI_ARADDR (s_axi_araddr),
        .S_AXI_ARPROT (s_axi_arprot),
        .S_AXI_RVALID (s_axi_rvalid),
        .S_AXI_RREADY (s_axi_rready),
        .S_AXI_RDATA  (s_axi_rdata),
        .S_AXI_RRESP  (s_axi_rresp),
        .M_APB_PSEL   (m_apb_psel),
        .M_APB_PENABLE(m_apb_penable),
        .M_APB_PREADY (m_apb_pready),
        .M_APB_PADDR  (m_apb_paddr),
        .M_APB_PWRITE (m_apb_pwrite),
        .M_APB_PWDATA (m_apb_pwdata),
        .M_APB_PWSTRB (m_apb_pwstrb),
        .M_APB_PPROT  (m_apb_pprot),
        .M_APB_PRDATA (m_apb_prdata),
        .M_APB_PSLVERR(m_apb_pslverr)
    );

    // ── APB slave (target peripheral) ───────────────────────────────
    apbslave #(
        .C_APB_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
        .C_APB_DATA_WIDTH(C_AXI_DATA_WIDTH)
    ) slave (
        .PCLK   (s_axi_aclk),
        .PRESETn(s_axi_aresetn),
        .PSEL   (m_apb_psel),
        .PENABLE(m_apb_penable),
        .PREADY (m_apb_pready),
        .PADDR  (m_apb_paddr),
        .PWRITE (m_apb_pwrite),
        .PWDATA (m_apb_pwdata),
        .PWSTRB (m_apb_pwstrb),
        .PPROT  (m_apb_pprot),
        .PRDATA (m_apb_prdata),
        .PSLVERR(m_apb_pslverr)
    );

    // ── reusable AXI-Lite tasks ─────────────────────────────────────
    task axi_write(
            input [C_AXI_ADDR_WIDTH-1:0] addr,
            input [C_AXI_DATA_WIDTH-1:0] data,
            input [STRB_WIDTH-1:0]       strb);
        begin
            @(posedge s_axi_aclk);
            s_axi_awvalid <= 1'b1;
            s_axi_awaddr  <= addr;
            s_axi_awprot  <= 3'b000;
            s_axi_wvalid  <= 1'b1;
            s_axi_wdata   <= data;
            s_axi_wstrb   <= strb;
            s_axi_bready  <= 1'b1;

            // Hold valid until AW + W handshake (both must accept).
            wait (s_axi_awready && s_axi_wready);
            @(posedge s_axi_aclk);
            s_axi_awvalid <= 1'b0;
            s_axi_wvalid  <= 1'b0;
            s_axi_wstrb   <= {STRB_WIDTH{1'b0}};

            // Wait for write response.
            wait (s_axi_bvalid);
            @(posedge s_axi_aclk);
            s_axi_bready  <= 1'b0;
        end
    endtask

    task axi_read(
            input  [C_AXI_ADDR_WIDTH-1:0] addr,
            output [C_AXI_DATA_WIDTH-1:0] data);
        begin
            @(posedge s_axi_aclk);
            s_axi_arvalid <= 1'b1;
            s_axi_araddr  <= addr;
            s_axi_arprot  <= 3'b000;
            s_axi_rready  <= 1'b1;

            wait (s_axi_arready);
            @(posedge s_axi_aclk);
            s_axi_arvalid <= 1'b0;

            wait (s_axi_rvalid);
            data = s_axi_rdata;
            @(posedge s_axi_aclk);
            s_axi_rready  <= 1'b0;
        end
    endtask

    // ── stimulus ────────────────────────────────────────────────────
    reg [C_AXI_DATA_WIDTH-1:0] rd;

    initial begin
        // Release reset after a few cycles.
        repeat (5) @(posedge s_axi_aclk);
        s_axi_aresetn <= 1'b1;
        repeat (2) @(posedge s_axi_aclk);

        // ── full-word writes ────────────────────────────────────────
        axi_write(12'h100, 32'hDEADBEEF, 4'hF);
        @(posedge s_axi_aclk);
        axi_write(12'h104, 32'h12345678, 4'hF);
        @(posedge s_axi_aclk);
        axi_write(12'h108, 32'hCAFEBABE, 4'hF);
        @(posedge s_axi_aclk);
        axi_write(12'h10C, 32'hA5A5A5A5, 4'hF);
        @(posedge s_axi_aclk);

        // ── read-back ───────────────────────────────────────────────
        axi_read(12'h100, rd);
        @(posedge s_axi_aclk);
        axi_read(12'h104, rd);
        @(posedge s_axi_aclk);
        axi_read(12'h108, rd);
        @(posedge s_axi_aclk);
        axi_read(12'h10C, rd);
        @(posedge s_axi_aclk);

        // ── partial-strobe write + read ────────────────────────────
        // Only update bytes [1:0] of 0x100, preserving the upper half.
        axi_write(12'h100, 32'h0000C0DE, 4'h3);
        @(posedge s_axi_aclk);
        axi_read(12'h100, rd);

        // Trailing idle cycles so the decoder sees the last
        // transaction return to bus idle before EOF.
        repeat (8) @(posedge s_axi_aclk);
        $finish;
    end

    // ── waveform dump ──────────────────────────────────────────────
    initial begin
        $dumpfile("apb_axil2apb.fst");
        $dumpvars(0, tb_apb);
    end

    // Safety guard.
    initial begin
        #20000;
        $display("ERROR: testbench timeout");
        $finish;
    end

endmodule

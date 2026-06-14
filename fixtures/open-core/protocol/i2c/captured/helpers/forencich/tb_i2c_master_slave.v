// SPDX-License-Identifier: 0BSD
// This is free and unencumbered software released into the public domain.
//
// Anyone is free to copy, modify, publish, use, compile, sell, or
// distribute this software, either in source code form or as a compiled
// binary, for any purpose, commercial or non-commercial, and by any
// means.
//
// Pure-Verilog testbench wiring Alex Forencich's i2c_master + i2c_slave
// (vendored verbatim from verilog-i2c, MIT) onto a shared open-drain SDA/SCL
// bus with explicit pull-ups. The master is driven with a small AXIS command
// program that performs two back-to-back writes to the slave at 7-bit
// address 0x50:
//
//   1. Write 2 bytes (0xAB, 0xCD).
//   2. Write 1 byte  (0x42).
//
// The captured FST exercises the WaveCrux I²C decoder against real
// master/slave SDA+SCL traffic — START/STOP framing, address+W,
// per-byte ACK, on a properly modelled open-drain bus.
//
// Prescale chosen so SCL is ~1 MHz off a 100 MHz tb clock (fast-mode
// I²C). The decoder is bus-clockless, so SCL frequency is cosmetic —
// it only affects how dense the FST is.

`timescale 1 ns / 1 ps

module tb_i2c_master_slave;

    // ── tb clock + reset ────────────────────────────────────────────
    reg clk = 1'b1;
    always #5 clk = ~clk;          // 100 MHz tb clock
    reg rst = 1'b1;

    // ── master AXIS command interface ───────────────────────────────
    reg  [6:0] m_cmd_address       = 7'h00;
    reg        m_cmd_start         = 1'b0;
    reg        m_cmd_read          = 1'b0;
    reg        m_cmd_write         = 1'b0;
    reg        m_cmd_write_multi   = 1'b0;
    reg        m_cmd_stop          = 1'b0;
    reg        m_cmd_valid         = 1'b0;
    wire       m_cmd_ready;

    reg  [7:0] m_dat_tdata         = 8'h00;
    reg        m_dat_tvalid        = 1'b0;
    wire       m_dat_tready;
    reg        m_dat_tlast         = 1'b0;

    wire [7:0] m_rx_tdata;
    wire       m_rx_tvalid;
    reg        m_rx_tready         = 1'b1;
    wire       m_rx_tlast;

    // master open-drain SCL/SDA drivers
    wire       m_scl_i, m_scl_o, m_scl_t;
    wire       m_sda_i, m_sda_o, m_sda_t;

    wire       m_busy;
    wire       m_bus_control;
    wire       m_bus_active;
    wire       m_missed_ack;

    // 100 MHz / (4 * 25) = 1 MHz SCL (fast-mode upper edge)
    wire [15:0] prescale = 16'd25;

    i2c_master master (
        .clk(clk),
        .rst(rst),
        .s_axis_cmd_address(m_cmd_address),
        .s_axis_cmd_start(m_cmd_start),
        .s_axis_cmd_read(m_cmd_read),
        .s_axis_cmd_write(m_cmd_write),
        .s_axis_cmd_write_multiple(m_cmd_write_multi),
        .s_axis_cmd_stop(m_cmd_stop),
        .s_axis_cmd_valid(m_cmd_valid),
        .s_axis_cmd_ready(m_cmd_ready),
        .s_axis_data_tdata(m_dat_tdata),
        .s_axis_data_tvalid(m_dat_tvalid),
        .s_axis_data_tready(m_dat_tready),
        .s_axis_data_tlast(m_dat_tlast),
        .m_axis_data_tdata(m_rx_tdata),
        .m_axis_data_tvalid(m_rx_tvalid),
        .m_axis_data_tready(m_rx_tready),
        .m_axis_data_tlast(m_rx_tlast),
        .scl_i(m_scl_i),
        .scl_o(m_scl_o),
        .scl_t(m_scl_t),
        .sda_i(m_sda_i),
        .sda_o(m_sda_o),
        .sda_t(m_sda_t),
        .busy(m_busy),
        .bus_control(m_bus_control),
        .bus_active(m_bus_active),
        .missed_ack(m_missed_ack),
        .prescale(prescale),
        .stop_on_idle(1'b0)
    );

    // ── slave configured as device 0x50, 7-bit ──────────────────────
    wire       s_scl_i, s_scl_o, s_scl_t;
    wire       s_sda_i, s_sda_o, s_sda_t;

    // Slave TX path (replies to read requests with these bytes).
    reg  [7:0] s_tx_tdata          = 8'h55;
    reg        s_tx_tvalid         = 1'b0;
    wire       s_tx_tready;
    reg        s_tx_tlast          = 1'b0;

    wire [7:0] s_rx_tdata;
    wire       s_rx_tvalid;
    reg        s_rx_tready         = 1'b1;
    wire       s_rx_tlast;

    wire       s_busy;
    wire [6:0] s_bus_address;
    wire       s_bus_addressed;
    wire       s_bus_active;

    i2c_slave #(
        .FILTER_LEN(4)
    ) slave (
        .clk(clk),
        .rst(rst),
        .release_bus(1'b0),
        .s_axis_data_tdata(s_tx_tdata),
        .s_axis_data_tvalid(s_tx_tvalid),
        .s_axis_data_tready(s_tx_tready),
        .s_axis_data_tlast(s_tx_tlast),
        .m_axis_data_tdata(s_rx_tdata),
        .m_axis_data_tvalid(s_rx_tvalid),
        .m_axis_data_tready(s_rx_tready),
        .m_axis_data_tlast(s_rx_tlast),
        .scl_i(s_scl_i),
        .scl_o(s_scl_o),
        .scl_t(s_scl_t),
        .sda_i(s_sda_i),
        .sda_o(s_sda_o),
        .sda_t(s_sda_t),
        .busy(s_busy),
        .bus_address(s_bus_address),
        .bus_addressed(s_bus_addressed),
        .bus_active(s_bus_active),
        .enable(1'b1),
        .device_address(7'h50),
        .device_address_mask(7'h7F)
    );

    // ── open-drain SDA/SCL bus with pull-ups ────────────────────────
    // Each side drives only when its _t (tristate) is low; otherwise
    // its driver is high-Z. The pullup makes the bus default to 1.
    wire scl;
    wire sda;
    assign scl = m_scl_t ? 1'bz : m_scl_o;
    assign scl = s_scl_t ? 1'bz : s_scl_o;
    assign sda = m_sda_t ? 1'bz : m_sda_o;
    assign sda = s_sda_t ? 1'bz : s_sda_o;
    pullup(scl);
    pullup(sda);
    assign m_scl_i = scl;
    assign m_sda_i = sda;
    assign s_scl_i = scl;
    assign s_sda_i = sda;

    // ── stimulus envelope ───────────────────────────────────────────
    // Helper task: issue a single command word + handshake on
    // s_axis_cmd_*.
    task issue_cmd(
        input [6:0] addr,
        input start_b,
        input read_b,
        input write_b,
        input write_multi_b,
        input stop_b
    );
        begin
            @(posedge clk);
            m_cmd_address     <= addr;
            m_cmd_start       <= start_b;
            m_cmd_read        <= read_b;
            m_cmd_write       <= write_b;
            m_cmd_write_multi <= write_multi_b;
            m_cmd_stop        <= stop_b;
            m_cmd_valid       <= 1'b1;
            @(posedge clk);
            while (!m_cmd_ready) @(posedge clk);
            m_cmd_start       <= 1'b0;
            m_cmd_read        <= 1'b0;
            m_cmd_write       <= 1'b0;
            m_cmd_write_multi <= 1'b0;
            m_cmd_stop        <= 1'b0;
            m_cmd_valid       <= 1'b0;
        end
    endtask

    // Helper task: present one write byte on the master TX stream.
    task send_byte(input [7:0] b, input last);
        begin
            @(posedge clk);
            m_dat_tdata  <= b;
            m_dat_tlast  <= last;
            m_dat_tvalid <= 1'b1;
            @(posedge clk);
            while (!m_dat_tready) @(posedge clk);
            m_dat_tvalid <= 1'b0;
            m_dat_tlast  <= 1'b0;
        end
    endtask

    initial begin
        $dumpfile("i2c_forencich_master_slave.fst");
        $dumpvars(0, tb_i2c_master_slave);

        // Hold reset for a few clocks.
        repeat (8) @(posedge clk);
        rst <= 1'b0;
        repeat (8) @(posedge clk);

        // ── Transaction 1: write 2 bytes 0xAB, 0xCD to address 0x50 ──
        // START + ADDR+W in one command; data via separate stream.
        issue_cmd(.addr(7'h50), .start_b(1'b1), .read_b(1'b0),
                  .write_b(1'b1), .write_multi_b(1'b1), .stop_b(1'b0));
        send_byte(8'hAB, 1'b0);
        send_byte(8'hCD, 1'b1);
        // Followed by an explicit STOP command (no address change).
        issue_cmd(.addr(7'h50), .start_b(1'b0), .read_b(1'b0),
                  .write_b(1'b0), .write_multi_b(1'b0), .stop_b(1'b1));

        // Let the master complete this transaction on the bus.
        wait (!m_bus_active);
        repeat (40) @(posedge clk);

        // ── Transaction 2: write 1 byte 0x42 to address 0x50 ────────
        // START + ADDR+W + single data byte + STOP, all in one go.
        issue_cmd(.addr(7'h50), .start_b(1'b1), .read_b(1'b0),
                  .write_b(1'b1), .write_multi_b(1'b0), .stop_b(1'b1));
        send_byte(8'h42, 1'b1);

        wait (!m_bus_active);
        repeat (40) @(posedge clk);

        $finish;
    end

    // Safety timeout — if the master+slave handshake stalls, kill the
    // run rather than dump a multi-megabyte FST.
    initial begin
        #500000;  // 500 us
        $display("FATAL: tb timeout — bus did not complete");
        $finish;
    end

endmodule

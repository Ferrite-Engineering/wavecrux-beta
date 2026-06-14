// SPDX-License-Identifier: 0BSD
//
// USB 2.0 Full-Speed host-TX capture, driving the D+/D- bus via
// ulixxe's usb_cdc host-side packet emitters (`usb_tasks.v` + its
// includes, MIT). These tasks emit NRZI-encoded, bit-stuffed, CRC-
// computed packets that match the USB 2.0 spec byte-for-byte.
//
// We don't instantiate a device — only the master-side TX matters for
// the wavecrux USB 2.0 decoder, which reconstructs packets from the
// D+/D- signal pair. The testbench wires `dp_force`/`dn_force` (driven
// by the tasks) onto the bus through pull-ups so idle state is J
// (D+ high, D- low) per Full-Speed convention.
//
// Sequence:
//   1. Start-of-Frame (SOF) for frame 0x123
//   2. SETUP token to address 0, endpoint 0
//   3. DATA0 carrying the 8-byte GET_DESCRIPTOR(DEVICE) setup packet
//   4. ACK handshake
//
// All four packets are full USB 2.0 wire-format with SYNC + PID +
// payload + CRC + EOP, hand-checked against the USB 2.0 specification
// §8.4 (packet formats).

`timescale 1 ns / 1 ps

module tb_usb_cdc_host_tx;
  // Constants the included tasks expect.
  localparam MAX_BITS  = 128;
  localparam MAX_BYTES = 128;
  // Full-Speed bit period = 1 / 12 Mb/s ≈ 83.333 ns. The included tasks
  // expect `time` (real-valued), in our timeunit (1 ns).
  time bit_time = 1000.0 / 12.0;

  reg  dp_force;
  reg  dn_force;
  wire dp_sense;
  wire dn_sense;

  // Bus has weak pull-up on D+, pull-down on D- — idle = J.
  pullup  (dp_sense);
  pulldown(dn_sense);
  assign  dp_sense = dp_force;
  assign  dn_sense = dn_force;

  integer errors   = 0;
  integer warnings = 0;

  // Referenced by usb_tasks.v's unused `test_poweron_reset` task.
  reg power_on = 1'b1;

  // The macros in sim_tasks.v use `BIT_TIME — define it locally.
  `define BIT_TIME bit_time

  // usb_tasks.v references `USB_CDC_INST.u_sie.frame_o` inside
  // higher-level `test_*` tasks that we never call. Provide a dummy
  // hierarchy so the file compiles without instantiating a real
  // device. The compiled-but-uncalled tasks are dead code.
  `define USB_CDC_INST tb_usb_cdc_host_tx.dummy_dev
  dummy_usb_cdc_host_tx_stub dummy_dev ();

  `include "usb_tasks.v"

  initial begin
    $dumpfile("tb_usb_cdc_host_tx.vcd");
    $dumpvars(0, tb_usb_cdc_host_tx);

    dp_force = 1'bZ;
    dn_force = 1'bZ;

    // Hold idle for a moment.
    #(20 * bit_time);

    // 1. Start-of-Frame for frame 0x123
    sof_tx(11'h123, 8, bit_time);
    #(8 * bit_time);

    // 2. SETUP token to addr=0, endp=0
    token_tx(PID_SETUP, 7'h00, 4'h0, 8, bit_time);
    #(2 * bit_time);

    // 3. DATA0 with 8-byte GET_DESCRIPTOR(DEVICE) setup packet
    //    bmRequestType=0x80 (D2H, Standard, Device)
    //    bRequest=0x06 (GET_DESCRIPTOR)
    //    wValue=0x0100 (Descriptor Type=DEVICE, Index=0)
    //    wIndex=0x0000
    //    wLength=0x0040 (64 bytes)
    //
    //    The task takes data MSB-first across bytes (data[8*j +: 8] is byte j
    //    from MSB end); we want byte 0 = 0x80, byte 7 = 0x40.
    data_tx(
      PID_DATA0,
      // The task indexes byte 0 at bits [7:0] and byte (bytes-1) at the
      // high end. Pad the high MSB end with zeros and put our 8 bytes
      // in the LSB so byte 7 (bmRequestType, transmitted first) =
      // 0x80, byte 0 (wLength_hi, transmitted last) = 0x00.
      {{(8 * (MAX_BYTES - 8)){1'b0}},
       8'h80, 8'h06, 8'h00, 8'h01, 8'h00, 8'h00, 8'h40, 8'h00},
      8,
      8,
      bit_time
    );
    #(2 * bit_time);

    // 4. ACK handshake
    handshake_tx(PID_ACK, 8, bit_time);

    #(20 * bit_time);
    $finish;
  end
endmodule

// Dummy hierarchy that satisfies the `USB_CDC_INST.u_sie.frame_o`
// references inside usb_tasks.v's `test_*` tasks. None of those tasks
// are actually called from our initial block — this stub just lets the
// file compile.
module dummy_usb_cdc_host_tx_stub ();
  reg [10:0] frame_o = 11'b0;

  // Nest one level so `u_sie.frame_o` resolves.
  dummy_usb_cdc_sie_stub u_sie ();
endmodule

module dummy_usb_cdc_sie_stub ();
  reg [10:0] frame_o = 11'b0;
endmodule

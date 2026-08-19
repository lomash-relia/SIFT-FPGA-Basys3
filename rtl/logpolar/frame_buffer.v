`timescale 1ns / 1ps
// =====================================================================
//  frame_buffer.v
//  16384 x 8-bit simple dual-port block RAM.
//  One write port (UART RX side or transform side) and one registered
//  read port (1 cycle latency, which logpolar_core's pipeline accounts for).
//  Used twice in the design: once as the input frame, once as the output.
// =====================================================================

module frame_buffer (
    input  wire        clk,

    input  wire        we,
    input  wire [13:0] wr_addr,
    input  wire [7:0]  wr_data,

    input  wire [13:0] rd_addr,
    output reg  [7:0]  rd_data
);

    (* ram_style = "block" *) reg [7:0] ram [0:16383];

    always @(posedge clk) begin
        if (we) ram[wr_addr] <= wr_data;
        rd_data <= ram[rd_addr];
    end

endmodule

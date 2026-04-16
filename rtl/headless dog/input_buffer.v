`timescale 1ns / 1ps

module input_buffer (
    input wire clk,
    input wire we,
    input wire [13:0] wr_addr,
    input wire [7:0] data_in,
    input wire [13:0] rd_addr,
    output reg [7:0] data_out
);

    (* ram_style = "block" *) reg [7:0] ram [0:16383];

    always @(posedge clk) begin
        if (we) ram[wr_addr] <= data_in;
        data_out <= ram[rd_addr];
    end
endmodule
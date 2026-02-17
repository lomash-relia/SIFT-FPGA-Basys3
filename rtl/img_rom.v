`timescale 1ns / 1ps

//==============================================================================
// Image ROM - Reads 128x128 grayscale image from hex file
// One pixel per clock when enabled. 1-cycle read latency.
//==============================================================================
module img_rom #(
    parameter WIDTH  = 128,
    parameter HEIGHT = 128
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        en,
    output reg  [7:0]  pixel
);

    localparam TOTAL = WIDTH * HEIGHT;  // 16384

    (* ram_style = "block" *)
    reg [7:0] mem [0:TOTAL-1];

    reg [13:0] addr;

    initial begin
        $readmemh("image.hex", mem);
    end

    always @(posedge clk) begin
        if (rst) begin
            addr  <= 14'd0;
            pixel <= 8'd0;
        end
        else if (en) begin
            pixel <= mem[addr];
            addr  <= addr + 1'b1;
        end
    end

endmodule
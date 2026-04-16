`timescale 1ns / 1ps

module output_buffer (
    input wire clk,
    input wire rst,
    
    // Write side (From DoG)
    input wire dog_valid,
    input wire signed [8:0] dog_pixel,
    
    // Read side (To UART TX)
    input wire [13:0] rd_addr,
    output reg [7:0] out_pixel
);

    (* ram_style = "block" *) reg [7:0] ram [0:16383];
    reg [13:0] wr_addr;

    wire [7:0] mapped_pixel = 8'd128 + (dog_pixel >>> 1);

    always @(posedge clk) begin
        if (rst) begin
            wr_addr <= 0;
        end else if (dog_valid) begin
            ram[wr_addr] <= mapped_pixel;
            wr_addr <= wr_addr + 1;
        end
        
        out_pixel <= ram[rd_addr];
    end
endmodule
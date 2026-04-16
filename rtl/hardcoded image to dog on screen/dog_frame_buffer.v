`timescale 1ns / 1ps

module dog_frame_buffer (
    input  wire        clk,
    input  wire        rst,
    
    // Port A: Write from DoG Core (100 MHz)
    input  wire        dog_valid,
    input  wire signed [8:0] dog_pixel,
    
    // Port B: Read from VGA Display (100 MHz, gated by CE)
    input  wire [13:0] rd_addr,
    output reg  signed [8:0] out_pixel
);

    // 128x128 = 16,384 pixels
    (* ram_style = "block" *)
    reg signed [8:0] bram [0:16383];
    
    // 15-bit address to safely hold the number 16384 without truncation
    reg [14:0] wr_addr;

    // Port A: Write Logic
    always @(posedge clk) begin
        if (rst) begin
            wr_addr <= 15'd0;
        end else if (dog_valid && wr_addr < 15'd16384) begin
            bram[wr_addr[13:0]] <= dog_pixel;
            wr_addr <= wr_addr + 15'd1;
        end
    end

    // Port B: Read Logic
    always @(posedge clk) begin
        out_pixel <= bram[rd_addr];
    end

endmodule
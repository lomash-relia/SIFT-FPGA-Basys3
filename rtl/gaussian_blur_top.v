`timescale 1ns / 1ps

module gaussian_blur_top #(
    parameter WIDTH  = 128,
    parameter HEIGHT = 128,
    // Default Kernel (Standard Gaussian): [1, 4, 6, 4, 1] / 16
    parameter W0 = 1, 
    parameter W1 = 4, 
    parameter W2 = 6, 
    parameter W3 = 4, 
    parameter W4 = 1,
    parameter SHIFT = 4
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,

    output wire [7:0]  blurred_pixel,
    output wire        blurred_valid,
    output wire        done
);
    localparam TOTAL = WIDTH * HEIGHT; 

    //==========================================================================
    // ROM Control
    //==========================================================================
    reg        rom_en;
    reg        rom_valid;
    reg [14:0] rom_count; 
    
    wire [7:0] rom_pixel;

    always @(posedge clk) begin
        if (rst) begin
            rom_en    <= 1'b0;
            rom_valid <= 1'b0;
            rom_count <= 15'd0;
        end
        else if (start) begin
            rom_en    <= 1'b1;
            rom_valid <= 1'b0;
            rom_count <= 15'd0;
        end
        else if (rom_en) begin
            if (rom_count == TOTAL) begin
                rom_en    <= 1'b0;
                rom_valid <= 1'b0;
            end
            else begin
                rom_valid <= 1'b1;
                rom_count <= rom_count + 15'd1;
            end
        end
        else begin
            rom_valid <= 1'b0;
        end
    end

    //==========================================================================
    // Image ROM
    //==========================================================================
    img_rom #(.WIDTH(WIDTH), .HEIGHT(HEIGHT)) rom_inst (
        .clk   (clk),
        .rst   (rst),
        .en    (rom_en),
        .pixel (rom_pixel)
    );

    //==========================================================================
    // Row (Horizontal) Convolution
    //==========================================================================
    wire [7:0] row_pixel;
    wire       row_valid;
    
    // Pass parameters W0..W4, SHIFT down to the instance
    gaussian_row_conv #(
        .WIDTH(WIDTH), .HEIGHT(HEIGHT),
        .W0(W0), .W1(W1), .W2(W2), .W3(W3), .W4(W4), .SHIFT(SHIFT)
    ) row_conv_inst (
        .clk            (clk),
        .rst            (rst),
        .pixel_in       (rom_pixel),
        .pixel_in_valid (rom_valid),
        .pixel_out      (row_pixel),
        .pixel_out_valid(row_valid)
    );

    //==========================================================================
    // Column (Vertical) Convolution
    //==========================================================================
    // Pass parameters W0..W4, SHIFT down to the instance
    gaussian_col_conv #(
        .WIDTH(WIDTH), .HEIGHT(HEIGHT),
        .W0(W0), .W1(W1), .W2(W2), .W3(W3), .W4(W4), .SHIFT(SHIFT)
    ) col_conv_inst (
        .clk            (clk),
        .rst            (rst),
        .start          (start),
        .pixel_in       (row_pixel),
        .pixel_in_valid (row_valid),
        .pixel_out      (blurred_pixel),
        .pixel_out_valid(blurred_valid),
        .done           (done)
    );

endmodule
`timescale 1ns / 1ps

module gaussian_blur_top #(
    parameter WIDTH = 128,
    parameter HEIGHT = 128,
    parameter W0 = 1, W1 = 4, W2 = 6, W3 = 4, W4 = 1, parameter SHIFT = 4
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    
    // RAM interface
    output reg [13:0]  rd_addr,
    input  wire [7:0]  rd_data,

    output wire [7:0]  blurred_pixel,
    output wire        blurred_valid,
    output wire        done
);
    localparam TOTAL = WIDTH * HEIGHT; 

    reg        processing;
    reg [14:0] count;
    reg        rd_data_valid; // Accounts for BRAM 1-cycle latency

    always @(posedge clk) begin
        if (rst) begin
            rd_addr <= 0;
            count <= 0;
            processing <= 0;
            rd_data_valid <= 0;
        end else if (start) begin
            rd_addr <= 0;
            count <= 0;
            processing <= 1;
            rd_data_valid <= 0;
        end else if (processing) begin
            if (count < TOTAL) begin
                rd_addr <= rd_addr + 1;
                count <= count + 1;
                rd_data_valid <= 1'b1;
            end else begin
                processing <= 0;
                rd_data_valid <= 1'b0;
            end
        end else begin
            rd_data_valid <= 1'b0;
        end
    end

    // Pipelined Row Convolution
    wire [7:0] row_pixel;
    wire       row_valid;
    
    gaussian_row_conv #(
        .WIDTH(WIDTH), .HEIGHT(HEIGHT),
        .W0(W0), .W1(W1), .W2(W2), .W3(W3), .W4(W4), .SHIFT(SHIFT)
    ) row_conv_inst (
        .clk(clk), .rst(rst),
        .pixel_in(rd_data),
        .pixel_in_valid(rd_data_valid),
        .pixel_out(row_pixel), .pixel_out_valid(row_valid)
    );

    // Pipelined Column Convolution
    gaussian_col_conv #(
        .WIDTH(WIDTH), .HEIGHT(HEIGHT),
        .W0(W0), .W1(W1), .W2(W2), .W3(W3), .W4(W4), .SHIFT(SHIFT)
    ) col_conv_inst (
        .clk(clk), .rst(rst), .start(start),
        .pixel_in(row_pixel), .pixel_in_valid(row_valid),
        .pixel_out(blurred_pixel), .pixel_out_valid(blurred_valid),
        .done(done)
    );
endmodule
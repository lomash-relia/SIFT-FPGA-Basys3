`timescale 1ns / 1ps

module dog_top #(
    parameter WIDTH  = 128,
    parameter HEIGHT = 128
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               start,

    // DoG Result: Signed 9-bit (Range -255 to +255)
    output reg signed [8:0]   dog_pixel,
    output reg                dog_valid,
    output wire               done
);

    //==========================================================================
    // Pipeline 1: Sigma 1 (Standard Gaussian)
    // Kernel: 1, 4, 6, 4, 1 (Div 16)
    //==========================================================================
    wire [7:0] blur1_pixel;
    wire       blur1_valid;
    wire       done1;

    gaussian_blur_top #(
        .WIDTH(WIDTH), .HEIGHT(HEIGHT),
        .W0(1), .W1(4), .W2(6), .W3(4), .W4(1), .SHIFT(4)
    ) blur_pipe_1 (
        .clk           (clk),
        .rst           (rst),
        .start         (start),
        .blurred_pixel (blur1_pixel),
        .blurred_valid (blur1_valid),
        .done          (done1)
    );

    //==========================================================================
    // Pipeline 2: Sigma 2 (Wider Gaussian)
    // Kernel: 1, 2, 2, 2, 1 (Div 8) -> More blur
    //==========================================================================
    wire [7:0] blur2_pixel;
    wire       blur2_valid;
    wire       done2;

    gaussian_blur_top #(
        .WIDTH(WIDTH), .HEIGHT(HEIGHT),
        .W0(1), .W1(2), .W2(2), .W3(2), .W4(1), .SHIFT(3)
    ) blur_pipe_2 (
        .clk           (clk),
        .rst           (rst),
        .start         (start),
        .blurred_pixel (blur2_pixel),
        .blurred_valid (blur2_valid),
        .done          (done2)
    );

    //==========================================================================
    // Difference Logic
    //==========================================================================
    // Since both pipes are identical hardware triggered by the same start signal,
    // they will be cycle-accurate synchronized. We can simply AND the valids.
    
    always @(posedge clk) begin
        if (rst) begin
            dog_valid <= 1'b0;
            dog_pixel <= 9'sd0;
        end
        else begin
            // Synchronization check
            if (blur1_valid && blur2_valid) begin
                dog_valid <= 1'b1;
                // Signed Subtraction: Expand to 9 bits first to handle negative results
                dog_pixel <= {1'b0, blur1_pixel} - {1'b0, blur2_pixel};
            end
            else begin
                dog_valid <= 1'b0;
            end
        end
    end

    assign done = done1 & done2;

endmodule
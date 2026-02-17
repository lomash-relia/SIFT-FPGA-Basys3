`timescale 1ns / 1ps

module gaussian_row_conv #(
    parameter WIDTH  = 128,
    parameter HEIGHT = 128,
    // Default Kernel: [1, 4, 6, 4, 1] / 16
    parameter W0 = 1, 
    parameter W1 = 4, 
    parameter W2 = 6, 
    parameter W3 = 4, 
    parameter W4 = 1,
    parameter SHIFT = 4  // Divide by 2^4 = 16
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  pixel_in,
    input  wire        pixel_in_valid,

    output reg  [7:0]  pixel_out,
    output reg         pixel_out_valid
);
    // Shift register for the 5-tap window
    reg [7:0] t0, t1, t2, t3, t4;
    reg [7:0] col_count;
    
    // Increased sum width to 20 bits to be safe with larger weights
    reg [19:0] sum; 
    reg        math_valid;
    
    // Temporary wires for edge mirroring
    reg [7:0] p0, p1, p2, p3, p4;

    // Combinational logic for Edge Mirroring (No changes here)
    always @(*) begin
        p0 = t0; p1 = t1; p2 = t2; p3 = t3; p4 = t4;
        if (col_count == 1) begin 
             p0=t4; p1=t4; p2=t4; p3=t4; p4=t4; 
        end
        else if (col_count == 2) begin 
             p0=t3; p1=t3; p2=t3; 
        end
        else if (col_count == 3) begin 
             p0=t2; p1=t2; 
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            t0 <= 0; t1 <= 0; t2 <= 0; t3 <= 0; t4 <= 0;
            col_count       <= 0;
            pixel_out       <= 0;
            pixel_out_valid <= 0;
            math_valid      <= 0;
            sum             <= 0;
        end
        else begin
            // 1. Shift Window logic
            if (pixel_in_valid) begin
                t0 <= t1; t1 <= t2; t2 <= t3; t3 <= t4; t4 <= pixel_in;
                
                if (col_count == WIDTH-1) col_count <= 0;
                else col_count <= col_count + 1;
                
                math_valid <= 1'b1;
            end
            else begin
                math_valid <= 1'b0;
            end

            // 2. Math Pipeline (Flexible Weights)
            if (math_valid) begin
                // Replaced hardcoded shifts with parameter multiplications
                sum <= (p0 * W0) + 
                       (p1 * W1) + 
                       (p2 * W2) + 
                       (p3 * W3) + 
                       (p4 * W4);
                       
                pixel_out       <= sum >> SHIFT; // Flexible division
                pixel_out_valid <= 1'b1;
            end
            else begin
                pixel_out_valid <= 1'b0;
            end
        end
    end
endmodule
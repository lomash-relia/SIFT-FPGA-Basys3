//`timescale 1ns / 1ps

//module gaussian_row_conv #(
//    parameter WIDTH  = 128,
//    parameter HEIGHT = 128,
//    parameter W0 = 1, 
//    parameter W1 = 4, 
//    parameter W2 = 6, 
//    parameter W3 = 4, 
//    parameter W4 = 1,
//    parameter SHIFT = 4  
//)(
//    input  wire        clk,
//    input  wire        rst,
//    input  wire [7:0]  pixel_in,
//    input  wire        pixel_in_valid,

//    output reg  [7:0]  pixel_out,
//    output reg         pixel_out_valid
//);
//    reg [7:0] t0, t1, t2, t3, t4;
//    reg [7:0] col_count;
    
//    reg [19:0] sum; 
//    reg        math_valid;
    
//    reg [7:0] p0, p1, p2, p3, p4;

//    always @(*) begin
//        p0 = t0; p1 = t1; p2 = t2; p3 = t3; p4 = t4;
        
//        // Edge mirroring at start of row
//        if (col_count == 1) begin
//            p0 = t2; p1 = t1;
//        end else if (col_count == 2) begin
//            p0 = t3; p1 = t3; p2 = t2;
//        end
        
//        // Edge mirroring at end of row
//        if (col_count == WIDTH - 1) begin
//            p3 = t3; p4 = t2;
//        end else if (col_count == WIDTH - 2) begin
//            p4 = t3;
//        end
//    end

//    always @(posedge clk) begin
//        if (rst) begin
//            t0 <= 0; t1 <= 0; t2 <= 0; t3 <= 0; t4 <= 0;
//            col_count       <= 0;
//            pixel_out       <= 0;
//            pixel_out_valid <= 0;
//            math_valid      <= 0;
//            sum             <= 0;
//        end
//        else begin
//            if (pixel_in_valid) begin
//                t0 <= t1; t1 <= t2; t2 <= t3; t3 <= t4; t4 <= pixel_in;
                
//                if (col_count == WIDTH-1) col_count <= 0;
//                else col_count <= col_count + 1;
                
//                math_valid <= 1'b1;
//            end
//            else begin
//                math_valid <= 1'b0;
//            end

//            if (math_valid) begin
//                sum <= (p0 * W0) + (p1 * W1) + (p2 * W2) + (p3 * W3) + (p4 * W4);
//                pixel_out <= sum >> SHIFT;
//                pixel_out_valid <= 1'b1;
//            end
//            else begin
//                pixel_out_valid <= 1'b0;
//            end
//        end
//    end

//endmodule

`timescale 1ns / 1ps

module gaussian_row_conv #(
    parameter W0 = 1, W1 = 4, W2 = 6, W3 = 4, W4 = 1, parameter SHIFT = 4  
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  img_width,
    input  wire [7:0]  img_height,
    input  wire [7:0]  pixel_in,
    input  wire        pixel_in_valid,

    output reg  [7:0]  pixel_out,
    output reg         pixel_out_valid
);
    reg [7:0] t0, t1, t2, t3, t4;
    reg [7:0] col_count;
    reg [19:0] sum; 
    reg        math_valid;
    reg [7:0]  p0, p1, p2, p3, p4;

    always @(posedge clk) begin
        if (rst) begin
            t0 <= 0; t1 <= 0; t2 <= 0; t3 <= 0; t4 <= 0;
            col_count <= 0; pixel_out <= 0; pixel_out_valid <= 0; 
            math_valid <= 0; sum <= 0;
        end else begin
            if (pixel_in_valid) begin
                t0 <= t1; t1 <= t2; t2 <= t3; t3 <= t4; t4 <= pixel_in;
                
                if (col_count == img_width - 1) col_count <= 0;
                else col_count <= col_count + 1;
                
                math_valid <= 1'b1;
            end else begin
                math_valid <= 1'b0;
            end

            if (math_valid) begin
                // Temporary logic for mirroring
                p0 = t0; p1 = t1; p2 = t2; p3 = t3; p4 = t4;
                if (col_count == 1) begin p0 = t2; p1 = t1; end
                else if (col_count == 2) begin p0 = t3; p1 = t3; p2 = t2; end
                
                if (col_count == img_width - 1) begin p3 = t3; p4 = t2; end
                else if (col_count == img_width - 2) begin p4 = t3; end

                sum <= (p0 * W0) + (p1 * W1) + (p2 * W2) + (p3 * W3) + (p4 * W4);
                pixel_out <= sum >> SHIFT;
                pixel_out_valid <= 1'b1;
            end else begin
                pixel_out_valid <= 1'b0;
            end
        end
    end
endmodule
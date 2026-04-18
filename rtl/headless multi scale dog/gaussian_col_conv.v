`timescale 1ns / 1ps

module gaussian_col_conv #(
    parameter W0 = 1, W1 = 4, W2 = 6, W3 = 4, W4 = 1,
    parameter SHIFT = 4
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
    // Fixed max-size line buffers (128 depth)
    (* ram_style = "block" *) reg [7:0] lb0 [0:127];
    (* ram_style = "block" *) reg [7:0] lb1 [0:127];
    (* ram_style = "block" *) reg [7:0] lb2 [0:127];
    (* ram_style = "block" *) reg [7:0] lb3 [0:127];

    reg [7:0] t0, t1, t2, t3, t4;
    reg [7:0] col_count, row_count;
    reg [19:0] sum;
    reg        math_valid;
    reg [7:0]  p0, p1, p2, p3, p4;

    always @(posedge clk) begin
        if (rst) begin
            col_count <= 0;
            row_count <= 0;
            pixel_out_valid <= 0;
            math_valid <= 0;
        end else if (pixel_in_valid) begin
            // Shift data vertically through line buffers
            lb3[col_count] <= lb2[col_count];
            lb2[col_count] <= lb1[col_count];
            lb1[col_count] <= lb0[col_count];
            lb0[col_count] <= pixel_in;

            t4 <= pixel_in;
            t3 <= lb0[col_count];
            t2 <= lb1[col_count];
            t1 <= lb2[col_count];
            t0 <= lb3[col_count];

            if (col_count == img_width - 1) begin
                col_count <= 0;
                row_count <= row_count + 1;
            end else begin
                col_count <= col_count + 1;
            end
            math_valid <= 1'b1;
        end else begin
            math_valid <= 1'b0;
        end

        if (math_valid) begin
            p0 = t0; p1 = t1; p2 = t2; p3 = t3; p4 = t4;
            
            // Vertical Edge Mirroring using dynamic img_height
            if (row_count == 1) begin p0 = t2; p1 = t1; end
            else if (row_count == 2) begin p0 = t3; p1 = t3; p2 = t2; end
            else if (row_count == img_height + 1) begin p3 = t3; p4 = t2; end
            else if (row_count == img_height + 2) begin p4 = t3; end

            sum <= (p0*W0) + (p1*W1) + (p2*W2) + (p3*W3) + (p4*W4);
            pixel_out <= sum >> SHIFT;
            pixel_out_valid <= 1'b1;
        end else begin
            pixel_out_valid <= 1'b0;
        end
    end
endmodule
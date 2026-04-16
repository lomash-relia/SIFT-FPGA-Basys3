//`timescale 1ns / 1ps

//module gaussian_col_conv #(
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
//    input  wire        start,
//    input  wire [7:0]  pixel_in,
//    input  wire        pixel_in_valid,

//    output reg  [7:0]  pixel_out,
//    output reg         pixel_out_valid,
//    output reg         done
//);
//    localparam TOTAL = WIDTH * HEIGHT;

//    localparam IDLE    = 2'd0,
//               STORE   = 2'd1,
//               CONV    = 2'd2;
//    reg [1:0] state;

//    (* ram_style = "block" *)
//    reg [7:0] fbuf [0:TOTAL-1];
    
//    reg [13:0] wr_addr;
//    reg [7:0]  col;
//    reg [7:0]  row;

//    wire [7:0] r0, r1, r2, r3, r4;
//    assign r0 = (row < 8'd2) ? 8'd0 : (row - 8'd2);
//    assign r1 = (row < 8'd1) ? 8'd0 : (row - 8'd1);
//    assign r2 = row;
//    assign r3 = (row > (HEIGHT - 2)) ? (HEIGHT - 1) : (row + 8'd1);
//    assign r4 = (row > (HEIGHT - 3)) ? (HEIGHT - 1) : (row + 8'd2);

//    wire [13:0] addr0 = r0 * WIDTH + col;
//    wire [13:0] addr1 = r1 * WIDTH + col;
//    wire [13:0] addr2 = r2 * WIDTH + col;
//    wire [13:0] addr3 = r3 * WIDTH + col;
//    wire [13:0] addr4 = r4 * WIDTH + col;

//    reg [7:0] p0, p1, p2, p3, p4;
//    reg pipe_valid, pipe_last;
    
//    always @(posedge clk) begin
//        if (rst) begin
//            state <= IDLE;
//            wr_addr <= 14'd0;
//            row <= 8'd0;
//            col <= 8'd0;
//            pixel_out <= 8'd0;
//            pixel_out_valid <= 1'b0;
//            done <= 1'b0;
//            pipe_valid <= 1'b0;
//            pipe_last <= 1'b0;
//        end else begin
//            case (state)
//                IDLE: begin
//                    pipe_valid <= 1'b0;
//                    done <= 1'b0;
//                    if (start) begin
//                        state   <= STORE;
//                        wr_addr <= 14'd0;
//                    end
//                end

//                STORE: begin
//                    pipe_valid <= 1'b0;
//                    if (pixel_in_valid) begin
//                        fbuf[wr_addr] <= pixel_in;
//                        if (wr_addr == (TOTAL - 1)) begin
//                            state <= CONV;
//                            row   <= 8'd0;
//                            col   <= 8'd0;
//                        end
//                        wr_addr <= wr_addr + 14'd1;
//                    end
//                end

//                CONV: begin
//                    p0 <= fbuf[addr0];
//                    p1 <= fbuf[addr1];
//                    p2 <= fbuf[addr2];
//                    p3 <= fbuf[addr3];
//                    p4 <= fbuf[addr4];

//                    pipe_valid <= 1'b1;
//                    pipe_last  <= (row == (HEIGHT - 1)) && (col == (WIDTH - 1));

//                    if (col == (WIDTH - 1)) begin
//                        col <= 8'd0;
//                        if (row == (HEIGHT - 1)) state <= IDLE;
//                        else row <= row + 8'd1;
//                    end else begin
//                        col <= col + 8'd1;
//                    end
//                end
//            endcase

//            if (pipe_valid) begin
//                pixel_out <= ((p0 * W0) + (p1 * W1) + (p2 * W2) + (p3 * W3) + (p4 * W4)) >> SHIFT;
//                pixel_out_valid <= 1'b1;
//                if (pipe_last) done <= 1'b1;
//            end else begin
//                pixel_out_valid <= 1'b0;
//            end
//        end
//    end

//endmodule
`timescale 1ns / 1ps

module gaussian_col_conv #(
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
    // Line Buffers: Only 4 rows are stored to get a 5-pixel vertical window
    reg [7:0] lb0 [0:127];
    reg [7:0] lb1 [0:127];
    reg [7:0] lb2 [0:127];
    reg [7:0] lb3 [0:127];

    reg [7:0] col_count;
    reg [7:0] row_count;

    // Registers moved to module level to avoid Synth 8-10632
    reg [7:0] t0, t1, t2, t3, t4;
    reg [7:0] p0, p1, p2, p3, p4;
    reg [19:0] sum;
    reg math_valid;

    always @(posedge clk) begin
        if (rst) begin
            col_count <= 0;
            row_count <= 0;
            pixel_out <= 0;
            pixel_out_valid <= 0;
            math_valid <= 0;
            sum <= 0;
        end else begin
            if (pixel_in_valid) begin
                // Shift data through line buffers
                lb3[col_count] <= pixel_in;
                lb2[col_count] <= lb3[col_count];
                lb1[col_count] <= lb2[col_count];
                lb0[col_count] <= lb1[col_count];

                // Current column "slice"
                t4 <= pixel_in;
                t3 <= lb3[col_count];
                t2 <= lb2[col_count];
                t1 <= lb1[col_count];
                t0 <= lb0[col_count];

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
                // Default center assignment
                p0 = t0; p1 = t1; p2 = t2; p3 = t3; p4 = t4;

                // Vertical Edge Mirroring
                if (row_count == 1) begin 
                    p0 = t2; p1 = t1; 
                end else if (row_count == 2) begin 
                    p0 = t3; p1 = t3; p2 = t2; 
                end else if (row_count == img_height + 1) begin 
                    p3 = t3; p4 = t2; 
                end else if (row_count == img_height + 2) begin 
                    p4 = t3; 
                end

                sum <= (p0 * W0) + (p1 * W1) + (p2 * W2) + (p3 * W3) + (p4 * W4);
                pixel_out <= sum >> SHIFT;
                pixel_out_valid <= 1'b1;
            end else begin
                pixel_out_valid <= 1'b0;
            end
        end
    end
endmodule
`timescale 1ns / 1ps

module gaussian_col_conv #(
    parameter WIDTH  = 128,
    parameter HEIGHT = 128,
    // Default Kernel parameters
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
    input  wire [7:0]  pixel_in,
    input  wire        pixel_in_valid,

    output reg  [7:0]  pixel_out,
    output reg         pixel_out_valid,
    output reg         done
);
    localparam TOTAL = WIDTH * HEIGHT;

    localparam IDLE    = 2'd0,
               STORE   = 2'd1,
               CONV    = 2'd2;
    reg [1:0] state;

    // Frame buffer (Use BRAM)
    (* ram_style = "block" *)
    reg [7:0] fbuf [0:TOTAL-1];
    
    reg [13:0] wr_addr;
    reg [7:0]  col;
    reg [7:0]  row;

    // Tap row indices (No changes to address logic)
    wire [7:0] r0, r1, r2, r3, r4;
    assign r0 = (row < 8'd2) ? 8'd0 : (row - 8'd2);
    assign r1 = (row < 8'd1) ? 8'd0 : (row - 8'd1);
    assign r2 = row;
    assign r3 = (row >= (HEIGHT[7:0] - 8'd1)) ? (HEIGHT[7:0] - 8'd1) : (row + 8'd1);
    assign r4 = (row >= (HEIGHT[7:0] - 8'd2)) ? (HEIGHT[7:0] - 8'd1) : (row + 8'd2);

    // Address calc (No changes)
    wire [14:0] row_addr0 = {7'd0, r0} * 15'd128;
    wire [14:0] row_addr1 = {7'd0, r1} * 15'd128;
    wire [14:0] row_addr2 = {7'd0, r2} * 15'd128;
    wire [14:0] row_addr3 = {7'd0, r3} * 15'd128;
    wire [14:0] row_addr4 = {7'd0, r4} * 15'd128;
    
    wire [13:0] addr0 = row_addr0[13:0] + {6'd0, col};
    wire [13:0] addr1 = row_addr1[13:0] + {6'd0, col};
    wire [13:0] addr2 = row_addr2[13:0] + {6'd0, col};
    wire [13:0] addr3 = row_addr3[13:0] + {6'd0, col};
    wire [13:0] addr4 = row_addr4[13:0] + {6'd0, col};

    reg [7:0] p0, p1, p2, p3, p4;
    reg        pipe_valid;
    reg        pipe_last;

    // NEW: Flexible Math
    reg [19:0] sum; // Increased width

    always @(posedge clk) begin
        if (rst) begin
            state           <= IDLE;
            done            <= 1'b0;
            pixel_out_valid <= 1'b0;
            pixel_out       <= 8'd0;
            wr_addr         <= 14'd0;
            col             <= 8'd0;
            row             <= 8'd0;
            pipe_valid      <= 1'b0;
            pipe_last       <= 1'b0;
            sum             <= 0;
            p0<=0; p1<=0; p2<=0; p3<=0; p4<=0;
        end
        else begin
            done            <= 1'b0;
            pixel_out_valid <= 1'b0;

            // Pipeline stage 2: output convolved pixel
            if (pipe_valid) begin
                // Compute Sum with Parameters
                sum <= (p0 * W0) + (p1 * W1) + (p2 * W2) + (p3 * W3) + (p4 * W4);
                
                // Output (delayed by 1 cycle relative to sum calc, 
                // but for simple blur flow, we can output next cycle)
                // Note: In strict pipelining, 'sum' updates this cycle, 
                // so we output 'sum >> SHIFT' on the *next* cycle. 
                // However, to keep your logic flow similar:
                pixel_out       <= ((p0 * W0) + (p1 * W1) + (p2 * W2) + (p3 * W3) + (p4 * W4)) >> SHIFT;
                
                pixel_out_valid <= 1'b1;
                if (pipe_last) done <= 1'b1;
            end

            case (state)
                IDLE: begin
                    pipe_valid <= 1'b0;
                    if (start) begin
                        state   <= STORE;
                        wr_addr <= 14'd0;
                    end
                end

                STORE: begin
                    pipe_valid <= 1'b0;
                    if (pixel_in_valid) begin
                        fbuf[wr_addr] <= pixel_in;
                        if (wr_addr == (TOTAL[13:0] - 14'd1)) begin
                            state <= CONV;
                            row   <= 8'd0;
                            col   <= 8'd0;
                        end
                        wr_addr <= wr_addr + 14'd1;
                    end
                end

                CONV: begin
                    p0 <= fbuf[addr0];
                    p1 <= fbuf[addr1];
                    p2 <= fbuf[addr2];
                    p3 <= fbuf[addr3];
                    p4 <= fbuf[addr4];

                    pipe_valid <= 1'b1;
                    pipe_last  <= (row == (HEIGHT[7:0] - 8'd1)) && (col == (WIDTH[7:0] - 8'd1));

                    if (col == (WIDTH[7:0] - 8'd1)) begin
                        col <= 8'd0;
                        if (row == (HEIGHT[7:0] - 8'd1)) state <= IDLE;
                        else row <= row + 8'd1;
                    end
                    else col <= col + 8'd1;
                end
            endcase
        end
    end
endmodule
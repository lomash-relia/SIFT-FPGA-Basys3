`timescale 1ns / 1ps

module gaussian_col_conv #(
    parameter WIDTH  = 128,
    parameter HEIGHT = 128,
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

    (* ram_style = "block" *)
    reg [7:0] fbuf [0:TOTAL-1];
    
    reg [13:0] wr_addr;
    reg [7:0]  col;
    reg [7:0]  row;

    wire [7:0] r0, r1, r2, r3, r4;
    assign r0 = (row < 8'd2) ? 8'd0 : (row - 8'd2);
    assign r1 = (row < 8'd1) ? 8'd0 : (row - 8'd1);
    assign r2 = row;
    assign r3 = (row > (HEIGHT - 2)) ? (HEIGHT - 1) : (row + 8'd1);
    assign r4 = (row > (HEIGHT - 3)) ? (HEIGHT - 1) : (row + 8'd2);

    wire [13:0] addr0 = r0 * WIDTH + col;
    wire [13:0] addr1 = r1 * WIDTH + col;
    wire [13:0] addr2 = r2 * WIDTH + col;
    wire [13:0] addr3 = r3 * WIDTH + col;
    wire [13:0] addr4 = r4 * WIDTH + col;

    reg [7:0] p0, p1, p2, p3, p4;
    reg pipe_valid, pipe_last;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            wr_addr <= 14'd0;
            row <= 8'd0;
            col <= 8'd0;
            pixel_out <= 8'd0;
            pixel_out_valid <= 1'b0;
            done <= 1'b0;
            pipe_valid <= 1'b0;
            pipe_last <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    pipe_valid <= 1'b0;
                    done <= 1'b0;
                    if (start) begin
                        state   <= STORE;
                        wr_addr <= 14'd0;
                    end
                end

                STORE: begin
                    pipe_valid <= 1'b0;
                    if (pixel_in_valid) begin
                        fbuf[wr_addr] <= pixel_in;
                        if (wr_addr == (TOTAL - 1)) begin
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
                    pipe_last  <= (row == (HEIGHT - 1)) && (col == (WIDTH - 1));

                    if (col == (WIDTH - 1)) begin
                        col <= 8'd0;
                        if (row == (HEIGHT - 1)) state <= IDLE;
                        else row <= row + 8'd1;
                    end else begin
                        col <= col + 8'd1;
                    end
                end
            endcase

            if (pipe_valid) begin
                pixel_out <= ((p0 * W0) + (p1 * W1) + (p2 * W2) + (p3 * W3) + (p4 * W4)) >> SHIFT;
                pixel_out_valid <= 1'b1;
                if (pipe_last) done <= 1'b1;
            end else begin
                pixel_out_valid <= 1'b0;
            end
        end
    end

endmodule
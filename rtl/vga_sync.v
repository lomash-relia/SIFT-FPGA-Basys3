`timescale 1ns / 1ps

module vga_sync (
    input  wire        clk,       // 100 MHz system clock
    input  wire        ce,        // 25 MHz clock enable
    input  wire        rst,

    output reg         hsync,
    output reg         vsync,
    output wire        video_on,
    output wire [9:0]  pixel_x,
    output wire [9:0]  pixel_y
);

    localparam H_VIS        = 640;
    localparam H_FP         =  16;
    localparam H_SYNC_W     =  96;
    localparam H_BP         =  48;
    localparam H_TOTAL      = 800;
    localparam H_SYNC_START = H_VIS + H_FP;              // 656
    localparam H_SYNC_END   = H_VIS + H_FP + H_SYNC_W;   // 752

    localparam V_VIS        = 480;
    localparam V_FP         =  10;
    localparam V_SYNC_W     =   2;
    localparam V_BP         =  33;
    localparam V_TOTAL      = 525;
    localparam V_SYNC_START = V_VIS + V_FP;              // 490
    localparam V_SYNC_END   = V_VIS + V_FP + V_SYNC_W;   // 492

    reg [9:0] h_cnt;
    reg [9:0] v_cnt;

    // Horizontal counter
    always @(posedge clk) begin
        if (rst)       h_cnt <= 10'd0;
        else if (ce)   h_cnt <= (h_cnt == H_TOTAL-1) ? 10'd0 : h_cnt + 10'd1;
    end

    // Vertical counter
    always @(posedge clk) begin
        if (rst)
            v_cnt <= 10'd0;
        else if (ce && h_cnt == H_TOTAL-1)
            v_cnt <= (v_cnt == V_TOTAL-1) ? 10'd0 : v_cnt + 10'd1;
    end

    // Sync pulses (registered, active LOW)
    always @(posedge clk) begin
        if (rst) begin
            hsync <= 1'b1;
            vsync <= 1'b1;
        end else if (ce) begin
            hsync <= ~(h_cnt >= H_SYNC_START && h_cnt < H_SYNC_END);
            vsync <= ~(v_cnt >= V_SYNC_START && v_cnt < V_SYNC_END);
        end
    end

    assign video_on = (h_cnt < H_VIS) && (v_cnt < V_VIS);
    assign pixel_x  = h_cnt;
    assign pixel_y  = v_cnt;

endmodule
`timescale 1ns / 1ps

module vga_top (
    input  wire       clk,     // 100 MHz 
    input  wire       btnC,    // Center button 
    
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b,
    output wire       hsync,
    output wire       vsync
);

    // 100 MHz -> 25 MHz Clock Enable
    reg [1:0] ce_cnt = 0;
    wire ce;
    always @(posedge clk) ce_cnt <= ce_cnt + 1;
    assign ce = (ce_cnt == 2'b00);

    // DoG Core 
    wire signed [8:0] dog_pixel;
    wire dog_valid;
    wire done;
    
    reg btn_prev = 0;
    reg start_trigger = 0;
    
    always @(posedge clk) begin
        btn_prev <= btnC;
        start_trigger <= (btn_prev == 1'b1 && btnC == 1'b0); // Start on button release
    end

    dog_top #(
        .WIDTH(128), .HEIGHT(128)
    ) sift_core (
        .clk       (clk),
        .rst       (btnC),
        .start     (start_trigger),
        .dog_pixel (dog_pixel),
        .dog_valid (dog_valid),
        .done      (done)
    );

    // Frame Buffer
    wire [13:0] rd_addr;
    wire signed [8:0] fb_out_pixel;

    dog_frame_buffer fbuf (
        .clk       (clk),
        .rst       (btnC),
        .dog_valid (dog_valid),
        .dog_pixel (dog_pixel),
        .rd_addr   (rd_addr),
        .out_pixel (fb_out_pixel)
    );

    // VGA Timing
    wire video_on;
    wire [9:0] pixel_x, pixel_y;

    vga_sync sync_gen (
        .clk      (clk),
        .ce       (ce),
        .rst      (btnC),
        .hsync    (hsync),
        .vsync    (vsync),
        .video_on (video_on),
        .pixel_x  (pixel_x),
        .pixel_y  (pixel_y)
    );

    // VGA Display
    vga_display display_gen (
        .clk       (clk),
        .ce        (ce),
        .video_on  (video_on),
        .pixel_x   (pixel_x),
        .pixel_y   (pixel_y),
        .dog_pixel (fb_out_pixel),
        .rd_addr   (rd_addr),
        .vga_r     (vga_r),
        .vga_g     (vga_g),
        .vga_b     (vga_b)
    );

endmodule
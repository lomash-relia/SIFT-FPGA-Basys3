`timescale 1ns / 1ps

module vga_display (
    input  wire        clk,
    input  wire        ce,
    input  wire        video_on,
    input  wire [9:0]  pixel_x,
    input  wire [9:0]  pixel_y,
    input  wire signed [8:0] dog_pixel,
    output wire [13:0] rd_addr,
    output reg  [3:0]  vga_r,
    output reg  [3:0]  vga_g,
    output reg  [3:0]  vga_b
);

    localparam X_START = 256;
    localparam Y_START = 176;

    wire in_box = (pixel_x >= X_START && pixel_x < X_START + 128) &&
                  (pixel_y >= Y_START && pixel_y < Y_START + 128);

    assign rd_addr = in_box ? ((pixel_y - Y_START) * 128) + (pixel_x - X_START) : 14'd0;

    reg video_on_delay;
    reg in_box_delay;

    always @(posedge clk) begin
        if (ce) begin
            video_on_delay <= video_on;
            in_box_delay   <= in_box;
        end
    end

    wire [7:0] mapped_color;

    dog_to_u8 dog_map_inst (
        .dog_in(dog_pixel),
        .pixel_out(mapped_color)
    );

    wire [3:0] dac_color = mapped_color[7:4];

    always @(posedge clk) begin
        if (ce) begin
            if (video_on_delay) begin
                if (in_box_delay) begin
                    vga_r <= dac_color;
                    vga_g <= dac_color;
                    vga_b <= dac_color;
                end else begin
                    vga_r <= 4'h0;
                    vga_g <= 4'h0;
                    vga_b <= 4'h2;
                end
            end else begin
                vga_r <= 4'h0;
                vga_g <= 4'h0;
                vga_b <= 4'h0;
            end
        end
    end

endmodule
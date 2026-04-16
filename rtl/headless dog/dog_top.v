//`timescale 1ns / 1ps

//module dog_top # (
//    parameter WIDTH = 128,
//    parameter HEIGHT = 128
//)(
//    input  wire               clk,
//    input  wire               rst,
//    input  wire               start,
    
//    // Interface to Input Buffer
//    output wire [13:0]        rd_addr,
//    input  wire [7:0]         rd_data,

//    output reg signed [8:0]   dog_pixel,
//    output reg                dog_valid,
//    output wire               done
//);

//    wire [7:0] blur1_pixel, blur2_pixel;
//    wire       blur1_valid, blur2_valid;
//    wire       done1, done2;
    
//    // Shared read address logic inside gaussian_blur_top
//    // Only the first pipe needs to drive the address since they are in sync
//    wire [13:0] internal_addr;
//    assign rd_addr = internal_addr;

//    gaussian_blur_top #(.W0(1), .W1(4), .W2(6), .W3(4), .W4(1), .SHIFT(4)) blur_pipe_1 (
//        .clk(clk), .rst(rst), .start(start),
//        .rd_addr(internal_addr), .rd_data(rd_data),
//        .blurred_pixel(blur1_pixel), .blurred_valid(blur1_valid), .done(done1)
//    );

//    gaussian_blur_top #(.W0(1), .W1(2), .W2(2), .W3(2), .W4(1), .SHIFT(3)) blur_pipe_2 (
//        .clk(clk), .rst(rst), .start(start),
//        .rd_addr(), .rd_data(rd_data), // Address output left floating here
//        .blurred_pixel(blur2_pixel), .blurred_valid(blur2_valid), .done(done2)
//    );

//    assign done = done1; // Both pipes finish at the same time

//    always @(posedge clk) begin
//        if (rst) begin
//            dog_valid <= 1'b0;
//            dog_pixel <= 9'd0;
//        end else begin
//            dog_valid <= blur1_valid && blur2_valid;
//            dog_pixel <= $signed({1'b0, blur1_pixel}) - $signed({1'b0, blur2_pixel});
//        end
//    end
//endmodule
`timescale 1ns / 1ps

module dog_top # (
    parameter WIDTH = 128,
    parameter HEIGHT = 128
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               start,
    
    // NEW: Ports added to accept dimensions from top.v
    input  wire [7:0]         img_width,
    input  wire [7:0]         img_height,
    
    // Interface to Input Buffer
    output wire [13:0]        rd_addr,
    input  wire [7:0]         rd_data,

    output reg signed [8:0]   dog_pixel,
    output reg                dog_valid,
    output wire               done
);

    wire [7:0] blur1_pixel, blur2_pixel;
    wire       blur1_valid, blur2_valid;
    wire       done1, done2;
    
    // Shared read address logic inside gaussian_blur_top
    // Only the first pipe needs to drive the address since they are in sync
    wire [13:0] internal_addr;
    assign rd_addr = internal_addr;

    gaussian_blur_top #(.W0(1), .W1(4), .W2(6), .W3(4), .W4(1), .SHIFT(4)) blur_pipe_1 (
        .clk(clk), .rst(rst), .start(start),
        .img_width(img_width),       // Passed from top
        .img_height(img_height),     // Passed from top
        .rd_addr(internal_addr), .rd_data(rd_data),
        .blurred_pixel(blur1_pixel), .blurred_valid(blur1_valid), .done(done1)
    );

    gaussian_blur_top #(.W0(1), .W1(2), .W2(2), .W3(2), .W4(1), .SHIFT(3)) blur_pipe_2 (
        .clk(clk), .rst(rst), .start(start),
        .img_width(img_width),       // Passed from top
        .img_height(img_height),     // Passed from top
        .rd_addr(), .rd_data(rd_data), // Address output left floating here
        .blurred_pixel(blur2_pixel), .blurred_valid(blur2_valid), .done(done2)
    );

    assign done = done1 & done2;

    // Difference of Gaussians (DoG) Calculation
    always @(posedge clk) begin
        if (rst) begin
            dog_pixel <= 0;
            dog_valid <= 0;
        end else begin
            // Since both pipelines are architecturally identical, they will output valid data on the exact same clock cycles.
            if (blur1_valid && blur2_valid) begin
                dog_pixel <= $signed({1'b0, blur1_pixel}) - $signed({1'b0, blur2_pixel});
                dog_valid <= 1'b1;
            end else begin
                dog_valid <= 1'b0;
            end
        end
    end
endmodule
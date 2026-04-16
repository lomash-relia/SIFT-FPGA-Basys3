//`timescale 1ns / 1ps

//module gaussian_blur_top #(
//    parameter WIDTH = 128,
//    parameter HEIGHT = 128,
//    parameter W0 = 1, W1 = 4, W2 = 6, W3 = 4, W4 = 1, parameter SHIFT = 4
//)(
//    input  wire        clk,
//    input  wire        rst,
//    input  wire        start,
    
//    // RAM interface
//    output reg [13:0]  rd_addr,
//    input  wire [7:0]  rd_data,

//    output wire [7:0]  blurred_pixel,
//    output wire        blurred_valid,
//    output wire        done
//);
//    localparam TOTAL = WIDTH * HEIGHT; 

//    reg        processing;
//    reg [14:0] count;
//    reg        rd_data_valid; // Accounts for BRAM 1-cycle latency

//    always @(posedge clk) begin
//        if (rst) begin
//            rd_addr <= 0;
//            count <= 0;
//            processing <= 0;
//            rd_data_valid <= 0;
//        end else if (start) begin
//            rd_addr <= 0;
//            count <= 0;
//            processing <= 1;
//            rd_data_valid <= 0;
//        end else if (processing) begin
//            if (count < TOTAL) begin
//                rd_addr <= rd_addr + 1;
//                count <= count + 1;
//                rd_data_valid <= 1'b1;
//            end else begin
//                processing <= 0;
//                rd_data_valid <= 1'b0;
//            end
//        end else begin
//            rd_data_valid <= 1'b0;
//        end
//    end

//    // Pipelined Row Convolution
//    wire [7:0] row_pixel;
//    wire       row_valid;
    
//    gaussian_row_conv #(
//        .WIDTH(WIDTH), .HEIGHT(HEIGHT),
//        .W0(W0), .W1(W1), .W2(W2), .W3(W3), .W4(W4), .SHIFT(SHIFT)
//    ) row_conv_inst (
//        .clk(clk), .rst(rst),
//        .pixel_in(rd_data),
//        .pixel_in_valid(rd_data_valid),
//        .pixel_out(row_pixel), .pixel_out_valid(row_valid)
//    );

//    // Pipelined Column Convolution
//    gaussian_col_conv #(
//        .WIDTH(WIDTH), .HEIGHT(HEIGHT),
//        .W0(W0), .W1(W1), .W2(W2), .W3(W3), .W4(W4), .SHIFT(SHIFT)
//    ) col_conv_inst (
//        .clk(clk), .rst(rst), .start(start),
//        .pixel_in(row_pixel), .pixel_in_valid(row_valid),
//        .pixel_out(blurred_pixel), .pixel_out_valid(blurred_valid),
//        .done(done)
//    );
//endmodule

`timescale 1ns / 1ps

module gaussian_blur_top #(
    parameter W0 = 1, W1 = 4, W2 = 6, W3 = 4, W4 = 1, parameter SHIFT = 4
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [7:0]  img_width,
    input  wire [7:0]  img_height,
    
    output reg  [13:0] rd_addr,
    input  wire [7:0]  rd_data,

    output wire [7:0]  blurred_pixel,
    output reg         blurred_valid,
    output reg         done
);
    wire [15:0] total_pixels = img_width * img_height;
    localparam IDLE = 2'd0, READ = 2'd1, FLUSH = 2'd2;
    
    reg [1:0]  state;
    reg [15:0] read_count;
    reg [15:0] flush_count;
    reg        rd_data_valid;
    reg [15:0] latency_counter;
    reg [15:0] out_valid_count;

    // Convolutions
    wire [7:0] row_pixel, col_pixel;
    wire       row_valid, col_valid;

    gaussian_row_conv #(.W0(W0), .W1(W1), .W2(W2), .W3(W3), .W4(W4), .SHIFT(SHIFT)) row_inst (
        .clk(clk), .rst(rst), .img_width(img_width), .img_height(img_height),
        .pixel_in(rd_data), .pixel_in_valid(rd_data_valid),
        .pixel_out(row_pixel), .pixel_out_valid(row_valid)
    );

    gaussian_col_conv #(.W0(W0), .W1(W1), .W2(W2), .W3(W3), .W4(W4), .SHIFT(SHIFT)) col_inst (
        .clk(clk), .rst(rst), .img_width(img_width), .img_height(img_height),
        .pixel_in(row_pixel), .pixel_in_valid(row_valid),
        .pixel_out(col_pixel), .pixel_out_valid(col_valid)
    );

    assign blurred_pixel = col_pixel;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            rd_addr <= 0; read_count <= 0; flush_count <= 0;
            rd_data_valid <= 0; latency_counter <= 0;
            out_valid_count <= 0; blurred_valid <= 0; done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= READ;
                        rd_addr <= 0; read_count <= 0; 
                        flush_count <= 0; latency_counter <= 0;
                        out_valid_count <= 0;
                    end
                end
                
                READ: begin
                    if (read_count < total_pixels) begin
                        rd_addr <= rd_addr + 1;
                        read_count <= read_count + 1;
                        rd_data_valid <= 1'b1;
                    end else begin
                        rd_data_valid <= 1'b0;
                        state <= FLUSH;
                    end
                end
                
                FLUSH: begin
                    // Continue pulsing valid to push last pixels through the pipeline
                    if (flush_count < (img_width * 3)) begin 
                        flush_count <= flush_count + 1;
                        rd_data_valid <= 1'b1;
                    end else begin
                        rd_data_valid <= 1'b0;
                    end
                end
            endcase

            // Latency Logic: A 5x5 filter requires ~2 rows of delay (256 pixels)
            blurred_valid <= 1'b0;
            if (col_valid) begin
                if (latency_counter < ((img_width * 2) + 4)) begin
                    latency_counter <= latency_counter + 1;
                end else if (out_valid_count < total_pixels) begin
                    blurred_valid <= 1'b1;
                    out_valid_count <= out_valid_count + 1;
                    if (out_valid_count == total_pixels - 1) begin
                        done <= 1'b1;
                        state <= IDLE;
                    end
                end
            end
        end
    end
endmodule
//`timescale 1ns / 1ps

//module gaussian_blur_top #(
//    parameter W0 = 1, W1 = 4, W2 = 6, W3 = 4, W4 = 1,
//    parameter SHIFT = 4
//)(
//    input  wire        clk,
//    input  wire        rst,
//    input  wire        start,
//    input  wire [7:0]  img_width,
//    input  wire [7:0]  img_height,
    
//    output reg [13:0]  rd_addr,
//    input  wire [7:0]  rd_data,

//    output wire [7:0]  blurred_pixel,
//    output reg         blurred_valid,
//    output reg         done
//);
//    wire [15:0] total_pixels = img_width * img_height;
    
//    wire [7:0] row_out;
//    wire       row_valid;
//    wire [7:0] col_out;
//    wire       col_valid;
    
//    reg        rd_data_valid;
//    reg [15:0] read_count;
//    reg [15:0] out_valid_count;
//    reg [15:0] latency_counter;

//    localparam IDLE = 0, RUN = 1, FLUSH = 2;
//    reg [1:0] state;

//    gaussian_row_conv #(.W0(W0), .W1(W1), .W2(W2), .W3(W3), .W4(W4), .SHIFT(SHIFT)) row_unit (
//        .clk(clk), .rst(rst), .img_width(img_width),
//        .pixel_in(rd_data), .pixel_in_valid(rd_data_valid),
//        .pixel_out(row_out), .pixel_out_valid(row_valid)
//    );

//    gaussian_col_conv #(.W0(W0), .W1(W1), .W2(W2), .W3(W3), .W4(W4), .SHIFT(SHIFT)) col_unit (
//        .clk(clk), .rst(rst), .img_width(img_width), .img_height(img_height),
//        .pixel_in(row_out), .pixel_in_valid(row_valid),
//        .pixel_out(col_out), .pixel_out_valid(col_valid)
//    );

//    assign blurred_pixel = col_out;

//    always @(posedge clk) begin
//        if (rst) begin
//            state <= IDLE;
//            rd_addr <= 0;
//            read_count <= 0;
//            out_valid_count <= 0;
//            latency_counter <= 0;
//            blurred_valid <= 0;
//            done <= 0;
//            rd_data_valid <= 0;
//        end else begin
//            case(state)
//                IDLE: begin
//                    done <= 0;
//                    if (start) begin 
//                        state <= RUN; 
//                        rd_addr <= 0; 
//                        read_count <= 0;
//                        out_valid_count <= 0;
//                        latency_counter <= 0;
//                    end
//                end

//                RUN: begin
//                    if (read_count < total_pixels) begin
//                        rd_addr <= rd_addr + 1;
//                        read_count <= read_count + 1;
//                        rd_data_valid <= 1'b1;
//                    end else begin
//                        state <= FLUSH;
//                    end
//                end

//                FLUSH: begin
//                    // Keep the pipeline moving until the output count is complete
//                    // We feed "dummy" pixels (0) with valid high to push the tail out
//                    if (out_valid_count < total_pixels) begin
//                        rd_data_valid <= 1'b1;
//                    end else begin
//                        rd_data_valid <= 1'b0;
//                        state <= IDLE;
//                        done <= 1'b1;
//                    end
//                end
//            endcase

//            // Latency Logic
//            if (col_valid) begin
//                if (latency_counter < ((img_width * 2) + 10)) begin
//                    latency_counter <= latency_counter + 1;
//                    blurred_valid <= 0;
//                end else if (out_valid_count < total_pixels) begin
//                    blurred_valid <= 1'b1;
//                    out_valid_count <= out_valid_count + 1;
//                end
//            end else begin
//                blurred_valid <= 0;
//            end
//        end
//    end
//endmodule

`timescale 1ns / 1ps

module gaussian_blur_top #(
    parameter W0 = 1, W1 = 4, W2 = 6, W3 = 4, W4 = 1,
    parameter SHIFT = 4
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [7:0]  img_width,   // Dynamic: 128 or 64
    input  wire [7:0]  img_height,  // Dynamic: 128 or 64
    
    output reg [13:0]  rd_addr,
    input  wire [7:0]  rd_data,

    output wire [7:0]  blurred_pixel,
    output reg         blurred_valid,
    output reg         done
);
    // Dynamic boundary limits
    wire [15:0] total_pixels = img_width * img_height;
    
    wire [7:0] row_out;
    wire       row_valid;
    wire [7:0] col_out;
    wire       col_valid;
    
    reg        rd_data_valid;
    reg [15:0] read_count;
    reg [15:0] out_valid_count;
    reg [15:0] latency_counter;

    localparam IDLE = 0, RUN = 1, FLUSH = 2;
    reg [1:0] state;

    // SURGICAL FIX: Force reset of counters on every new scale/octave
    wire conv_rst = rst | start;

    gaussian_row_conv #(.W0(W0), .W1(W1), .W2(W2), .W3(W3), .W4(W4), .SHIFT(SHIFT)) row_unit (
        .clk(clk), 
        .rst(conv_rst), 
        .img_width(img_width),
        .pixel_in(rd_data), 
        .pixel_in_valid(rd_data_valid),
        .pixel_out(row_out), 
        .pixel_out_valid(row_valid)
    );

    gaussian_col_conv #(.W0(W0), .W1(W1), .W2(W2), .W3(W3), .W4(W4), .SHIFT(SHIFT)) col_unit (
        .clk(clk), 
        .rst(conv_rst), 
        .img_width(img_width), 
        .img_height(img_height),
        .pixel_in(row_out), 
        .pixel_in_valid(row_valid),
        .pixel_out(col_out), 
        .pixel_out_valid(col_valid)
    );

    assign blurred_pixel = col_out;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            rd_addr <= 0;
            read_count <= 0;
            out_valid_count <= 0;
            latency_counter <= 0;
            blurred_valid <= 0;
            done <= 0;
            rd_data_valid <= 0;
        end else begin
            case(state)
                IDLE: begin
                    done <= 0;
                    if (start) begin 
                        state <= RUN; 
                        rd_addr <= 0; 
                        read_count <= 0;
                        out_valid_count <= 0;
                        latency_counter <= 0;
                    end
                end

                RUN: begin
                    if (read_count < total_pixels) begin
                        rd_addr <= rd_addr + 1;
                        read_count <= read_count + 1;
                        rd_data_valid <= 1'b1;
                    end else begin
                        state <= FLUSH;
                    end
                end

                FLUSH: begin
                    if (out_valid_count < total_pixels) begin
                        rd_data_valid <= 1'b1;
                    end else begin
                        rd_data_valid <= 1'b0;
                        state <= IDLE;
                        done <= 1'b1;
                    end
                end
            endcase

            if (col_valid) begin
                // Latency is now dynamically tied to the current octave width
                if (latency_counter < ((img_width * 2) + 10)) begin
                    latency_counter <= latency_counter + 1;
                    blurred_valid <= 0;
                end else if (out_valid_count < total_pixels) begin
                    blurred_valid <= 1'b1;
                    out_valid_count <= out_valid_count + 1;
                end
            end else begin
                blurred_valid <= 0;
            end
        end
    end
endmodule
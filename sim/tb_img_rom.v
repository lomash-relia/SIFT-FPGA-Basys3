`timescale 1ns / 1ps

module tb_img_rom;

    reg clk = 0;
    reg rst = 1;
    reg en  = 0;

    wire [7:0] pixel;

    img_rom #(.WIDTH(128), .HEIGHT(128)) dut (
        .clk   (clk),
        .rst   (rst),
        .en    (en),
        .pixel (pixel)
    );

    always #5 clk = ~clk;

    integer count;

    initial begin
        #20;
        rst = 0;
        en  = 1;

        @(posedge clk);  // 1-cycle latency

        count = 0;
        while (count < 32) begin
            @(posedge clk);
            $display("pixel[%0d] = 0x%02h (%0d)", count, pixel, pixel);
            count = count + 1;
        end

        $finish;
    end

endmodule
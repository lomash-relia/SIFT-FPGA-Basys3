`timescale 1ns / 1ps

//==============================================================================
// Testbench for Gaussian Blur Top (Separable 2D)
//==============================================================================
module tb_gaussian_blur_top;

    parameter WIDTH      = 128;
    parameter HEIGHT     = 128;
    parameter CLK_PERIOD = 10;

    reg        clk   = 0;
    reg        rst   = 1;
    reg        start = 0;

    wire [7:0] blurred_pixel;
    wire       blurred_valid;
    wire       done;

    always #(CLK_PERIOD/2) clk = ~clk;

    //==========================================================================
    // DUT
    //==========================================================================
    gaussian_blur_top #(
        .WIDTH  (WIDTH),
        .HEIGHT (HEIGHT)
    ) dut (
        .clk           (clk),
        .rst           (rst),
        .start         (start),
        .blurred_pixel (blurred_pixel),
        .blurred_valid (blurred_valid),
        .done          (done)
    );

    //==========================================================================
    // Output capture
    //==========================================================================
    integer output_file;
    integer pixel_count = 0;

    initial begin
        output_file = $fopen("blurred_image.hex", "w");

        // Reset
        rst = 1;
        start = 0;
        #(CLK_PERIOD * 5);
        rst = 0;
        #(CLK_PERIOD * 2);

        // Start
        $display("========================================");
        $display("Starting 2D Gaussian Blur (Separable)");
        $display("Image: %0dx%0d", WIDTH, HEIGHT);
        $display("Kernel: [1,4,6,4,1] x [1,4,6,4,1] / 256");
        $display("========================================");

        start = 1;
        #(CLK_PERIOD);
        start = 0;

        // Wait for completion
        wait(done);
        @(posedge clk);
        @(posedge clk);

        $display("========================================");
        $display("Processing Complete!");
        $display("Total pixels output: %0d", pixel_count);
        $display("Output saved to: blurred_image.hex");
        $display("========================================");

        $fclose(output_file);
        #(CLK_PERIOD * 10);
        $finish;
    end

    //==========================================================================
    // Capture blurred output
    //==========================================================================
    always @(posedge clk) begin
        if (blurred_valid) begin
            $fwrite(output_file, "%02h\n", blurred_pixel);

            if (pixel_count < 16 || pixel_count >= (WIDTH * HEIGHT - 10)) begin
                $display("Pixel[%0d] = 0x%02h (%0d)",
                         pixel_count, blurred_pixel, blurred_pixel);
            end
            else if (pixel_count == 16) begin
                $display("... (skipping middle pixels) ...");
            end

            pixel_count = pixel_count + 1;
        end
    end

    //==========================================================================
    // Timeout
    //==========================================================================
    initial begin
        #(CLK_PERIOD * 500000);
        $display("ERROR: Timeout!");
        $fclose(output_file);
        $finish;
    end

endmodule
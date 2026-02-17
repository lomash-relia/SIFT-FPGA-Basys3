`timescale 1ns / 1ps

module tb_dog_top;

    parameter WIDTH      = 128;
    parameter HEIGHT     = 128;
    parameter CLK_PERIOD = 10;

    reg         clk   = 0;
    reg         rst   = 1;
    reg         start = 0;

    wire signed [8:0] dog_pixel;
    wire              dog_valid;
    wire              done;

    // Clock Generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // DUT (Device Under Test)
    dog_top #(
        .WIDTH (WIDTH),
        .HEIGHT(HEIGHT)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .start    (start),
        .dog_pixel(dog_pixel),
        .dog_valid(dog_valid),
        .done     (done)
    );

    integer out_file;
    integer pixel_count = 0;

    initial begin
        out_file = $fopen("dog_output.txt", "w");
        
        // Reset sequence
        rst = 1; start = 0;
        #(CLK_PERIOD * 10);
        rst = 0;
        #(CLK_PERIOD * 5);

        // Trigger the process
        $display("Starting DoG Simulation...");
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        // Wait for completion
        wait(done);
        #(CLK_PERIOD * 20);
        
        $display("Simulation Finished. Total pixels: %0d", pixel_count);
        $fclose(out_file);
        $finish;
    end

    // Capture and Log Results
    always @(posedge clk) begin
        if (dog_valid) begin
            // Writing as signed decimal (%d) to see negative values
            $fwrite(out_file, "%d\n", dog_pixel);
            
            // Log every 2000th pixel to console for a heartbeat
            if (pixel_count % 2000 == 0) begin
                $display("Sample Pixel[%0d]: %d", pixel_count, dog_pixel);
            end
            
            pixel_count <= pixel_count + 1;
        end
    end

endmodule
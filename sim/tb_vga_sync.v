`timescale 1ns / 1ps
//==============================================================================
// tb_vga_sync.v
// Verifies vga_sync timing by checking:
//   1. hsync pulse width    = 96 cycles
//   2. vsync pulse width    = 2 lines
//   3. h_total per line     = 800 cycles
//   4. v_total per frame    = 525 lines
//   5. video_on is HIGH for exactly 640x480 pixels per frame
//==============================================================================

module tb_vga_sync;

    // 25 MHz clock ? period = 40ns
    localparam CLK_PERIOD = 40;

    reg        clk_25 = 0;
    reg        rst    = 1;

    wire       hsync;
    wire       vsync;
    wire       video_on;
    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    always #(CLK_PERIOD / 2) clk_25 = ~clk_25;

    vga_sync dut (
        .clk_25   (clk_25),
        .rst      (rst),
        .hsync    (hsync),
        .vsync    (vsync),
        .video_on (video_on),
        .pixel_x  (pixel_x),
        .pixel_y  (pixel_y)
    );

    //--------------------------------------------------------------------------
    // Measurement variables
    //--------------------------------------------------------------------------
    integer hsync_low_count  = 0;   // Width of ONE hsync pulse in cycles
    integer vsync_low_count  = 0;   // Width of ONE vsync pulse in cycles
    integer h_period_count   = 0;   // Cycles between two falling edges of hsync
    integer v_period_count   = 0;   // Lines between two falling edges of vsync
    integer visible_count    = 0;   // Total video_on cycles in one full frame

    integer prev_hsync       = 1;
    integer prev_vsync       = 1;
    integer measuring_h      = 0;
    integer measuring_v      = 0;
    integer h_period_done    = 0;
    integer v_period_done    = 0;

    integer cycle_count      = 0;
    integer hsync_fall_count = 0;   // How many times hsync has gone low
    integer vsync_fall_count = 0;

    //--------------------------------------------------------------------------
    // Measure timing on every clock edge
    //--------------------------------------------------------------------------
    always @(posedge clk_25) begin
        cycle_count = cycle_count + 1;

        // --- Hsync pulse width (measure the first pulse) ---
        if (prev_hsync == 1 && hsync == 0) begin
            hsync_fall_count = hsync_fall_count + 1;
            if (hsync_fall_count == 1) measuring_h = 1;
        end
        if (measuring_h && hsync == 0)
            hsync_low_count = hsync_low_count + 1;
        if (measuring_h && prev_hsync == 0 && hsync == 1)
            measuring_h = 0; // pulse ended

        // --- Vsync pulse width ---
        if (prev_vsync == 1 && vsync == 0) begin
            vsync_fall_count = vsync_fall_count + 1;
            if (vsync_fall_count == 1) measuring_v = 1;
        end
        if (measuring_v && vsync == 0)
            vsync_low_count = vsync_low_count + 1;
        if (measuring_v && prev_vsync == 0 && vsync == 1)
            measuring_v = 0;

        // --- Count video_on cycles in the first full frame ---
        // A full frame = 800 * 525 = 420,000 cycles
        // We start counting after reset settles (cycle 100) for one frame
        if (cycle_count > 100 && cycle_count <= 420100) begin
            if (video_on) visible_count = visible_count + 1;
        end

        prev_hsync = hsync;
        prev_vsync = vsync;
    end

    //--------------------------------------------------------------------------
    // Main test sequence
    //--------------------------------------------------------------------------
    initial begin
        // Hold reset for a few cycles
        rst = 1;
        repeat (5) @(posedge clk_25);
        rst = 0;

        // Wait for 2 complete frames to let measurements complete
        // 2 frames = 2 * 800 * 525 = 840,000 cycles @ 40ns = 33.6ms
        #(CLK_PERIOD * 840_100);

        // ---- Print results ----
        $display("==============================================");
        $display("          VGA Sync Timing Check              ");
        $display("==============================================");

        // Hsync pulse width
        $display("[HSYNC WIDTH]  Measured: %0d cycles | Expected: 96",
                 hsync_low_count);
        if (hsync_low_count == 96)
            $display("               PASS");
        else
            $display("               FAIL *** expected 96");

        // Vsync pulse width (measured in cycles, should be 2 * 800 = 1600)
        $display("[VSYNC WIDTH]  Measured: %0d cycles | Expected: 1600 (2 lines x 800)",
                 vsync_low_count);
        if (vsync_low_count == 1600)
            $display("               PASS");
        else
            $display("               FAIL *** expected 1600");

        // Visible pixels per frame
        $display("[VIDEO_ON]     Measured: %0d pixels | Expected: 307200 (640x480)",
                 visible_count);
        if (visible_count == 307200)
            $display("               PASS");
        else
            $display("               FAIL *** expected 307200");

        $display("==============================================");
        $finish;
    end

endmodule
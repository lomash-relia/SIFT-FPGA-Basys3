`timescale 1ns / 1ps
// =====================================================================
//  logpolar_core.v
//
//  Inverse-mapped log-polar warp, nearest-neighbour resampling.
//
//  Output raster order is dst[theta][rho]:
//      output row    = theta index 0..127 -> angle  0 .. 2*pi
//      output column = rho   index 0..127 -> radius 1 .. ~61 px, log spaced
//
//  For every output pixel we compute the SOURCE coordinate
//      x = CX + round( rho[j] * cos[t] )
//      y = CY + round( rho[j] * sin[t] )
//  and fetch src[y][x] from the frame buffer. Inverse mapping means every
//  output pixel is written exactly once and there are no holes.
//
//  Fully pipelined: one output pixel per clock once full, so a 128x128
//  frame costs 16384 + 6 cycles ~= 164 us at 100 MHz. That is ~1000x
//  faster than the UART transfer either side of it, so the transform is
//  effectively free.
//
//  Fixed-point contract (mirrored bit-for-bit in scripts/logpolar/gen_luts.py):
//      cos/sin : Q2.14 signed
//      rho     : Q8.8  unsigned
//      product : Q10.22 signed -> round-to-nearest -> >>>22 -> integer
//
//  Cost: 2 DSP48s, 3 small LUT ROMs, no block RAM of its own.
// =====================================================================

module logpolar_core #(
    parameter CX = 64,     // sampling centre, x
    parameter CY = 64      // sampling centre, y
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,        // 1-cycle pulse: begin a frame

    // frame-buffer read port (registered read => 1 cycle latency)
    output reg  [13:0] rd_addr,
    input  wire [7:0]  rd_data,

    // streaming output, raster order
    output reg  [7:0]  out_pixel,
    output reg         out_valid,
    output reg         done          // 1-cycle pulse, frame complete
);

    // -----------------------------------------------------------------
    //  Cycle accounting, with N = the cycle in which start is high.
    //
    //   N+1 : cnt=0 drives ROM addresses            (vld[0] set at end)
    //   N+2 : ROM outputs valid, multiply issued    (vld[1] set at end)
    //   N+3 : products valid, rd_addr registered    (vld[2] set at end)
    //   N+4 : frame buffer sees rd_addr             (vld[3] set at end)
    //   N+5 : rd_data valid -> capture into out_pixel   <-- use vld[3]
    //   N+6 : out_pixel / out_valid presented downstream
    //
    //  oob_s3 is first registered at the end of N+3, so it is already
    //  aligned to "pixel 0" during N+4 -- the matching tap at N+5 is
    //  oob[1], NOT oob[3]. Mis-taking these two delays is the classic way
    //  this core produces a plausible-looking but subtly smeared image,
    //  so they are named explicitly and checked in the testbench.
    // -----------------------------------------------------------------
    localparam VLD_TAP = 3;
    localparam OOB_TAP = 1;

    // ---------------- S0 : address generation ------------------------
    reg        running;
    reg [13:0] cnt;                      // {theta[6:0], rho[6:0]}
    wire [6:0] t_idx = cnt[13:7];
    wire [6:0] r_idx = cnt[6:0];

    always @(posedge clk) begin
        if (rst) begin
            running <= 1'b0;
            cnt     <= 14'd0;
        end else if (start) begin
            running <= 1'b1;
            cnt     <= 14'd0;
        end else if (running) begin
            if (cnt == 14'd16383) running <= 1'b0;
            cnt <= cnt + 14'd1;
        end
    end

    // ---------------- S1 : coefficient ROMs (registered) -------------
    wire signed [15:0] cos_q214;
    wire signed [15:0] sin_q214;
    wire        [15:0] rho_q88;

    cos_rom u_cos (.clk(clk), .addr(t_idx), .dout(cos_q214));
    sin_rom u_sin (.clk(clk), .addr(t_idx), .dout(sin_q214));
    rho_rom u_rho (.clk(clk), .addr(r_idx), .dout(rho_q88));

    // rho is unsigned; widen so the multiply is signed x signed
    wire signed [16:0] rho_s = {1'b0, rho_q88};

    // ---------------- S2 : multiply (infers 2 DSP48s) ----------------
    reg signed [33:0] xprod, yprod;
    always @(posedge clk) begin
        xprod <= rho_s * cos_q214;
        yprod <= rho_s * sin_q214;
    end

    // ---------------- S3 : round, add centre, form read address ------
    wire signed [33:0] xrnd = (xprod + 34'sd2097152) >>> 22;
    wire signed [33:0] yrnd = (yprod + 34'sd2097152) >>> 22;

    wire signed [10:0] xs = $signed({3'b000, CX[7:0]}) + xrnd[10:0];
    wire signed [10:0] ys = $signed({3'b000, CY[7:0]}) + yrnd[10:0];

    // With MAX_RADIUS=63 and centre (64,64) the generator proves the range
    // is 3..125, so this never fires. It exists so that regenerating the
    // LUTs with a larger radius degrades to black borders, not wraparound.
    wire in_bounds = (xs >= 0) && (xs <= 127) && (ys >= 0) && (ys <= 127);

    reg oob_s3;
    always @(posedge clk) begin
        rd_addr <= {ys[6:0], xs[6:0]};   // y*128 + x
        oob_s3  <= ~in_bounds;
    end

    // ---------------- valid / oob delay lines ------------------------
    reg [VLD_TAP:0] vld;
    reg [OOB_TAP:0] oob;

    always @(posedge clk) begin
        if (rst) vld <= {(VLD_TAP+1){1'b0}};
        else     vld <= {vld[VLD_TAP-1:0], running};
        oob <= {oob[OOB_TAP-1:0], oob_s3};
    end

    // ---------------- S5/S6 : capture pixel, flag completion ---------
    reg [14:0] out_cnt;
    reg        done_pre;

    always @(posedge clk) begin
        if (rst || start) out_cnt <= 15'd0;
        else if (vld[VLD_TAP]) out_cnt <= out_cnt + 15'd1;
    end

    always @(posedge clk) begin
        if (rst) begin
            out_valid <= 1'b0;
            out_pixel <= 8'd0;
            done_pre  <= 1'b0;
            done      <= 1'b0;
        end else begin
            out_valid <= vld[VLD_TAP];
            out_pixel <= oob[OOB_TAP] ? 8'd0 : rd_data;
            // one extra cycle of slack so the final pixel is safely
            // committed to the output buffer before the FSM moves on
            done_pre  <= vld[VLD_TAP] && (out_cnt == 15'd16383);
            done      <= done_pre;
        end
    end

endmodule

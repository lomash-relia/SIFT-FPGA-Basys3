`timescale 1ns / 1ps
// =====================================================================
//  top.v  --  Basys 3 log-polar transform accelerator
//
//  Wire protocol (same shape as the SIFT-FPGA-Basys3 DoG design, so the
//  same host-side habits apply):
//
//      PC  -> FPGA :  0x55  followed by 16384 raw grayscale bytes
//      FPGA -> PC  :  0x55  followed by 16384 transformed bytes
//
//  No *payload* byte may equal 0x55, or a resync after a dropped frame
//  can latch onto a pixel instead of a real header. The host clamps
//  0x55 -> 0x54 before sending; the FPGA does the same on the way back.
//
//  LED map:
//      led[0]  idle / waiting for sync
//      led[1]  receiving frame
//      led[2]  transforming
//      led[3]  transmitting
//      led[15] heartbeat -- proves clock and bitstream are alive
// =====================================================================

module top #(
    // 100 MHz / 108 = 925.9 kbaud, within 0.5% of 921600. Matches the
    // reference design. For 115200 baud use 868.
    parameter CLKS_PER_BIT = 108
)(
    input  wire        clk,           // W5, 100 MHz
    input  wire        uart_txd_in,   // B18, data from PC
    input  wire        btnC,          // U18, reset
    output wire        uart_rxd_out,  // A18, data to PC
    output reg  [15:0] led
);

    localparam SYNC_BYTE = 8'h55;

    localparam S_WAIT_SYNC = 3'd0;
    localparam S_RX_FRAME  = 3'd1;
    localparam S_TRANSFORM = 3'd2;
    localparam S_TX_SYNC   = 3'd3;
    localparam S_TX_HDRWT  = 3'd4;   // waiting for the header byte to finish
    localparam S_TX_FETCH  = 3'd5;   // BRAM read latency cycle
    localparam S_TX_ISSUE  = 3'd6;   // latch pixel, launch it
    localparam S_TX_WAIT   = 3'd7;   // wait for the byte to clear the wire

    reg [2:0] state = S_WAIT_SYNC;

    // ---------------- reset synchroniser -----------------------------
    // btnC is asynchronous and bouncy; feeding it raw into a pipeline
    // that drives block RAM is a good way to get one corrupt frame per
    // press.
    reg [2:0] rst_sync = 3'b111;
    wire rst = rst_sync[2];
    always @(posedge clk) rst_sync <= {rst_sync[1:0], btnC};

    // ---------------- UART -------------------------------------------
    wire [7:0] rx_data;
    wire       rx_ready;

    reg        tx_start = 1'b0;
    reg  [7:0] tx_data  = 8'd0;
    wire       tx_active, tx_done;

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
        .clk(clk), .rx_serial(uart_txd_in),
        .rx_data(rx_data), .rx_ready(rx_ready)
    );

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .clk(clk), .tx_start(tx_start), .tx_data(tx_data),
        .tx_active(tx_active), .tx_serial(uart_rxd_out), .tx_done(tx_done)
    );

    // uart_rx already pulses rx_ready for one cycle; the edge detect is
    // cheap insurance against that ever changing underneath us.
    reg  rx_ready_d = 1'b0;
    wire rx_strobe = rx_ready & ~rx_ready_d;
    always @(posedge clk) rx_ready_d <= rx_ready;

    // ---------------- buffers and core -------------------------------
    reg [13:0] rx_ptr = 14'd0;
    reg [13:0] tx_ptr = 14'd0;

    wire [13:0] core_rd_addr;
    wire [7:0]  core_rd_data;
    wire [7:0]  core_pixel;
    wire        core_valid, core_done;

    reg start_core = 1'b0;

    // input frame: written by UART RX, read by the transform core
    frame_buffer u_in (
        .clk(clk),
        .we(rx_strobe && state == S_RX_FRAME),
        .wr_addr(rx_ptr), .wr_data(rx_data),
        .rd_addr(core_rd_addr), .rd_data(core_rd_data)
    );

    logpolar_core #(.CX(64), .CY(64)) u_core (
        .clk(clk), .rst(rst), .start(start_core),
        .rd_addr(core_rd_addr), .rd_data(core_rd_data),
        .out_pixel(core_pixel), .out_valid(core_valid), .done(core_done)
    );

    // output frame: written by the core, read by UART TX
    reg [13:0] out_wr_ptr = 14'd0;
    wire [7:0] tx_pixel;

    always @(posedge clk) begin
        if (rst || start_core) out_wr_ptr <= 14'd0;
        else if (core_valid)   out_wr_ptr <= out_wr_ptr + 14'd1;
    end

    frame_buffer u_out (
        .clk(clk),
        .we(core_valid), .wr_addr(out_wr_ptr), .wr_data(core_pixel),
        .rd_addr(tx_ptr), .rd_data(tx_pixel)
    );

    // protect the sync byte on the return path too
    wire [7:0] tx_byte = (tx_pixel == SYNC_BYTE) ? 8'h54 : tx_pixel;

    // ---------------- heartbeat --------------------------------------
    reg [25:0] hb = 26'd0;
    always @(posedge clk) hb <= hb + 26'd1;

    // ---------------- main FSM ---------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            state      <= S_WAIT_SYNC;
            rx_ptr     <= 14'd0;
            tx_ptr     <= 14'd0;
            start_core <= 1'b0;
            tx_start   <= 1'b0;
            led        <= 16'd0;
        end else begin
            start_core <= 1'b0;      // default: single-cycle pulses
            tx_start   <= 1'b0;

            led        <= 16'd0;
            led[15]    <= hb[25];

            case (state)
                // ---- wait for the host's sync byte ------------------
                S_WAIT_SYNC: begin
                    led[0] <= 1'b1;
                    rx_ptr <= 14'd0;
                    if (rx_strobe && rx_data == SYNC_BYTE)
                        state <= S_RX_FRAME;
                end

                // ---- soak up exactly 16384 payload bytes ------------
                S_RX_FRAME: begin
                    led[1] <= 1'b1;
                    if (rx_strobe) begin
                        if (rx_ptr == 14'd16383) begin
                            rx_ptr     <= 14'd0;
                            start_core <= 1'b1;
                            state      <= S_TRANSFORM;
                        end else begin
                            rx_ptr <= rx_ptr + 14'd1;
                        end
                    end
                end

                // ---- ~164 us of warping ----------------------------
                S_TRANSFORM: begin
                    led[2] <= 1'b1;
                    if (core_done) begin
                        tx_ptr <= 14'd0;
                        state  <= S_TX_SYNC;
                    end
                end

                // ---- send the reply header -------------------------
                S_TX_SYNC: begin
                    led[3] <= 1'b1;
                    if (!tx_active) begin
                        tx_data  <= SYNC_BYTE;
                        tx_start <= 1'b1;
                        state    <= S_TX_HDRWT;
                    end
                end

                // header gone; tx_ptr is still 0 so pixel 0 is not skipped
                S_TX_HDRWT: begin
                    led[3] <= 1'b1;
                    if (tx_done) state <= S_TX_FETCH;
                end

                // ---- rd_addr is already tx_ptr; burn the BRAM cycle -
                S_TX_FETCH: begin
                    led[3] <= 1'b1;
                    state  <= S_TX_ISSUE;
                end

                // ---- tx_pixel is valid now: latch and launch -------
                S_TX_ISSUE: begin
                    led[3]   <= 1'b1;
                    tx_data  <= tx_byte;
                    tx_start <= 1'b1;
                    state    <= S_TX_WAIT;
                end

                // ---- one byte on the wire --------------------------
                S_TX_WAIT: begin
                    led[3] <= 1'b1;
                    if (tx_done) begin
                        if (tx_ptr == 14'd16383) begin
                            state <= S_WAIT_SYNC;   // 16384 pixels sent
                        end else begin
                            tx_ptr <= tx_ptr + 14'd1;
                            state  <= S_TX_FETCH;
                        end
                    end
                end

                default: state <= S_WAIT_SYNC;
            endcase
        end
    end

endmodule

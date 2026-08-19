`timescale 1ns / 1ps
// =====================================================================
//  tb_top.v -- end-to-end test: bit-bangs a real UART frame into top.v,
//  captures the serial reply, and dumps it for comparison against the
//  Python golden model.
//
//  A short CLKS_PER_BIT is used so the sim finishes quickly; the logic
//  under test is unchanged.
// =====================================================================

module tb_top;

    localparam CPB = 8;              // clocks per bit (sim only)
    localparam integer NPIX = 16384;

    reg clk = 0;
    always #5 clk = ~clk;            // 100 MHz

    reg  btnC = 1;
    reg  rx_line = 1;                // PC -> FPGA
    wire tx_line;                    // FPGA -> PC
    wire [15:0] led;

    top #(.CLKS_PER_BIT(CPB)) dut (
        .clk(clk),
        .uart_txd_in(rx_line),
        .btnC(btnC),
        .uart_rxd_out(tx_line),
        .led(led)
    );

    reg [7:0] src   [0:NPIX-1];
    reg [7:0] recvd [0:NPIX-1];

    integer i;
    integer fd;
    integer nrecv;
    reg [7:0] hdr;

    // ---------------- UART transmit (host side) ----------------------
    task send_byte(input [7:0] b);
        integer k;
        begin
            rx_line = 0;                         // start
            repeat (CPB) @(posedge clk);
            for (k = 0; k < 8; k = k + 1) begin
                rx_line = b[k];
                repeat (CPB) @(posedge clk);
            end
            rx_line = 1;                         // stop
            repeat (CPB) @(posedge clk);
        end
    endtask

    // ---------------- UART receive (host side) -----------------------
    task recv_byte(output [7:0] b);
        integer k;
        begin
            @(negedge tx_line);                  // start bit
            repeat (CPB + CPB/2) @(posedge clk); // centre of bit 0
            for (k = 0; k < 8; k = k + 1) begin
                b[k] = tx_line;
                repeat (CPB) @(posedge clk);
            end
            // we are now inside the stop bit; return
        end
    endtask

    // ---------------- capture thread ---------------------------------
    initial begin
        nrecv = 0;
        recv_byte(hdr);
        if (hdr !== 8'h55) begin
            $display("FAIL: reply header was %02x, expected 55", hdr);
            $finish;
        end
        $display("got reply header 0x55");
        for (nrecv = 0; nrecv < NPIX; nrecv = nrecv + 1)
            recv_byte(recvd[nrecv]);

        fd = $fopen("sim/hw_out.hex", "w");
        for (i = 0; i < NPIX; i = i + 1) $fwrite(fd, "%02x\n", recvd[i]);
        $fclose(fd);
        $display("captured %0d payload bytes -> sim/hw_out.hex", NPIX);
        $finish;
    end

    // ---------------- stimulus ---------------------------------------
    initial begin
        $readmemh("sim/src_img.hex", src);

        repeat (20) @(posedge clk);
        btnC = 0;
        repeat (20) @(posedge clk);

        $display("sending sync + %0d pixels...", NPIX);
        send_byte(8'h55);
        for (i = 0; i < NPIX; i = i + 1) send_byte(src[i]);
        $display("frame sent, waiting for reply...");
    end

    // ---------------- watchdog ---------------------------------------
    initial begin
        #500_000_000;
        $display("FAIL: timeout, only %0d bytes received", nrecv);
        $finish;
    end

endmodule

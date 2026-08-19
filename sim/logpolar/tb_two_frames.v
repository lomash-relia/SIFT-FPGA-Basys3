`timescale 1ns / 1ps
// Back-to-back frame test with proper request/response handshaking.
// The design has no RX FIFO, so the host MUST wait for the reply before
// sending the next frame. This TB models that discipline.
module tb_two_frames;
    localparam CPB = 8;
    localparam integer NPIX = 16384;
    reg clk = 0; always #5 clk = ~clk;
    reg btnC = 1, rx_line = 1; wire tx_line; wire [15:0] led;
    top #(.CLKS_PER_BIT(CPB)) dut (.clk(clk), .uart_txd_in(rx_line),
        .btnC(btnC), .uart_rxd_out(tx_line), .led(led));
    reg [7:0] src[0:NPIX-1]; reg [7:0] f1[0:NPIX-1]; reg [7:0] f2[0:NPIX-1];
    integer i, k, nmis; reg [7:0] hdr;
    task send_byte(input [7:0] b); integer j; begin
        rx_line=0; repeat(CPB) @(posedge clk);
        for(j=0;j<8;j=j+1) begin rx_line=b[j]; repeat(CPB) @(posedge clk); end
        rx_line=1; repeat(CPB) @(posedge clk); end
    endtask
    task recv_byte(output [7:0] b); integer j; begin
        @(negedge tx_line); repeat(CPB+CPB/2) @(posedge clk);
        for(j=0;j<8;j=j+1) begin b[j]=tx_line; repeat(CPB) @(posedge clk); end end
    endtask
    task send_frame; begin
        send_byte(8'h55);
        for(i=0;i<NPIX;i=i+1) send_byte(src[i]);
    end endtask
    initial begin
        $readmemh("sim/src_img.hex", src);
        repeat(20) @(posedge clk); btnC=0; repeat(20) @(posedge clk);

        send_frame; $display("frame 1 sent");
        recv_byte(hdr);
        if (hdr!==8'h55) begin $display("FAIL hdr1=%02x",hdr); $finish; end
        for(k=0;k<NPIX;k=k+1) recv_byte(f1[k]);
        $display("frame 1 reply received");

        send_frame; $display("frame 2 sent (no reset in between)");
        recv_byte(hdr);
        if (hdr!==8'h55) begin $display("FAIL hdr2=%02x",hdr); $finish; end
        for(k=0;k<NPIX;k=k+1) recv_byte(f2[k]);
        $display("frame 2 reply received");

        nmis=0;
        for(k=0;k<NPIX;k=k+1) if (f1[k]!==f2[k]) nmis=nmis+1;
        if (nmis==0) $display("PASS - frame 2 bit-identical to frame 1");
        else $display("FAIL - %0d pixels differ between consecutive frames",nmis);
        $finish;
    end
    initial begin #1500_000_000; $display("FAIL: timeout"); $finish; end
endmodule

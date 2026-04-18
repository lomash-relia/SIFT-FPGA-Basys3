`timescale 1ns / 1ps

module uart_rx # (
    parameter CLKS_PER_BIT = 108
)(
    input  wire       clk,
    input  wire       rx_serial,
    output reg        rx_ready,
    output reg [7:0]  rx_data
);

    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    reg [1:0] state = IDLE;
    reg [7:0] clk_count = 0;
    reg [2:0] bit_index = 0;

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                rx_ready <= 1'b0;
                clk_count <= 0;
                bit_index <= 0;
                if (rx_serial == 1'b0) // Start bit detected (low)
                    state <= START;
            end

            START: begin
                // Sample in the middle of the start bit to verify it's real
                if (clk_count == (CLKS_PER_BIT / 2)) begin
                    if (rx_serial == 1'b0) begin
                        clk_count <= 0;
                        state <= DATA;
                    end else
                        state <= IDLE;
                end else begin
                    clk_count <= clk_count + 1;
                end
            end

            DATA: begin
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    rx_data[bit_index] <= rx_serial;
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                end
            end

            STOP: begin
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    rx_ready <= 1'b1; // Byte received!
                    clk_count <= 0;
                    state <= IDLE;
                end
            end

            default: state <= IDLE;
        endcase
    end
endmodule
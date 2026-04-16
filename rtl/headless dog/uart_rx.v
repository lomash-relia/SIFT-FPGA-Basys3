`timescale 1ns / 1ps

module uart_rx #(
    parameter CLKS_PER_BIT = 108
)(
    input clk,
    input rx_serial,
    output reg [7:0] rx_data = 0,
    output reg rx_ready = 0
);

    parameter IDLE = 2'b00, START = 2'b01, DATA = 2'b10, STOP = 2'b11;
    reg [1:0] state = IDLE;
    reg [7:0] clk_count = 0;
    reg [2:0] bit_index = 0;

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                rx_ready <= 0;
                clk_count <= 0;
                bit_index <= 0;
                if (rx_serial == 0) // Start bit detected
                    state <= START;
                else
                    state <= IDLE;
            end

            START: begin
                if (clk_count == (CLKS_PER_BIT / 2)) begin
                    if (rx_serial == 0) begin // Verify it's still low
                        clk_count <= 0;
                        state <= DATA;
                    end else
                        state <= IDLE;
                end else begin
                    clk_count <= clk_count + 1;
                    state <= START;
                end
            end

            DATA: begin
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                    state <= DATA;
                end else begin
                    clk_count <= 0;
                    rx_data[bit_index] <= rx_serial;
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                        state <= DATA;
                    end else begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                end
            end

            STOP: begin
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                    state <= STOP;
                end else begin
                    rx_ready <= 1; // Signal byte received
                    clk_count <= 0;
                    state <= IDLE;
                end
            end
            
            default: state <= IDLE;
        endcase
    end
endmodule
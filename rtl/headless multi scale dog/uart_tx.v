`timescale 1ns / 1ps

module uart_tx # (
    parameter CLKS_PER_BIT = 108
)(
    input  wire       clk,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    output reg        tx_active,
    output reg        tx_serial,
    output reg        tx_done
);

    localparam IDLE  = 2'b00,
               START = 2'b01,
               DATA  = 2'b10,
               STOP  = 2'b11;

    reg [1:0] state = IDLE;
    reg [7:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] tx_data_reg = 0;

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                tx_serial <= 1'b1; // Drive high when idle
                tx_done   <= 1'b0;
                tx_active <= 1'b0;
                clk_count <= 0;
                bit_index <= 0;
                if (tx_start) begin
                    tx_data_reg <= tx_data;
                    tx_active   <= 1'b1;
                    state       <= START;
                end
            end

            START: begin
                tx_serial <= 1'b0; // Start bit
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    state     <= DATA;
                end
            end

            DATA: begin
                tx_serial <= tx_data_reg[bit_index];
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        bit_index <= 0;
                        state     <= STOP;
                    end
                end
            end

            STOP: begin
                tx_serial <= 1'b1; // Stop bit
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    tx_done   <= 1'b1;
                    tx_active <= 1'b0;
                    clk_count <= 0;
                    state     <= IDLE;
                end
            end

            default: state <= IDLE;
        endcase
    end
endmodule
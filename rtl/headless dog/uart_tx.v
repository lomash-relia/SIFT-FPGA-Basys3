`timescale 1ns / 1ps

module uart_tx #(parameter CLKS_PER_BIT = 108)(
    input wire clk,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx_active,
    output reg tx_serial,
    output reg tx_done
);

    localparam S_IDLE  = 3'd0;
    localparam S_START = 3'd1;
    localparam S_DATA  = 3'd2;
    localparam S_STOP  = 3'd3;

    reg [2:0] state = S_IDLE;
    reg [7:0] clock_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] tx_data_reg = 0;

    always @(posedge clk) begin
        case (state)
            S_IDLE: begin
                tx_serial <= 1'b1; // Idle is high
                tx_done <= 1'b0;
                tx_active <= 1'b0;
                clock_count <= 0;
                bit_index <= 0;
                
                if (tx_start) begin
                    tx_active <= 1'b1;
                    tx_data_reg <= tx_data;
                    state <= S_START;
                end
            end
            
            S_START: begin
                tx_serial <= 1'b0; // Start bit is low
                if (clock_count < CLKS_PER_BIT - 1) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                    state <= S_DATA;
                end
            end
            
            S_DATA: begin
                tx_serial <= tx_data_reg[bit_index];
                if (clock_count < CLKS_PER_BIT - 1) begin
                    clock_count <= clock_count + 1;
                end else begin
                    clock_count <= 0;
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        bit_index <= 0;
                        state <= S_STOP;
                    end
                end
            end
            
            S_STOP: begin
                tx_serial <= 1'b1; // Stop bit is high
                if (clock_count < CLKS_PER_BIT - 1) begin
                    clock_count <= clock_count + 1;
                end else begin
                    tx_done <= 1'b1;
                    tx_active <= 1'b0;
                    state <= S_IDLE;
                end
            end
            
            default: state <= S_IDLE;
        endcase
    end
endmodule
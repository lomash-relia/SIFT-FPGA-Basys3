`timescale 1ns / 1ps

module top(
    input wire clk,              // 100MHz
    input wire uart_txd_in,      // B18 (From PC)
    input wire btnC,             // Reset
    output wire uart_rxd_out,    // A18 (To PC)
    output reg [15:0] led        // Status LEDs
);

    // --- State Machine Definitions ---
    localparam S_WAIT_SYNC = 3'd0;
    localparam S_RX_FRAME  = 3'd1;
    localparam S_PROCESS   = 3'd2;
    localparam S_TX_SYNC   = 3'd3;
    localparam S_TX_FRAME  = 3'd4;
    
    reg [2:0] state = S_WAIT_SYNC;

    // --- Signals ---
    wire [7:0] rx_data;
    wire rx_ready;
    wire is_sync = (rx_data == 8'h55 && rx_ready);

    reg [14:0] rx_ptr = 0;
    reg [14:0] tx_ptr = 0;
    
    reg  tx_start = 0;
    reg  [7:0] tx_data = 0;
    wire tx_active;
    wire tx_done;

    reg  start_dog = 0;
    wire dog_done;

    wire [13:0] rd_addr_dog;
    wire [7:0]  raw_pixel_dog;
    wire signed [8:0] dog_pixel_out;
    wire dog_valid_out;
    wire [7:0] tx_pixel_bus;

    // --- 1. UART Modules (921600 Baud = 100MHz / 108) ---
    uart_rx #(.CLKS_PER_BIT(108)) rx_inst (
        .clk(clk), .rx_serial(uart_txd_in), .rx_data(rx_data), .rx_ready(rx_ready)
    );

    uart_tx #(.CLKS_PER_BIT(108)) tx_inst (
        .clk(clk), .tx_start(tx_start), .tx_data(tx_data), 
        .tx_active(tx_active), .tx_serial(uart_rxd_out), .tx_done(tx_done)
    );

    // --- 2. Memory & Math Core ---
    input_buffer in_buf (
        .clk(clk), .we(state == S_RX_FRAME && rx_ready), 
        .wr_addr(rx_ptr[13:0]), .data_in(rx_data),
        .rd_addr(rd_addr_dog), .data_out(raw_pixel_dog)
    );

    dog_top core (
        .clk(clk), .rst(btnC), .start(start_dog), 
        .rd_addr(rd_addr_dog), .rd_data(raw_pixel_dog),
        .dog_pixel(dog_pixel_out), .dog_valid(dog_valid_out), .done(dog_done)
    );

    output_buffer out_buf (
        .clk(clk), .rst(btnC || start_dog), // Reset pointer when new processing starts
        .dog_valid(dog_valid_out), .dog_pixel(dog_pixel_out),
        .rd_addr(tx_ptr[13:0]), .out_pixel(tx_pixel_bus)
    );

    // --- 3. Main Control FSM ---
    always @(posedge clk) begin
        if (btnC) begin
            state <= S_WAIT_SYNC;
            rx_ptr <= 0;
            tx_ptr <= 0;
            start_dog <= 0;
            tx_start <= 0;
            led <= 16'b0;
        end else begin
            // Default pulldowns
            start_dog <= 0;
            tx_start <= 0;
            
            case (state)
                S_WAIT_SYNC: begin
                    led[0] <= 1'b1; // Waiting for PC
                    if (is_sync) begin
                        state <= S_RX_FRAME;
                        rx_ptr <= 0;
                    end
                end
                
                S_RX_FRAME: begin
                    led[1] <= 1'b1; // Receiving
                    if (rx_ready) begin
                        rx_ptr <= rx_ptr + 1;
                        if (rx_ptr == 16383) begin
                            state <= S_PROCESS;
                            start_dog <= 1'b1; // Trigger DoG Core
                        end
                    end
                end
                
                S_PROCESS: begin
                    led[2] <= 1'b1; // Processing Math
                    if (dog_done) begin
                        state <= S_TX_SYNC;
                    end
                end
                
                S_TX_SYNC: begin
                    led[3] <= 1'b1; // Sending Sync back
                    if (!tx_active) begin
                        tx_data <= 8'h55;
                        tx_start <= 1'b1;
                        state <= S_TX_FRAME;
                        tx_ptr <= 0;
                    end
                end
                
                S_TX_FRAME: begin
                    led[4] <= 1'b1; // Sending Frame
                    if (tx_done) begin
                        tx_ptr <= tx_ptr + 1;
                        if (tx_ptr == 16384) begin
                            state <= S_WAIT_SYNC; // Frame complete, restart
                            led <= 16'b0;
                        end else begin
                            tx_data <= tx_pixel_bus;
                            tx_start <= 1'b1;
                        end
                    end
                end
            endcase
        end
    end
endmodule
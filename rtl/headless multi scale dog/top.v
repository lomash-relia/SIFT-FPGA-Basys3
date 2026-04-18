`timescale 1ns / 1ps

module top(
    input  wire        clk,           // 100MHz from Basys 3
    input  wire        uart_txd_in,   // Receive from PC
    input  wire        btnC,          // Hardware Reset
    output wire        uart_rxd_out,  // Transmit to PC
    output reg [15:0]  led            // Debug LEDs
);

    localparam BAUD_DIV = 108;       // 921,600 baud @ 100MHz

    // --- Dynamic Octave Control ---
    reg octave; // 0 = 128x128, 1 = 64x64
    wire [14:0] current_size = (octave == 0) ? 15'd16384 : 15'd4096;
    wire [7:0]  current_dim  = (octave == 0) ? 8'd128    : 8'd64;

    // --- FSM States ---
    localparam S_WAIT_SYNC  = 5'd0,
               S_RX         = 5'd1,
               
               // Scale 1
               S_BLUR_1     = 5'd2,
               S_TX_SYNC_0  = 5'd3,
               S_TX_WAIT_0  = 5'd4,
               S_TX_DOG_0   = 5'd5,
               
               // Scale 2
               S_BLUR_2     = 5'd6,
               S_TX_SYNC_1  = 5'd7,
               S_TX_WAIT_1  = 5'd8,
               S_TX_DOG_1   = 5'd9,
               
               // Scale 3 (Overwrite Bank A)
               S_BLUR_3     = 5'd10,
               S_TX_SYNC_2  = 5'd11,
               S_TX_WAIT_2  = 5'd12,
               S_TX_DOG_2   = 5'd13,
               
               // Octave Bridge (Downsampling)
               S_DS_WAIT    = 5'd14,
               S_DS_WRITE   = 5'd15,
               S_COPY_WAIT  = 5'd16,
               S_COPY_WRITE = 5'd17;

    reg [4:0] state = S_WAIT_SYNC;

    // --- Memory Signals ---
    reg [13:0] ram_addr;
    reg [7:0]  ram_din;
    reg        we_a, we_b, we_c;
    wire [7:0] dout_a, dout_b, dout_c;
    reg [7:0]  core_in_pixel;
    
    // --- Module Instances ---
    wire [7:0] rx_data;
    wire       rx_ready;
    uart_rx #(.CLKS_PER_BIT(BAUD_DIV)) rx_unit (
        .clk(clk), .rx_serial(uart_txd_in), .rx_data(rx_data), .rx_ready(rx_ready)
    );

    reg        tx_start;
    reg [7:0]  tx_data;
    wire       tx_done, tx_active;
    uart_tx #(.CLKS_PER_BIT(BAUD_DIV)) tx_unit (
        .clk(clk), .tx_start(tx_start), .tx_data(tx_data), .tx_serial(uart_rxd_out), .tx_done(tx_done), .tx_active(tx_active)
    );

    bram_bank bank_a (.clk(clk), .we(we_a), .addr(ram_addr), .din(ram_din), .dout(dout_a));
    bram_bank bank_b (.clk(clk), .we(we_b), .addr(ram_addr), .din(ram_din), .dout(dout_b));
    bram_bank bank_c (.clk(clk), .we(we_c), .addr(ram_addr), .din(ram_din), .dout(dout_c));

    reg         core_start;
    wire [13:0] core_rd_addr;
    wire [7:0]  core_out_pixel;
    wire        core_out_valid, core_done;
    
    gaussian_blur_top blur_core (
        .clk(clk), .rst(btnC), .start(core_start),
        .img_width(current_dim), .img_height(current_dim), // DYNAMIC Dimensions
        .rd_addr(core_rd_addr), .rd_data(core_in_pixel),
        .blurred_pixel(core_out_pixel), .blurred_valid(core_out_valid), .done(core_done)
    );

    // --- FSM Control Logic ---
    reg [14:0] ptr;
    reg [5:0]  ds_row, ds_col; // For downsampling (max 64)

    always @(posedge clk) begin
        if (btnC) begin
            state <= S_WAIT_SYNC;
            led <= 16'b0; octave <= 0; ptr <= 0;
            tx_start <= 0; core_start <= 0;
            ds_row <= 0; ds_col <= 0;
        end else begin
            we_a <= 0; we_b <= 0; we_c <= 0;
            core_start <= 0; tx_start <= 0;

            case (state)
                S_WAIT_SYNC: begin
                    if (rx_ready && rx_data == 8'h55) begin
                        state <= S_RX; ptr <= 0; octave <= 0;
                        led[0] <= 1'b1;
                    end
                end

                S_RX: begin
                    if (rx_ready) begin
                        ram_addr <= ptr[13:0]; ram_din <= rx_data; we_a <= 1'b1;
                        if (ptr == 16383) begin
                            state <= S_BLUR_1; core_start <= 1'b1; ptr <= 0;
                        end else ptr <= ptr + 1;
                    end
                end

                // --- SCALE 1: Blur 1 (A -> B), DoG 0 (A - B) ---
                S_BLUR_1: begin
                    ram_addr <= core_rd_addr; core_in_pixel <= dout_a; 
                    if (core_out_valid) begin
                        ram_addr <= ptr[13:0]; ram_din <= core_out_pixel; we_b <= 1'b1; ptr <= ptr + 1;
                    end
                    if (core_done) begin state <= S_TX_SYNC_0; ptr <= 0; end
                end
                
                S_TX_SYNC_0: if (!tx_active && !tx_start) begin tx_data <= 8'h55; tx_start <= 1'b1; state <= S_TX_WAIT_0; end
                
                S_TX_WAIT_0: begin ram_addr <= ptr[13:0]; state <= S_TX_DOG_0; end
                
                S_TX_DOG_0: begin
                    if (!tx_active && !tx_start) begin
                        tx_data <= 8'd128 + ($signed({1'b0, dout_a}) - $signed({1'b0, dout_b}));
                        tx_start <= 1'b1; ptr <= ptr + 1;
                        if (ptr == current_size) begin state <= S_BLUR_2; core_start <= 1'b1; ptr <= 0; end
                        else state <= S_TX_WAIT_0; 
                    end
                end

                // --- SCALE 2: Blur 2 (B -> C), DoG 1 (B - C) ---
                S_BLUR_2: begin
                    led[1] <= 1'b1;
                    ram_addr <= core_rd_addr; core_in_pixel <= dout_b; 
                    if (core_out_valid) begin
                        ram_addr <= ptr[13:0]; ram_din <= core_out_pixel; we_c <= 1'b1; ptr <= ptr + 1;
                    end
                    if (core_done) begin state <= S_TX_SYNC_1; ptr <= 0; end
                end
                
                S_TX_SYNC_1: if (!tx_active && !tx_start) begin tx_data <= 8'h55; tx_start <= 1'b1; state <= S_TX_WAIT_1; end
                
                S_TX_WAIT_1: begin ram_addr <= ptr[13:0]; state <= S_TX_DOG_1; end
                
                S_TX_DOG_1: begin
                    if (!tx_active && !tx_start) begin
                        tx_data <= 8'd128 + ($signed({1'b0, dout_b}) - $signed({1'b0, dout_c}));
                        tx_start <= 1'b1; ptr <= ptr + 1;
                        if (ptr == current_size) begin state <= S_BLUR_3; core_start <= 1'b1; ptr <= 0; end
                        else state <= S_TX_WAIT_1; 
                    end
                end

                // --- SCALE 3: Blur 3 (C -> A), DoG 2 (C - A) ---
                S_BLUR_3: begin
                    led[2] <= 1'b1;
                    ram_addr <= core_rd_addr; core_in_pixel <= dout_c; 
                    if (core_out_valid) begin
                        ram_addr <= ptr[13:0]; ram_din <= core_out_pixel; we_a <= 1'b1; ptr <= ptr + 1;
                    end
                    if (core_done) begin state <= S_TX_SYNC_2; ptr <= 0; end
                end
                
                S_TX_SYNC_2: if (!tx_active && !tx_start) begin tx_data <= 8'h55; tx_start <= 1'b1; state <= S_TX_WAIT_2; end
                
                S_TX_WAIT_2: begin ram_addr <= ptr[13:0]; state <= S_TX_DOG_2; end
                
                S_TX_DOG_2: begin
                    if (!tx_active && !tx_start) begin
                        tx_data <= 8'd128 + ($signed({1'b0, dout_c}) - $signed({1'b0, dout_a}));
                        tx_start <= 1'b1; ptr <= ptr + 1;
                        
                        if (ptr == current_size) begin
                            if (octave == 0) begin
                                state <= S_DS_WAIT; ptr <= 0; ds_row <= 0; ds_col <= 0;
                            end else begin
                                state <= S_WAIT_SYNC; octave <= 0; led <= 16'b0; // End of Frame
                            end
                        end
                        else state <= S_TX_WAIT_2; 
                    end
                end

                // --- OCTAVE BRIDGE: Downsample A to B, Copy B to A ---
                S_DS_WAIT: begin
                    // Address calculation: Skip every other pixel and row (read 128x128 space)
                    ram_addr <= {ds_row[5:0], 1'b0, ds_col[5:0], 1'b0}; 
                    state <= S_DS_WRITE;
                end
                S_DS_WRITE: begin
                    ram_addr <= ptr[13:0]; ram_din <= dout_a; we_b <= 1'b1; // Write to 64x64 space
                    if (ptr == 4095) begin state <= S_COPY_WAIT; ptr <= 0; end
                    else begin
                        ptr <= ptr + 1;
                        if (ds_col == 63) begin ds_col <= 0; ds_row <= ds_row + 1; end
                        else ds_col <= ds_col + 1;
                        state <= S_DS_WAIT;
                    end
                end
                
                S_COPY_WAIT: begin ram_addr <= ptr[13:0]; state <= S_COPY_WRITE; end
                S_COPY_WRITE: begin
                    ram_addr <= ptr[13:0]; ram_din <= dout_b; we_a <= 1'b1;
                    if (ptr == 4095) begin
                        octave <= 1; // Engage Octave 2
                        state <= S_BLUR_1; core_start <= 1'b1; ptr <= 0;
                        led[15] <= 1'b1; // Indicate Octave 2
                    end else begin
                        ptr <= ptr + 1; state <= S_COPY_WAIT;
                    end
                end
                default: state <= S_WAIT_SYNC;
            endcase
        end
    end
endmodule
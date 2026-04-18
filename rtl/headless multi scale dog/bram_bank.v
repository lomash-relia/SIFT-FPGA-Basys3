module bram_bank (
    input wire clk,
    input wire we,
    input wire [13:0] addr,
    input wire [7:0] din,
    output reg [7:0] dout
);
    (* ram_style = "block" *) reg [7:0] mem [0:16383];
    always @(posedge clk) begin
        if (we) mem[addr] <= din;
        dout <= mem[addr];
    end
endmodule
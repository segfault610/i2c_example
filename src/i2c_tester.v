module top (
input clk,
input rst_n,
inout sda,
output scl,
output [5:0] led
);

wire [3:0] state;
wire scl_int;

i2c_master #(.BYTE(8'hFC)) uut (
.clk(clk),
.rst(~rst_n),
.sda(sda),
.scl(scl_int),
.debug_state(state)
);

assign scl = scl_int;

// ========= LED DEBUG =========
assign led[3:0] = ~state;
assign led[4]   = ~scl_int;
assign led[5]   = ~sda;

endmodule

module top (
    input  logic clk,
    input  logic rst_n,
    inout  wire  sda,
    output logic scl,
    output logic [5:0] led
);
    logic [3:0] state_debug;
    logic scl_int;

    // You need to explicitly handle the tri-state in the top or master
    // If the master does the tri-state, top just passes the wire.
    // However, the LEDs might be flickering too fast to see.

    i2c_master #(.BYTE(8'hFC)) uut (
        .clk(clk),
        .rst(~rst_n),
        .sda(sda), // This is the wire
        .scl(scl_int),
        .debug_state(state_debug)
    );

    assign scl = scl_int;

    // LED DEBUG
    assign led[3:0] = ~state_debug; 
    assign led[4]   = ~scl_int;
    assign led[5]   = ~sda; // This shows the ACTUAL state of the bus
endmodule
module top (
    input  logic clk,
    input  logic rst_n,
    inout  wire  sda,
    output logic scl,
    output logic [5:0] led
);

    logic [3:0] state_debug;
    logic scl_int;

    i2c_master #(.BYTE(8'hFC)) uut (
        .clk(clk),
        .rst(~rst_n),
        .sda(sda),
        .scl(scl_int),
        .debug_state(state_debug)
    );

    assign scl = scl_int;

    // ========= LED DEBUG (Active Low for Tang Nano) =========
    assign led[3:0] = ~state_debug;
    assign led[4]   = ~scl_int;
    assign led[5]   = ~sda;

endmodule

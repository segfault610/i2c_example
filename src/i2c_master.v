module i2c_master #(parameter BYTE = 8'hA8)(
input clk,
input rst,
inout sda,
output reg scl,
output [3:0] debug_state
);

// ========= CLOCK DIVIDER =========
reg [23:0] clkdiv = 0;
reg tick = 0;

always @(posedge clk) begin
if (clkdiv == 24'd500000) begin  // faster but visible
clkdiv <= 0;
tick <= 1;
end else begin
clkdiv <= clkdiv + 1;
tick <= 0;
end
end

// ========= SDA =========
reg sda_out = 1;
reg sda_oe  = 1;

assign sda = (sda_oe) ? sda_out : 1'bz;

// ========= FSM =========
reg [3:0] state = 0;
reg [3:0] bitcnt = 0;
reg [1:0] phase = 0;   // ⭐ 3-phase system

reg [7:0] byte_to_send;
assign debug_state = state;

localparam IDLE  = 0,
START = 1,
ADDR  = 2,
ACK1  = 3,
DATA  = 4,
ACK2  = 5,
STOP1 = 6,
STOP2 = 7,
DONE  = 8;

always @(posedge clk) begin
if (rst) begin
state <= IDLE;
scl <= 1;
sda_out <= 1;
sda_oe <= 1;
phase <= 0;
bitcnt <= 0;

end else if (tick) begin

    case (state)

    // ========= IDLE =========
    IDLE: begin
        scl <= 1;
        sda_out <= 1;
        state <= START;
    end

    // ========= START =========
    START: begin
        scl <= 1;
        sda_out <= 0;   // START condition
        byte_to_send <= 8'h4E;
        bitcnt <= 7;
        phase <= 0;
        state <= ADDR;
    end

    // ========= ADDRESS =========
    ADDR: begin
        case (phase)
        0: begin
            scl <= 0;
            sda_out <= byte_to_send[bitcnt];
            phase <= 1;
        end
        1: begin
            scl <= 0;   // hold for setup
            phase <= 2;
        end
        2: begin
            scl <= 1;   // sample here
            phase <= 0;

            if (bitcnt == 0)
                state <= ACK1;
            else
                bitcnt <= bitcnt - 1;
        end
        endcase
    end

    // ========= ACK =========
    ACK1: begin
        case (phase)
        0: begin
            scl <= 0;
            sda_oe <= 0;
            phase <= 1;
        end
        1: begin
            scl <= 0;
            phase <= 2;
        end
        2: begin
            scl <= 1;
            sda_oe <= 1;
            byte_to_send <= BYTE;
            bitcnt <= 7;
            phase <= 0;
            state <= DATA;
        end
        endcase
    end

    // ========= DATA =========
    DATA: begin
        case (phase)
        0: begin
            scl <= 0;
            sda_out <= byte_to_send[bitcnt];
            phase <= 1;
        end
        1: begin
            scl <= 0;
            phase <= 2;
        end
        2: begin
            scl <= 1;
            phase <= 0;

            if (bitcnt == 0)
                state <= ACK2;
            else
                bitcnt <= bitcnt - 1;
        end
        endcase
    end

    // ========= ACK =========
    ACK2: begin
        case (phase)
        0: begin
            scl <= 0;
            sda_oe <= 0;
            phase <= 1;
        end
        1: begin
            scl <= 0;
            phase <= 2;
        end
        2: begin
            scl <= 1;
            sda_oe <= 1;
            phase <= 0;
            state <= STOP1;
        end
        endcase
    end

    // ========= STOP =========

    STOP1: begin
        scl <= 1;
        sda_out <= 0;   // ensure SDA LOW while SCL HIGH
        state <= STOP2;
    end

    STOP2: begin
        sda_out <= 1;   // SDA rises while SCL HIGH → VALID STOP
        state <= DONE;
    end

    DONE: begin
        scl <= 0;
        state <= DONE;
    end

    endcase
end

end

endmodule

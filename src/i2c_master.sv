module i2c_master #(parameter [7:0] BYTE = 8'hA8)(
    input  logic clk,
    input  logic rst,
    inout  wire  sda,
    output logic scl,
    output logic [3:0] debug_state
);

    // ========= FSM TYPES =========
    typedef enum logic [3:0] {
        IDLE  = 4'd0,
        START = 4'd1,
        ADDR  = 4'd2,
        ACK1  = 4'd3,
        DATA  = 4'd4,
        ACK2  = 4'd5,
        STOP1 = 4'd6,
        STOP2 = 4'd7,
        DONE  = 4'd8
    } state_t;

    (* gowin_fsm_state_machine *) state_t state;

    // ========= INTERNAL SIGNALS =========
    logic [23:0] clkdiv;
    logic tick;
    logic sda_out;
    logic sda_oe;
    logic [2:0] bitcnt; // FIXED: 3 bits for 0-7 indexing
    logic [1:0] phase;
    logic [7:0] byte_to_send;

    assign debug_state = state;
    assign sda = (sda_oe) ? sda_out : 1'bz;

    // ========= CLOCK DIVIDER =========
    always_ff @(posedge clk) begin
        if (clkdiv == 24'd500000) begin
            clkdiv <= 0;
            tick   <= 1;
        end else begin
            clkdiv <= clkdiv + 1;
            tick   <= 0;
        end
    end

    // ========= MAIN FSM =========
    always_ff @(posedge clk) begin
        if (rst) begin
            state        <= IDLE;
            scl          <= 1;
            sda_out      <= 1;
            sda_oe       <= 1;
            phase        <= 0;
            bitcnt       <= 0;
            byte_to_send <= 0;
        end else if (tick) begin
            case (state)
                IDLE: begin
                    scl     <= 1;
                    sda_out <= 1;
                    state   <= START;
                end

                START: begin
                    scl          <= 1;
                    sda_out      <= 0;   // START condition
                    byte_to_send <= 8'h4E;
                    bitcnt       <= 7;
                    phase        <= 0;
                    state        <= ADDR;
                end

                ADDR: begin
                    case (phase)
                        0: begin
                            scl     <= 0;
                            sda_out <= byte_to_send[bitcnt];
                            phase   <= 1;
                        end
                        1: begin
                            scl   <= 0;
                            phase <= 2;
                        end
                        2: begin
                            scl   <= 1;
                            phase <= 0;
                            if (bitcnt == 0)
                                state <= ACK1;
                            else
                                bitcnt <= bitcnt - 1;
                        end
                    endcase
                end

                ACK1: begin
                    case (phase)
                        0: begin scl <= 0; sda_oe <= 0; phase <= 1; end
                        1: begin scl <= 0; phase <= 2; end
                        2: begin
                            scl          <= 1;
                            sda_oe       <= 1;
                            byte_to_send <= BYTE;
                            bitcnt       <= 7;
                            phase        <= 0;
                            state        <= DATA;
                        end
                    endcase
                end

                DATA: begin
                    case (phase)
                        0: begin
                            scl     <= 0;
                            sda_out <= byte_to_send[bitcnt];
                            phase   <= 1;
                        end
                        1: begin scl <= 0; phase <= 2; end
                        2: begin
                            scl   <= 1;
                            phase <= 0;
                            if (bitcnt == 0)
                                state <= ACK2;
                            else
                                bitcnt <= bitcnt - 1;
                        end
                    endcase
                end

                ACK2: begin
                    case (phase)
                        0: begin scl <= 0; sda_oe <= 0; phase <= 1; end
                        1: begin scl <= 0; phase <= 2; end
                        2: begin
                            scl    <= 1;
                            sda_oe <= 1;
                            phase  <= 0;
                            state  <= STOP1;
                        end
                    endcase
                end

                STOP1: begin
                    scl     <= 1;
                    sda_out <= 0;
                    state   <= STOP2;
                end

                STOP2: begin
                    sda_out <= 1; // STOP condition
                    state   <= DONE;
                end

                DONE: begin
                    scl   <= 0;
                    state <= DONE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

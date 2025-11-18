module gcd (
    input  logic       clk,
    input  logic       reset,
    input  logic       start,
    input  logic [7:0] a, b,
    output logic [15:0] result,
    output logic        done
);

    typedef enum logic [1:0] {
        IDLE, RUN, DONE
    } state_t;

    state_t state, next_state;

    logic [7:0] x, y;
    logic [7:0] next_x, next_y;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            x <= 0;
            y <= 0;
            state <= IDLE;
        end else begin
            x <= next_x;
            y <= next_y;
            state <= next_state;
        end
    end

    always_comb begin
        next_state = state;
        next_x = x;
        next_y = y;
        done = 1'b0;

        case (state)
            IDLE: begin
                if (start) begin
                    next_x = a;
                    next_y = b;
                    next_state = RUN;
                end
            end

            RUN: begin
                if (y != 0) begin
                    next_x = y;
                    next_y = x % y;
                end else begin
                    next_state = DONE;
                end
            end

            DONE: begin
                done = 1'b1;
                if (!start)
                    next_state = IDLE;
            end
        endcase
    end

    assign result = x;

endmodule

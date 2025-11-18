module controller #(parameter WIDTH = 16,
            parameter INSTR_LEN = 20,
            parameter ADDR = 5) (
    input  logic        clk,
    input  logic        reset,
    input logic         go,
    input  logic [INSTR_LEN-1:0] instruction,
    input  logic        done,
    output logic        enable,
    output logic [ADDR-1:0]  pc,
    output logic [3:0]  opcode,
    output logic [7:0]  a, b,
    output logic invalid_opcode
);

// Your code here

//-----------------------------
// State encoding
//-----------------------------
typedef enum logic [2:0] {
    S_WAIT,
    S_FETCH,
    S_DECODE,
    S_EXECUTE,
    S_WAIT_DONE,
    S_INCREMENT_PC,
    S_HALT
} state_t;

state_t state, next;

//-----------------------------
// PC Register
//-----------------------------
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        pc <= 0;
    else if (state == S_INCREMENT_PC)
        pc <= pc + 1;
end

//-----------------------------
// Instruction decode
//-----------------------------
always_comb begin
    opcode = instruction[19:16];
    a      = instruction[15:8];
    b      = instruction[7:0];
end

//-----------------------------
// Invalid opcode detection
//----------------------------- 
always_comb begin
    case(opcode)
        4'b0001,
        4'b0010,
        4'b0011,
        4'b1011,
        4'b1111: invalid_opcode = 0;
        default: invalid_opcode = 1;
    endcase
end

//-----------------------------
// FSM next state logic
//-----------------------------
always_comb begin
    next = state;
    enable = 0;

    case (state)

        S_WAIT: begin
            if (go)
                next = S_FETCH;
        end

        S_FETCH: begin
            next = S_DECODE;
        end

        S_DECODE: begin
            if (opcode == 4'b1111)           // HALT
                next = S_HALT;
            else if (invalid_opcode)
                next = S_INCREMENT_PC;
            else
                next = S_EXECUTE;
        end

        S_EXECUTE: begin
            enable = 1;
            next = S_WAIT_DONE;
        end

        S_WAIT_DONE: begin
            if (done)
                next = S_INCREMENT_PC;
        end

        S_INCREMENT_PC: begin
            next = S_FETCH;
        end

        S_HALT: begin
            if (go)
                next = S_FETCH;
        end
    endcase
end

//-----------------------------
// FSM state register
//-----------------------------
always_ff @(posedge clk or posedge reset) begin
    if (reset)
        state <= S_WAIT;
    else
        state <= next;
end




endmodule











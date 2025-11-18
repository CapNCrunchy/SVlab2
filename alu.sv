module alu (
    input  logic [3:0] opcode,
    input  logic [7:0] a, b,
    output logic [15:0] result
);

// Your code here

always_comb begin
    case(opcode)
        4'b0001: result = a+b;
        4'b0010: result = a-b;
        4'b0011: result = a*b;
        default: result = 16'h0000;
        
    endcase
end


endmodule



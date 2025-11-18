module top #(
    parameter int WIDTH = 16,
    parameter int INSTR_LEN = 20,
    parameter int ADDR = 5,
    parameter int PROG_LEN = 100
)
(
    input  logic clk, reset, go,
    output logic [WIDTH-1:0] result,
    output logic done,

    // === Memory preload interface from TB ===
    input  logic        wr_en,
    input  logic [ADDR-1:0]  wr_addr,
    input  logic [INSTR_LEN-1:0] wr_data
);

    // === Internal signals ===
    logic [INSTR_LEN-1:0] instruction;
    logic enable, go_pass, invalid_opcode;
    logic data_done;
    logic [3:0] opcode;
    logic [7:0] a,b;
    logic [ADDR-1:0]  rd_addr;
    logic [INSTR_LEN-1:0] rd_data;


    assign done = data_done;
    assign go_pass = go;

    // Instantiate memory
    memory #(.WIDTH(WIDTH),.INSTR_LEN(INSTR_LEN),.ADDR(ADDR),.PROG_LEN(PROG_LEN)) mem_inst  (
        .clk(clk),
        .rst(reset),
        .wr_en(wr_en),         // from TB
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_en(rd_en),         // from TB during preload OR driven by CPU during run
        .rd_addr(rd_addr),
        .rd_data(rd_data)     // goes to TB and also to CPU instruction input
    );

    // During execution, CPU fetches instruction from memory
    assign instruction = rd_data;
    assign rd_en = 1'b1;

    // Controller
    controller #(.WIDTH(WIDTH),.INSTR_LEN(INSTR_LEN),.ADDR(ADDR)) ctrl_inst (
        .clk(clk),
        .reset(reset),
        .go(go_pass),
        .instruction(instruction),
        .enable(enable),
        .done(data_done),
        .pc(rd_addr),
        .opcode(opcode),
	.invalid_opcode(invalid_opcode),
        .a(a),
        .b(b)
        
    );

    // Datapath
    datapath #(.WIDTH(WIDTH),.INSTR_LEN(INSTR_LEN),.ADDR(ADDR)) datapath_inst (
        .clk(clk),
        .reset(reset),
        .go(go_pass),
        .enable(enable),
        .result(result),
        .data_done(data_done),
        .opcode(opcode),
	.invalid_opcode(invalid_opcode),
        .a(a),
        .b(b)
         
    );

endmodule

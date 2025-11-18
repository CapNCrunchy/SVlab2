module memory #(parameter WIDTH = 16,
            parameter INSTR_LEN = 20,
            parameter ADDR = 5,
            parameter PROG_LEN = 100) (
    input  logic        clk,
    input  logic        rst,
    // Write interface
    input  logic        wr_en,
    input  logic [ADDR-1:0]  wr_addr,
    input  logic [INSTR_LEN-1:0] wr_data,
    // Read interface
    input  logic        rd_en,
    input  logic [ADDR-1:0]  rd_addr,
    output logic [INSTR_LEN-1:0] rd_data
);

    logic [INSTR_LEN-1:0] ram [0:PROG_LEN]; 

    // Synchronous write
    always_ff @(posedge clk) begin
        if (wr_en)
        	ram[wr_addr] = wr_data;        // This RAM is write first and read new data so they must use this ram style in-order to complaince with the rest of the components 
        if(rd_en)
		rd_data <= ram[rd_addr];
    end

endmodule

module datapath #(parameter WIDTH = 16,
            parameter INSTR_LEN = 20,
            parameter ADDR = 5)(
    input logic [3:0]  opcode,
    input logic [7:0]  a, b,
    input  logic        clk,
    input  logic        reset,
    input logic  go,  
    input  logic        enable, invalid_opcode,
    output logic [WIDTH-1:0] result,
    output logic        data_done
    
);

    
    logic [WIDTH-1 :0] alu_result, gcd_result;
    logic [WIDTH-1 :0] result_reg;
    logic        gcd_done;
    logic        done_reg;

    alu alu_inst (
        .opcode(opcode),
        .a(a),
        .b(b),
        .result(alu_result)
    );

  

    gcd gcd_inst (
        .clk(clk),
        .reset(reset),
        .start(enable && opcode == 4'b1011),
        .a(a),
        .b(b),
        .result(gcd_result),
        .done(gcd_done)
    );


    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            result_reg <= 16'd0;
            done_reg   <= 1'b0;
        end 
	else begin
		
		if(invalid_opcode && !go) begin                     
                	done_reg   <= 1'b1;
                	result_reg <= 1'b0;
            	end			

            if (enable) begin
                if (opcode == 4'b1011) begin
                    if (gcd_done) begin
                        result_reg <= gcd_result;                  // GCD Result based on the input number takes multiple cycles.
                        done_reg   <= 1'b1;
                    end
                end
		else begin                  // if any illegal opcode comes, it goes to the alu and the output will be default zero
                    result_reg <= alu_result;
                    done_reg   <= 1'b1;                          // ALU finishes in 1 cycle.
                end
		
            end
	else if (go) done_reg <= 1'b0;
        end
    end

    assign result = result_reg;
    assign data_done   = done_reg;

endmodule

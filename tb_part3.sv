module tb_randomize_p3;

// =====================================================
// Parameters
// =====================================================
localparam int WIDTH = 16;
localparam int INSTR_LEN = 20;
localparam int ADDR = 5;
localparam int PROG_LEN = 100;

logic clk, reset, go;
logic instruction_done;
logic [WIDTH-1:0] result;
logic [WIDTH-1:0] expected = 0;

// Memory interface
logic              wr_en;
logic [ADDR-1:0]   wr_addr;
logic [INSTR_LEN-1:0] wr_data;

// Temporary signals for coverage
logic [7:0] a_sig, b_sig;
logic [3:0] opcode_sig;

// =====================================================
// Instantiate DUT
// =====================================================
top #(.WIDTH(WIDTH),
      .INSTR_LEN(INSTR_LEN),
      .ADDR(ADDR),
      .PROG_LEN(PROG_LEN)) 
dut (
    .clk(clk),
    .reset(reset),
    .go(go),
    .done(instruction_done),
    .result(result),

    // memory connections
    .wr_en(wr_en),
    .wr_addr(wr_addr),
    .wr_data(wr_data)
);

// =====================================================
// Clock generation
// =====================================================
initial clk = 0;
always #5 clk = ~clk;

// =====================================================
// Part 3 — Instruction Class with Constraints
// =====================================================
class instr;
    rand bit [3:0] opcode;   
    rand bit [7:0] a, b;     

    // ------------------------------
    // REQUIRED PART 3 CONSTRAINTS
    // ------------------------------

    // Only valid ISA opcodes are allowed
    constraint c_opcode_valid {
        opcode inside {4'b0001, 4'b0010, 4'b0011, 4'b1011, 4'b1111};
    }

    // Operand constraints based on opcode
    constraint c_operands {
        if (opcode == 4'b0001) {      // add
            a inside {[0:50]};
            b inside {[0:50]};
        }
        else if (opcode == 4'b0010) { // sub
            a > b;
        }
        else if (opcode == 4'b0011) { // mul
            a % 2 == 0;
            b % 2 == 1;
        }
        else if (opcode == 4'b1011) { // gcd
            a != 0;
            b != 0;
        }
    }

    // Weighted distribution
    constraint c_weights {
        opcode dist {
            4'b0001 := 70,   // add
            4'b0010 := 70,   // sub
            4'b0011 := 15,   // mul
            4'b1011 := 5     // gcd
        };
    }
endclass

instr instr_obj;


// =====================================================
// Reference Model
// =====================================================
function automatic bit [WIDTH-1:0] ref_model(input [3:0] opcode, input [7:0] a, input [7:0] b);
    int x = a, y = b;

    case (opcode)
        4'b0001: ref_model = a + b;
        4'b0010: ref_model = a - b;
        4'b0011: ref_model = a * b;
        4'b1011: begin
            while (y != 0) begin
                int temp = y;
                y = x % y;
                x = temp;
            end
            ref_model = x;
        end
        default: ref_model = 16'd0;
    endcase
endfunction


// =====================================================
// Task: Write instruction to memory
// =====================================================
task mem_write(input [ADDR-1:0] addr, input [INSTR_LEN-1:0] data);
begin
    @(posedge clk);
    go <= 1'b1;
    wr_en   <= 1;
    wr_addr <= addr;
    wr_data <= data;
    @(posedge clk);
    wr_en   <= 0;
    go <= 0;
end
endtask


// =====================================================
// Coverage — PART 3 VERSION
// =====================================================
covergroup cg_inputs @(posedge clk);

    coverpoint a_sig {
        bins a[] = {[0:255]};
    }

    coverpoint b_sig {
        bins b[] = {[0:255]};
    }

    // PART 3: Two bins — valid & invalid
    coverpoint opcode_sig {
        bins valid_opcodes[] = {4'b0001, 4'b0010, 4'b0011, 4'b1011, 4'b1111};
        bins invalid_opcodes = default;
    }

endgroup

cg_inputs cov_inst = new();


// =====================================================
// Test Sequence
// =====================================================
initial begin
    wr_en   <= 0;
    wr_addr <= 0;
    wr_data <= 0;
    reset   <= 1;
    go      <= 0;
    #20 reset <= 0;

    $display("=== Starting Constrained Random Testbench (Part 3) ===");

    // Construct instruction object
    instr_obj = new();

    // Generate constrained random instructions
    for (int i = 0; i < PROG_LEN; i++) begin

        // Randomize with constraints
        assert(instr_obj.randomize())
            else begin
                $error("RANDOMIZATION FAILED!");
                $finish;
            end

        // Coverage assignments
        a_sig = instr_obj.a;
        b_sig = instr_obj.b;
        opcode_sig = instr_obj.opcode;

        // Display values
        $display("MEM[%0d]  OPCODE=%04b  A=%0d  B=%0d",
                 i, instr_obj.opcode, instr_obj.a, instr_obj.b);

        // Write to memory
        mem_write(i, {instr_obj.opcode, instr_obj.a, instr_obj.b});

        // Wait for instruction completion
        @(posedge clk);
        wait(instruction_done);

        // Compute expected result
        expected = ref_model(instr_obj.opcode, instr_obj.a, instr_obj.b);

        // Compare with DUT
        if (result !== expected) begin
            $error("FAIL | opcode=%04b a=%0d b=%0d | result=%0d expected=%0d",
                   instr_obj.opcode, instr_obj.a, instr_obj.b, result, expected);
        end
        else begin
            $display("PASS | opcode=%04b a=%0d b=%0d | result=%0d",
                     instr_obj.opcode, instr_obj.a, instr_obj.b, result);
            $display("---------------------------");
        end
    end

    #10;
    $display("=== Part 3 Test Finished ===");
    $finish;
end

endmodule

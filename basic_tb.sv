module tb_hardcoded;


// Parameters
parameter int PROG_LEN = 10;
localparam int WIDTH = 16;
localparam int INSTR_LEN = 20;
localparam int ADDR = 5;

  logic clk, reset, go;
  logic instruction_done;
  logic [WIDTH-1:0] result;
  logic [WIDTH-1:0] expected = 0;

  // For memory interface
  logic        wr_en;
  logic [ADDR-1:0]  wr_addr;
  logic [INSTR_LEN-1:0] wr_data;

  // Local variables for loops
  int i,j;

  // Instantiate DUT
  top  #(.WIDTH(WIDTH),.INSTR_LEN(INSTR_LEN),.ADDR(ADDR),.PROG_LEN(PROG_LEN)) dut (
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

  // Clock generation
  initial clk <= 0;
  always #5 clk <= ~clk;

  

  // Instruction struct
  typedef struct packed {
    logic [3:0] opcode;
    logic [7:0] a;
    logic [7:0] b;
  } instr_t;

  // Test program
  instr_t programm[PROG_LEN] = '{
    '{4'b0001, 8'd10, 8'd5},    // ADD 10 + 5 = 15
    '{4'b0010, 8'd20, 8'd8},    // SUB 20 - 8 = 12
    '{4'b0011, 8'd5,  8'd3},    // MUL 5 * 3 = 15
    '{4'b1011, 8'd85, 8'd51},   // GCD = 17
     '{4'b0001, 8'd10, 8'd5},    // ADD 10 + 5 = 15
     '{4'b0010, 8'd20, 8'd8},    // SUB 20 - 8 = 12
    '{4'b0011, 8'd5,  8'd3} ,      // MUL 5 * 3 = 15
    '{4'b1011, 8'd85, 8'd51},   // GCD = 17
     '{4'b1111, 8'd184, 8'd253}, //  none of them matches so zero.
    '{4'b1101, 8'd184, 8'd253}  // none of them matches so zero.
  };

  // Reference model for expected result
  function automatic logic [15:0] ref_model(input [3:0] op, input [7:0] a, input [7:0] b);
    int x = a, y = b;
    begin
      case (op)
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
    end
  endfunction

  // Task to write to memory
  task mem_write(input [ADDR-1:0] addr, input [INSTR_LEN-1:0] data);
    begin
      @(posedge clk);
      go <= 1'b1;
      wr_en   <= 1;
      wr_addr <= addr;
      wr_data <= data;
      @(posedge clk);
      wr_en   <= 0;
      go <= 1'b0;  
    end
  endtask

  initial begin
    // Init inputs and control signals with non-blocking assignments
    wr_en   <= 0; 
    wr_addr <= 0; 
    wr_data <= 0;
    reset   <= 1;
    go <= 0;
    #20 reset <= 0;

    $display("Starting Testbench...");

   
      for (i = 0; i < PROG_LEN; i++) begin
        mem_write(i, {programm[i].opcode, programm[i].a, programm[i].b});

	    $display("Displaying Memory Contents Iter=%0d | Opcode=%04b | A=%0d | B=%0d",  
                i, programm[i].opcode, programm[i].a, programm[i].b);

        @(posedge clk)
        wait(instruction_done);
        
        expected = ref_model(programm[i].opcode, programm[i].a, programm[i].b);
        if (result !== expected) begin
          $error("FAIL | Opcode=%0b A=%0d B=%0d | Got=%0d, Expected=%0d",
                  programm[i].opcode, programm[i].a, programm[i].b, result, expected);
        end else begin
          $display("Result_PASS | Opcode=%0b A=%0d B=%0d | Result=%0d",
                  programm[i].opcode, programm[i].a, programm[i].b, result);

                  $display(".............................");
        end
      end
      
        #20;
       $display("=== Test Finished ===");
       $finish;
    end
       
endmodule

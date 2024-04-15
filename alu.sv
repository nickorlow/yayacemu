import structs::*;

module alu (
    input wire rst_in,
    input wire clk_in,
    input alu_input in,
    output logic [7:0] result,
    output logic [15:0] result_long,
    output logic overflow,
    output logic done
);

  logic [8:0] result_int;
  int cnt;

  initial begin
    overflow = 0;
    result = 8'hxx;
    result_int = 9'bxxxxxxxxx;
    done = 0;
    cnt = 0;
  end

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      done <= 0;
      overflow <= 0;
      result <= 8'hxx;
      result_int <= 9'bxxxxxxxxx;
      cnt <= 0;
    end else begin
      case (in.op)
        structs::ADD: begin
          result_int <= in.operand_a + in.operand_b;
          result <= result_int[7:0];
          overflow <= result_int[8];
          if (cnt >= 2) begin
            done <= 1;
          end
          cnt <= cnt + 1;
        end
        structs::ADDL: begin
          result_long <= {8'h00, in.operand_a} + {4'h0, in.operand_b_long};
          done <= 1;
          cnt <= cnt + 1;
        end
        structs::SUB: begin
          result_int <= in.operand_a - in.operand_b;
          result <= result_int[7:0];
          // FIXME: if this fails, just do vx > vy
          overflow <= !result_int[8];
          if (cnt >= 2) begin
            done <= 1;
          end
          cnt <= cnt + 1;
        end
        structs::SE: begin
          result <= {7'b0000000, in.operand_a == in.operand_b};
          done   <= 1;
        end
        structs::SNE: begin
          result <= {7'b0000000, in.operand_a != in.operand_b};
          done   <= 1;
        end
        structs::OR: begin
          result <= in.operand_a | in.operand_b;
          overflow <= 0;
          done <= 1;
        end
        structs::AND: begin
          result <= in.operand_a & in.operand_b;
          overflow <= 0;
          done <= 1;
        end
        structs::XOR: begin
          result <= in.operand_a ^ in.operand_b;
          overflow <= 0;
          done <= 1;
        end
        structs::SHR: begin
          result <= in.operand_a >> in.operand_b;
          overflow <= in.operand_a[0];
          done <= 1;
        end
        structs::SHL: begin
          result <= in.operand_a << in.operand_b;
          overflow <= in.operand_a[7];
          done <= 1;
        end
      endcase
    end
  end

endmodule

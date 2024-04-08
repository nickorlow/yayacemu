import structs::*;

module alu(
    input wire rst_in,
    input wire clk_in,
    input alu_input in,
    output logic [7:0] result,
    output logic overflow,
    output logic done
    );

    logic [8:0] result_int;
    int cnt;

    initial begin
        overflow = 1'bx;
        result = 8'hxx;
        result_int = 9'bxxxxxxxxx;
        done = 0;
        cnt = 0;
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            done <= 0;        
            overflow <= 1'bx;
            result <= 8'hxx;
            result_int <= 9'bxxxxxxxxx;
            cnt <= 0;
        end else begin
            case(in.op)
                structs::ADD: begin
                    result_int <= in.operand_a + in.operand_b;
                    result <= result_int[7:0];
                    overflow <= result_int[8];
                    if (cnt == 2) begin
                        $display("%b %b + %b %b ya", result, in.operand_a, in.operand_b, result_int);
                        done <= 1;
                    end
                    cnt <= cnt + 1;
                end
            endcase
        end
    end

endmodule

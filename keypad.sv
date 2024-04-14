module keypad(
    input clk_in,
    input wire [3:0] row,
    output logic [3:0] col,
    output [5:0] cur_press
);

    logic [1:0] col_idx;
    logic [15:0] keymap;

    assign cur_press = {clk_in, 1'b0, keymap[3:0]};

    initial begin 
        col_idx = 0;
        col = 0;
        keymap = 0;
    end

    always_ff @(posedge clk_in) begin
        for(logic [2:0] i = 0; i < 4; i++) begin
            keymap[(i*4)+col_idx] <= row[i[1:0]];
        end 

        col[col_idx] <= 1;
        col[col_idx+1] <= 0;
        col_idx <= col_idx + 1;
    end

endmodule

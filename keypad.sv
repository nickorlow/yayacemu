module keypad(
    input clk_in,
    input wire [3:0] row,
    output logic [3:0] col,
    output logic [15:0] keymap_out
);

    logic [1:0] col_idx;
    logic [15:0] keymap;
    logic [15:0] keymap_db;
    logic [15:0] keymap_db2;
/* old
    assign keymap_out[0] = keymap[13];
    assign keymap_out[1] = keymap[0];
    assign keymap_out[2] = keymap[1];
    assign keymap_out[3] = keymap[2];
    assign keymap_out[4] = keymap[4];
    assign keymap_out[5] = keymap[5];
    assign keymap_out[6] = keymap[6];
    assign keymap_out[7] = keymap[8];
    assign keymap_out[8] = keymap[9];
    assign keymap_out[9] = keymap[10];

    assign keymap_out[10] = keymap[3];
    assign keymap_out[11] = keymap[7];
    assign keymap_out[12] = keymap[11];
    assign keymap_out[13] = keymap[15];
    assign keymap_out[14] = keymap[12];
    assign keymap_out[15] = keymap[14];
    */
    //assign keymap_out = keymap;
    

    assign keymap_out[1] = !keymap[1];
    assign keymap_out[2] = !keymap[0];
    assign keymap_out[3] = !keymap[2];
    assign keymap_out[12] =!keymap[3];


    assign keymap_out[4] = !keymap[5];
    assign keymap_out[5] = !keymap[4];
    assign keymap_out[6] = !keymap[6];
    assign keymap_out[13] =!keymap[7]; //E

    assign keymap_out[7] = !keymap[9];
    assign keymap_out[8] = !keymap[8];
    assign keymap_out[9] = !keymap[10];
    assign keymap_out[14] =!keymap[11]; //F

    assign keymap_out[10] =!keymap[13];
    assign keymap_out[0] = !keymap[12]; //0
    assign keymap_out[11] =!keymap[14];
    assign keymap_out[15] =!keymap[15];// D

    initial begin 
        col_idx = 0;
        col = 0;
        keymap = 0;
    end

    always_ff @(posedge clk_in) begin
        for(logic [2:0] i = 0; i < 4; i++) begin
            keymap_db[(i*4)+col_idx] <= row[i[1:0]];
        end 
        keymap_db2 <= keymap_db;
        keymap <= keymap_db2;

        col[col_idx] <= 1;
        col[col_idx == 3 ? 0 : col_idx +1] <= 0;
        col_idx <= col_idx == 3 ? 0 : col_idx + 1;
    end
endmodule

module keyboard (
    input wire clk_in,
    output bit keyboard [15:0]
    );

    import "DPI-C" function bit [7:0] get_key();

    always_ff @(posedge clk_in) begin
        bit[7:0] keyval = get_key();
        if (&keyval != 1) begin
           keyboard[keyval[3:0]] = keyval[7]; 
        end
    end

endmodule

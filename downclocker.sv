module downclocker #(parameter DC_BITS = 21) (
    input wire clk_in, 
    output logic clk_out
);

    logic [DC_BITS-1:0] counter;

    initial begin
        counter = 0;
        clk_out = 0;
    end

    always_ff @(posedge clk_in) begin
        if (counter[DC_BITS-1] == 1) begin
            clk_out <= !clk_out;
            counter <= 0; 
        end else begin
            counter <= counter + 1;
        end
    end
endmodule

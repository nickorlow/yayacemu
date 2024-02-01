module rng (
    input wire clk_in,
    input wire [15:0] pc,
    input bit keyboard[15:0],
    input int cycle_counter,
    output bit [7:0] rand_bit
);

  bit [7:0] last;

  always_ff @(posedge clk_in) begin
    for (int i = 0; i < 8; i++) begin
      rand_bit[i] ^= ~keyboard[i] ? cycle_counter[i] : cycle_counter[7-i];
      rand_bit[i] ^= (cycle_counter % 7) == 0 ? pc[i] : ~pc[i];
      rand_bit[i] ^= keyboard[i+7] ? ~last[i] : last[i];
    end
    last = rand_bit;
  end
endmodule

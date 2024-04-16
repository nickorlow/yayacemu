module rng (
    input wire clk_in,
    input wire [15:0] bor16,
    input bit [15:0] keyboard,
    input int cycle_counter,
    output bit [7:0] rand_bit
);

  bit [7:0] last;

  always_ff @(posedge clk_in) begin
    for (int i = 0; i < 5; i++) begin
      rand_bit[i] <= ~keyboard[i == 0 ? 7 : i-1] ? cycle_counter[i] : cycle_counter[7-i];
      rand_bit[i+1%8] <= rand_bit[i] ^ (cycle_counter % 7) == 0 ? bor16[i] : ~bor16[i];
      rand_bit[i+2%8] <= rand_bit[i+1%8] ^ keyboard[i+7] ? ~last[i] : last[i];
    end
    last <= rand_bit;
  end
endmodule

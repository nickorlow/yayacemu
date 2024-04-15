module memory #(
    parameter RAM_SIZE_BYTES = 4096
) (
    input wire clk_in,
    input wire do_write,
    input wire [$clog2(RAM_SIZE_BYTES)-1:0] write_address,
    input wire [7:0] data_in,
    input wire [$clog2(RAM_SIZE_BYTES)-1:0] read_address,
    output logic [7:0] data_out  /*,
    input wire [$clog2(RAM_SIZE_BYTES)-1:0] read_address_gfx,
    output logic [7:0] data_out_gfxA*/
);
  logic [7:0] mem[0:RAM_SIZE_BYTES-1];

  initial begin
    $readmemh("fontset.bin", mem, 0);
    $readmemb("rom.bin", mem, 'h200);
  end

  always_ff @(negedge clk_in) begin
    if (do_write) begin
      mem[write_address] <= data_in;
    end
    //$display("MEM    : Reading address %h (%h)", read_address, mem[read_address]);
    data_out <= mem[read_address];
    //data_out_gfx <= mem[read_address_gfx];
  end
endmodule


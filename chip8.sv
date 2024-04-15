module chip8 (
    input wire fpga_clk,
    input wire rst_in,
    output logic lcd_clk,
    output logic lcd_data,
    output logic [5:0] led,
    input wire [3:0] row,
    output logic [3:0] col
);
logic debug_overlay;
  logic slow_clk;
`ifdef FAST_CLK
  assign slow_clk = fpga_clk;
`endif

`ifndef FAST_CLK
  downclocker #(12) dc (
      fpga_clk,
      slow_clk
  );
`endif

  logic key_clk;
`ifdef FAST_CLK
  downclocker #(1) dck (
`endif
`ifndef FAST_CLK
  downclocker #(12) dck (
`endif
      fpga_clk,
      key_clk
  );

  logic [7:0] rd_memory_data;
  logic [11:0] rd_memory_address;
  logic [11:0] wr_memory_address;
  logic [7:0] wr_memory_data;
  logic wr_go;
  memory #(4096) mem (
      slow_clk,
      wr_go,
      wr_memory_address,
      wr_memory_data,
      rd_memory_address,
      rd_memory_data
  );

  logic [15:0] keymap;

  keypad keypad (
`ifndef DUMMY_KEYPAD
      key_clk,
`endif
`ifdef DUMMY_KEYPAD
      slow_clk,
`endif
      row,
      col,
      keymap
  );

  assign led = { key_clk, 1'b0, slow_clk, 1'b0, fpga_clk, 1'b0};

  int cycle_counter;
  logic [5:0] nc;
  cpu cpu (
      slow_clk,
      fpga_clk,
      rd_memory_data,
      keymap,
      cycle_counter,
      rd_memory_address,
      wr_memory_address,
      wr_memory_data,
      wr_go,
      lcd_clk,
      lcd_data,
      nc,
      row,
      col,
      debug_overlay
  );

endmodule


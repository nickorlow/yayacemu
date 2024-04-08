module chip8 (
    input wire fpga_clk,
    input wire rst_in,
    output logic lcd_clk, 
    output logic lcd_data,
    output logic [5:0] led
);

  logic [7:0] rd_memory_data;
  logic [11:0] rd_memory_address;
  logic [11:0] wr_memory_address;
  logic [7:0] wr_memory_data;
  logic wr_go;
  memory #(4096) mem (
        fpga_clk,
        wr_go,
        wr_memory_address,
        wr_memory_data,
        rd_memory_address,
        rd_memory_data
      );
  
  int cycle_counter;
  cpu cpu (
      fpga_clk,
      rd_memory_data,
      cycle_counter,
      rd_memory_address,
      wr_memory_address,
      wr_memory_data,
      wr_go,
      lcd_clk,
      lcd_data,
      led
  );

endmodule


module gpu (
    input wire sys_clk,
    input wire sys_rst_n_ms,
    input wire [7:0] vram [0:1023],
    output logic lcd_clk,  // This goes to the E pin
    output logic lcd_data,  // This goes to the R/W pin
    output logic [5:0] led
);

  import "DPI-C" function void init_screen();
  import "DPI-C" function void draw_screen(logic [7:0] vram[0:1023]);

  initial begin
    init_screen();

  end


  always_comb begin
      draw_screen(vram);
  end
endmodule

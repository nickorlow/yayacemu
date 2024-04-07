module gpu (
    input wire [7:0] vram[0:1023]
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

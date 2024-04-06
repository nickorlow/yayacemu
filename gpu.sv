module gpu (
    input wire vram[0:2047]
);

  import "DPI-C" function void init_screen();
  import "DPI-C" function void draw_screen(logic vram[0:2047]);

  initial begin
    init_screen();
  end

  always_comb begin
    draw_screen(vram);
  end
endmodule

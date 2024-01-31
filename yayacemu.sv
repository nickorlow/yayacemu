module yayacemu (
    input wire clk_in,
    input int pc_in,
    output int pc_out
    );
    import "DPI-C" function void init_screen();

    wire [31:0] vram [0:2047];
    bit [7:0] memory [0:4095];
    wire [7:0] registers [0:15];
    logic [7:0] index_reg;
    logic rom_ready;
    int pc;

    rom_loader rl (memory, rom_ready);
    chip8_cpu cpu (memory, clk_in, vram, index_reg, registers, pc_in, pc_out);
    chip8_gpu gpu (vram);

    initial begin 
        init_screen();
    end

endmodule

module chip8_cpu(
    input bit [7:0] memory [0:4095],
    input wire clk_in,
    output wire [31:0] vram [0:2047],
    output wire [7:0] index_reg,
    output wire [7:0] registers [0:15],
    input int pc_in,
    output int pc_out
    );

    logic [15:0] opcode;
    logic [15:0] scratch;

    logic [31:0] x_cord;
    logic [31:0] y_cord;
    logic [7:0] size;
    logic [31:0] screen_pixel;
    logic [7:0] sprite_pixel;

    int i;

    int r;
    int c;
    always_ff @(posedge clk_in) begin
        opcode = {memory[pc_in],  memory[pc_in+1]};
        $display("HW     : opcode is 0x%h (%b)", opcode, opcode);
        $display("HW     : PC %0d", pc_in);

        casez(opcode)
            'h00E0: begin 
                $display("HW     : INSTR CLS");
                for(i = 0; i < 2048; i++) begin
                    vram[i] = 0;
                end
            end
            'h00EE: $display("HW     : INSTR RET");
            'h0???: $display("HW     : INSTR SYS addr");
            'h1???: $display("HW     : INSTR JP addr");
            'h2???: $display("HW     : INSTR CALL addr");
            'h6???: begin
                $display("HW     : INSTR LD Vx, byte");
                scratch = (opcode & 'h00FF);
                registers[(opcode & 'h0F00) >> 8] = scratch[7:0];
            end
            'h7???: begin
                $display("HW     : INSTR ADD Vx, byte");
                scratch = (opcode & 'h00FF);
                registers[(opcode & 'h0F00) >> 8] += scratch[7:0];
            end
            'hA???: begin
                $display("HW     : INSTR LD I, addr");
                scratch = (opcode & 'h0FFF);
                index_reg = scratch[7:0];
            end
            'hD???: begin
                $display("HW     : INSTR DRW Vx, Vy, nibble");
                x_cord = {24'h000000, registers[(opcode & 'h0F00) >> 8]};
                y_cord = {24'h000000, registers[(opcode & 'h00F0) >> 4]};

                scratch = (opcode & 'h000F);
                size = scratch[7:0];

                for (r = 0; r < size; r++) begin 
                    for ( c = 0; c < 8; c++) begin 
                        screen_pixel = vram[((r + y_cord) * 64) + (x_cord + c)];
                        sprite_pixel = memory[{24'h000000, index_reg} + r] & ('h80 >> c);

                        if (|sprite_pixel) begin 
                           if (screen_pixel == 32'hFFFFFFFF) begin 
                                registers[15] = 1;
                           end 
                           vram[((r + y_cord) * 64) + (x_cord + c)] = screen_pixel ^ 32'hFFFFFFFF;
                        end 
                  end 
                end 
            end
            default: $display("HW     : ILLEGAL INSTRUCTION");
        endcase
        
        pc_out <= pc_in + 2;
    end
endmodule

module chip8_gpu (
    input wire [31:0] vram [0:2047]
    );
    import "DPI-C" function void draw_screen(logic [31:0] vram [0:2047]);
    always_comb begin
       draw_screen(vram); 
    end
endmodule

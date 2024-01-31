module yayacemu (
    input wire clk_in
    );
    import "DPI-C" function void init_screen();

    wire [31:0] vram [0:2047];
    bit [7:0] memory [0:4095];
    wire [7:0] registers [0:15];
    logic [3:0] stack_pointer;
    wire [15:0] stack [0:15];

    logic [15:0] index_reg;
    logic rom_ready;
    logic [15:0] program_counter;

    rom_loader rl (memory, rom_ready);
    chip8_cpu cpu (memory, clk_in, vram, stack, index_reg, stack_pointer, registers, program_counter);
    chip8_gpu gpu (vram);

    initial begin 
        program_counter = 'h200;
        stack_pointer = 4'b0000;
        init_screen();
    end

endmodule

module chip8_cpu(
    output bit [7:0] memory [0:4095],
    input wire clk_in,
    output wire [31:0] vram [0:2047],
    output wire [15:0] stack [0:15],
    output wire [15:0] index_reg,
    output wire [3:0] stack_pointer,
    output wire [7:0] registers [0:15],
    output wire [15:0] program_counter 
    );

    logic [15:0] opcode;
    logic [15:0] scratch;
    logic [15:0] scratch2;

    logic [31:0] x_cord;
    logic [31:0] y_cord;
    logic [7:0] size;
    logic [31:0] screen_pixel;
    logic [7:0] sprite_pixel;

    int i;
    logic [7:0] i8;

    int r;
    int c;
    always_ff @(posedge clk_in) begin
        opcode = {memory[program_counter+0],  memory[program_counter+1]};
        $display("HW     : opcode is 0x%h (%b)", opcode, opcode);
        $display("HW     : PC %0d 0x%h", program_counter, program_counter);

        casez(opcode)
            'h00E0: begin 
                $display("HW     : INSTR CLS");
                for(i = 0; i < 2048; i++) begin
                    vram[i] = 0;
                end
            end
            'h00EE: begin
               $display("HW     : INSTR RET"); 
               stack_pointer--;
               program_counter = stack[stack_pointer];
            end
            'h0???: $display("HW     : INSTR SYS addr (Treating as NOP)");
            'h1???: begin 
                $display("HW     : INSTR JP addr");
                program_counter = (opcode & 'h0FFF) - 2;
            end
            'h2???: begin
                $display("HW     : INSTR CALL addr");
                stack[stack_pointer] = program_counter;
                stack_pointer++;
                program_counter = (opcode & 'h0FFF) - 2;
            end 
            'h3???: begin
                $display("HW     : INSTR SE Vx, byte");
                scratch = (opcode & 'h00FF);
                if (scratch[7:0] == registers[(opcode & 'h0F00) >> 8]) begin
                    program_counter += 2;
                end
            end
            'h4???: begin
                $display("HW     : INSTR SNE Vx, byte");
                scratch = (opcode & 'h00FF);
                if (scratch[7:0] != registers[(opcode & 'h0F00) >> 8]) begin
                    program_counter += 2;
                end
            end
            'h5??0: begin
                $display("HW     : INSTR SE Vx, Vy");
                if (registers[(opcode & 'h00F0) >> 4] == registers[(opcode & 'h0F00) >> 8]) begin
                    program_counter += 2;
                end
            end
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
            'h8??0: begin
                $display("HW     : INSTR LD Vx, Vy");
                registers[(opcode & 'h0F00) >> 8] = registers[(opcode & 'h00F0) >> 4];
            end
            'h8??1: begin
                $display("HW     : INSTR OR Vx, Vy");
                registers[(opcode & 'h0F00) >> 8] |= registers[(opcode & 'h00F0) >> 4];
            end
            'h8??2: begin
                $display("HW     : INSTR AND Vx, Vy");
                registers[(opcode & 'h0F00) >> 8] &= registers[(opcode & 'h00F0) >> 4];
            end
            'h8??3: begin
                $display("HW     : INSTR XOR Vx, Vy");
                registers[(opcode & 'h0F00) >> 8] ^= registers[(opcode & 'h00F0) >> 4];
            end
            'h8??4: begin
                $display("HW     : INSTR ADD Vx, Vy");
                registers[(opcode & 'h0F00) >> 8] += registers[(opcode & 'h00F0) >> 4];
            end
            'h8??5: begin
                $display("HW     : INSTR SUB Vx, Vy");
                registers[(opcode & 'h0F00) >> 8] -= registers[(opcode & 'h00F0) >> 4];
            end
            'h8??6: begin
                $display("HW     : INSTR SHR Vx {, Vy}");
                registers[(opcode & 'h0F00) >> 8] = registers[(opcode & 'h00F0) >> 4]>> 1;
            end
            'h8??7: begin
                $display("HW     : INSTR SUBN Vx, Vy");
                registers[(opcode & 'h0F00) >> 8] = registers[(opcode & 'h00F0) >> 4] - registers[(opcode & 'h0F00) >> 8];
            end
            'h8??E: begin
                $display("HW     : INSTR SHL Vx {, Vy}");
                registers[(opcode & 'h0F00) >> 8] = registers[(opcode & 'h00F0) >> 4]<< 1;
            end
            'hA???: begin
                $display("HW     : INSTR LD I, addr");
                index_reg = (opcode & 'h0FFF);
            end
            'hD???: begin
                $display("HW     : INSTR DRW Vx, Vy, nibble");
                x_cord = {24'h000000, registers[(opcode & 'h0F00) >> 8]};
                y_cord = {24'h000000, registers[(opcode & 'h00F0) >> 4]};

                x_cord %= 64;
                y_cord %= 32;

                scratch = (opcode & 'h000F);
                size = scratch[7:0];
                registers[15] = 0;

                for (r = 0; r < size; r++) begin 
                    for ( c = 0; c < 8; c++) begin 
                        screen_pixel = vram[((r + y_cord) * 64) + (x_cord + c)];
                        sprite_pixel = memory[{16'h0000, index_reg} + r] & ('h80 >> c);

                        if (|sprite_pixel) begin 
                           if (screen_pixel == 32'hFFFFFFFF) begin 
                                registers[15] = 1;
                           end 
                           vram[((r + y_cord) * 64) + (x_cord + c)] ^= 32'hFFFFFFFF;
                        end 
                  end 
                end
        end
                'hF?33: begin
                   $display("HW     : INSTR LD B, Vx"); 
                    scratch = {8'h00, registers[(opcode & 'h0F00) >> 8]};
                    scratch2 = scratch % 10;
                    memory[index_reg + 2] = scratch2[7:0];
                    scratch /= 10;
                    scratch2 = scratch % 10;
                    memory[index_reg + 1] = scratch2[7:0];
                    scratch /= 10;
                    scratch2 = scratch % 10;
                    memory[index_reg + 0] = scratch2[7:0];
                end
                'hF?55: begin
                   $display("HW     : INSTR LD [I], Vx"); 
                    scratch = (opcode & 'h0F00) >> 8;
                    for (i8 = 0; i8 <= scratch[7:0]; i8++) begin 
                      scratch2 = index_reg + {8'h00, i8};
                      memory[scratch2[11:0]] = registers[i8[3:0]];
                    end 
                    index_reg++;
                end
                'hF?65: begin
                    $display("HW     : INSTR LD Vx, [I]");
                    scratch = (opcode & 'h0F00) >> 8;
                    for (i8 = 0; i8 <= scratch[7:0]; i8++) begin 
                      scratch2 = index_reg + {8'h00, i8};
                      registers[i8[3:0]] = memory[scratch2[11:0]];
                    end 
                    index_reg++;
                end
                'hF?1E: begin
                    $display("HW     : INSTR ADD I, Vx");
                    index_reg = index_reg + {8'h00, registers[(opcode & 'h0F00) >> 8]};
                end
            default: $display("HW     : ILLEGAL INSTRUCTION");
        endcase
        
        program_counter += 2;
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

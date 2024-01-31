module yayacemu (
    input wire clk_in
    );
    import "DPI-C" function void init_screen();

    wire [31:0] vram [0:2047];
    bit [7:0] memory [0:4095];
    wire [7:0] registers [0:15];
    logic [3:0] stack_pointer;
    wire [15:0] stack [0:15];
    logic [7:0] delay_timer;
    logic [7:0] sound_timer;
    bit keyboard [15:0];
    int cycle_counter;
    bit halt;
    int watch_key;

    logic [15:0] index_reg;
    bit [7:0] rand_num;
    logic rom_ready;
    logic [15:0] program_counter;

    bit [7:0] fontset [79:0];

    randomizer randy(clk_in, program_counter, keyboard, cycle_counter, rand_num);
    keyboard kb(clk_in, keyboard);
    rom_loader rl (memory, rom_ready);
    chip8_cpu cpu (memory, clk_in, keyboard, rand_num, vram, stack, index_reg, stack_pointer, registers, delay_timer, sound_timer, cycle_counter, program_counter, halt, watch_key);
    chip8_gpu gpu (vram, sound_timer);

    int i;
    initial begin 
        fontset = {
            8'hF0, 8'h90, 8'h90, 8'h90, 8'hF0, // 0
            8'h20, 8'h60, 8'h20, 8'h20, 8'h70, // 1
            8'hF0, 8'h10, 8'hF0, 8'h80, 8'hF0, // 2
            8'hF0, 8'h10, 8'hF0, 8'h10, 8'hF0, // 3
            8'h90, 8'h90, 8'hF0, 8'h10, 8'h10, // 4
            8'hF0, 8'h80, 8'hF0, 8'h10, 8'hF0, // 5
            8'hF0, 8'h80, 8'hF0, 8'h90, 8'hF0, // 6
            8'hF0, 8'h10, 8'h20, 8'h40, 8'h40, // 7
            8'hF0, 8'h90, 8'hF0, 8'h90, 8'hF0, // 8
            8'hF0, 8'h90, 8'hF0, 8'h10, 8'hF0, // 9
            8'hF0, 8'h90, 8'hF0, 8'h90, 8'h90, // A
            8'hE0, 8'h90, 8'hE0, 8'h90, 8'hE0, // B
            8'hF0, 8'h80, 8'h80, 8'h80, 8'hF0, // C
            8'hE0, 8'h90, 8'h90, 8'h90, 8'hE0, // D
            8'hF0, 8'h80, 8'hF0, 8'h80, 8'hF0, // E
            8'hF0, 8'h80, 8'hF0, 8'h80, 8'h80  // F
        };
        watch_key = 255;
        halt = 0;
        for(i = 0; i < 80; i++) begin
            memory[i] = fontset[i];
        end
        for(i = 0; i < 15; i++) begin
            keyboard[i] = 0;
        end
        sound_timer = 0;
        delay_timer = 0;
        cycle_counter = 0;
        program_counter = 'h200;
        stack_pointer = 4'b0000;
        init_screen();
    end

endmodule

module keyboard (
    input wire clk_in,
    output bit keyboard [15:0]
    );
    int i;
    import "DPI-C" function bit [7:0] get_key();
    bit[7:0] keyval;
    always_ff @(posedge clk_in) begin
        keyval = get_key();
        if (keyval != 8'b11111111) begin
           keyboard[keyval[3:0]] = keyval[7]; 
        end
    end
endmodule

module chip8_cpu(
    output bit [7:0] memory [0:4095],
    input wire clk_in,
    input wire keyboard [15:0],
    input wire [7:0] random_number,
    output wire [31:0] vram [0:2047],
    output wire [15:0] stack [0:15],
    output wire [15:0] index_reg,
    output wire [3:0] stack_pointer,
    output wire [7:0] registers [0:15],
    output logic [7:0] delay_timer,
    output logic [7:0] sound_timer,
    output int cycle_counter,
    output wire [15:0] program_counter,
    output bit halt,
    output int watch_key
    );

    logic [15:0] opcode;

    logic [15:0] scratch;
    logic [15:0] scratch2;

    logic [7:0] scratch_8;
    logic [7:0] scratch_82;

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

        // 480Hz / 8 = 60 Hz
        if (cycle_counter % 20 == 0) begin
            if (delay_timer > 0)
                delay_timer--;
            if (sound_timer > 0)
                sound_timer--;
        end

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
                registers[15] = 0;
            end
            'h8??2: begin
                $display("HW     : INSTR AND Vx, Vy");
                registers[(opcode & 'h0F00) >> 8] &= registers[(opcode & 'h00F0) >> 4];
                registers[15] = 0;
            end
            'h8??3: begin
                $display("HW     : INSTR XOR Vx, Vy");
                registers[(opcode & 'h0F00) >> 8] ^= registers[(opcode & 'h00F0) >> 4];
                registers[15] = 0;
            end
            'h8??4: begin
                $display("HW     : INSTR ADD Vx, Vy");
                scratch_8 = registers[(opcode & 'h0F00) >> 8];
                registers[(opcode & 'h0F00) >> 8] += registers[(opcode & 'h00F0) >> 4];
                registers[15] = {7'b0000000, scratch_8 > registers[(opcode & 'h0F00) >> 8]};
            end
            'h8??5: begin
                $display("HW     : INSTR SUB Vx, Vy");
                scratch_8 = registers[(opcode & 'h0F00) >> 8];
                registers[(opcode & 'h0F00) >> 8] -= registers[(opcode & 'h00F0) >> 4];
                registers[15] = {7'b0000000, scratch_8 >= registers[(opcode & 'h0F00) >> 8]};
            end
            'h8??6: begin
                $display("HW     : INSTR SHR Vx {, Vy}");
                scratch_8 = registers[(opcode & 'h0F00) >> 8];
                registers[(opcode & 'h0F00) >> 8] = registers[(opcode & 'h00F0) >> 4]>> 1;
                registers[15] = {7'b0000000,  ((scratch_8 & 8'h01) == 8'h01)};
            end
            'h8??7: begin
                $display("HW     : INSTR SUBN Vx, Vy");
                scratch_8 = registers[(opcode & 'h00F0) >> 4];
                scratch_82 = registers[(opcode & 'h0F00) >> 8];
                registers[(opcode & 'h0F00) >> 8] = registers[(opcode & 'h00F0) >> 4] - registers[(opcode & 'h0F00) >> 8];
                registers[15] = {7'b0000000, (scratch_8 >= scratch_82)};
            end
            'h8??E: begin
                $display("HW     : INSTR SHL Vx {, Vy}");
                scratch_8 = registers[(opcode & 'h0F00) >> 8];
                registers[(opcode & 'h0F00) >> 8] = registers[(opcode & 'h00F0) >> 4]<< 1;

                registers[15] = {7'b0000000, (scratch_8[7]) };
            end
            'h9??0: begin
                $display("HW     : INSTR SNE Vx, Vy");
                if (registers[(opcode & 'h00F0) >> 4] != registers[(opcode & 'h0F00) >> 8]) begin
                    program_counter += 2;
                end
            end
            'hA???: begin
                $display("HW     : INSTR LD I, addr");
                index_reg = (opcode & 'h0FFF);
            end
            'hb???: begin
                $display("HW     : INSTR JP V0, addr");
                program_counter = {8'h00, registers[0]} + (opcode & 'h0FFF) - 2;
            end
            'hc???: begin
                $display("HW     : RND Vx, addr");
                // TODO: use a real RNG module, this is not synthesizeable
                scratch = {8'h00, random_number} % 16'h0100;
                scratch2 = (opcode & 'h00FF);
                registers[(opcode & 'h0F00) >> 8] = scratch[7:0] & scratch2[7:0];
            end
            'hD???: begin
                if (cycle_counter % 20 != 0) begin
                    halt = 1;
                end else begin
                    halt = 0;
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
                        if (r + y_cord >= 32 || x_cord + c >= 64)
                            continue;
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
            end
            'hE?9E: begin
                $display("HW     : INSTR SKP Vx");
                if (keyboard[{registers[(opcode & 'h0F00) >> 8]}[3:0]] == 1) begin
                    program_counter += 2;
                end
            end
            'hE?A1: begin
                $display("HW     : INSTR SNE Vx");
                if (keyboard[{registers[(opcode & 'h0F00) >> 8]}[3:0]] != 1) begin
                    program_counter += 2;
                end
            end
            'hF?07: begin
                $display("HW     : INSTR LD Vx, DT");
                registers[(opcode & 'h0F00) >> 8] = delay_timer;
            end
            'hF?0A: begin
                $display("HW     : INSTR LD Vx, K");
                halt = 1;
                for(i = 0; i < 16; i++) begin
                    if (watch_key == 255) begin
                        if (keyboard[i]) begin
                           watch_key = i; 
                        end
                    end else begin
                        if (!keyboard[watch_key]) begin
                            halt = 0;
                            watch_key = 255;
                        end
                    end
                end
            end
            'hF?15: begin
                $display("HW     : INSTR LD DT, Vx");
               delay_timer =  registers[(opcode & 'h0F00) >> 8];
            end
            'hF?18: begin
                $display("HW     : INSTR LD ST, Vx");
               sound_timer =  registers[(opcode & 'h0F00) >> 8];
            end
            'hF?1E: begin
                $display("HW     : INSTR ADD I, Vx");
                index_reg = index_reg + {8'h00, registers[(opcode & 'h0F00) >> 8]};
            end
            'hF?29: begin
                $display("HW     : INSTR LDL F, Vx");
                index_reg = registers[(opcode & 'h0F00) >> 8] * 5;
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
            default: $display("HW     : ILLEGAL INSTRUCTION");
        endcase
        if (!halt) 
            program_counter += 2;
        cycle_counter++;
    end
endmodule

// pseudo random number generator
module randomizer (
    input wire clk_in,
    input wire [15:0] pc,
    input bit keyboard [15:0],
    input int cycle_counter,
    output bit [7:0] rand_bit
    );

    bit [7:0] last;
    int i;
    
    always_ff @(posedge clk_in) begin
        for (i = 0; i < 8; i++) begin
            rand_bit[i] ^= ~keyboard[i] ? cycle_counter[i] : cycle_counter[7-i];
            rand_bit[i] ^= (cycle_counter % 7) == 0 ? pc[i] : ~pc[i];
            rand_bit[i] ^= keyboard[i+7] ? ~last[i] : last[i];
        end 
        last = rand_bit;
        $display("Randomizer is: %b", rand_bit);
    end
endmodule

module chip8_gpu (
    input wire [31:0] vram [0:2047],
    input wire [7:0] sound_timer
    );
    import "DPI-C" function void draw_screen(logic [31:0] vram [0:2047], bit beep);
    always_comb begin
       draw_screen(vram, sound_timer > 0); 
    end
endmodule

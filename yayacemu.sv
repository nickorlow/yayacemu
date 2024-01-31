module yayacemu (
    input wire clk_in
    );
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
    cpu cpu (memory, clk_in, keyboard, rand_num, vram, stack, index_reg, stack_pointer, registers, delay_timer, sound_timer, cycle_counter, program_counter, halt, watch_key);
    beeper beeper(sound_timer);
    gpu gpu (vram);

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
    end

endmodule

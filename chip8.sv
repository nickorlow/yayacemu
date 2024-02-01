module chip8 (
    input wire clk_in
    );

    bit [31:0] vram [0:2047];
    bit [7:0] memory [0:4095];

    bit keyboard [15:0];

    bit [7:0] sound_timer;
    bit [15:0] program_counter;
    int cycle_counter;

    bit [7:0] random_number;


    beeper     beeper  (sound_timer);
    cpu        cpu     (memory, clk_in, keyboard, random_number, cycle_counter, program_counter, vram, sound_timer);
    gpu        gpu     (vram);
    keyboard   kb      (clk_in, keyboard);
    rng        randy   (clk_in, program_counter, keyboard, cycle_counter, random_number);
    rom_loader loader  (memory);

    initial begin 
        bit [7:0] fontset [79:0] = {
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

        // Load fontset into memory
        for(int i = 0; i < 80; i++) begin
            memory[i] = fontset[79-i];
        end
       
        // Initialize keyboard bits
        for(int i = 0; i < 15; i++) begin
            keyboard[i] = 0;
        end
    end
endmodule

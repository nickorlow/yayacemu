module rom_loader (
    output bit [7:0] memory [0:4095],
    output logic rom_ready
    );

    import "DPI-C" function int load_rom();
    import "DPI-C" function bit [7:0] get_next_instr();
    import "DPI-C" function void close_rom();

    int rom_size;
    int i;

    initial begin
        rom_size = load_rom();
        $display("HW     : ROM size is %0d bytes (%0d bits) (%0d instructions)", rom_size, rom_size * 8, rom_size / 2);
        for (i = 0; i < rom_size; i++) begin
            memory[i] = get_next_instr();
        end
        close_rom();
        $display("HW     : ROM loaded successfully");
        rom_ready = 1;
    end
endmodule

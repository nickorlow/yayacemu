module beeper (
    input wire [7:0] sound_timer
    );

    import "DPI-C" function void set_beep(bit beep);

    always_comb begin
       set_beep(sound_timer > 0); 
    end
endmodule

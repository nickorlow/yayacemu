.PHONY: run clean format

SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`
SV_FILES=aastructs.sv cpu.sv chip8.sv gpu.sv alu.sv keypad.sv

lint:
	verilator --lint-only -DDUMMY_GPU --timing ${SV_FILES} 

build-rom:
	python3 ./gen_rom.py ${ROM_FILE} rom.bin

build: build-rom
	verilator --cc --exe --build --timing -j 0 --top-module chip8 *.sv yayacemu.cpp -DDUMMY_KEYPAD -DDUMMY_GPU -DFAST_CLK -CFLAGS "${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}" && clear

run: build
	obj_dir/Vchip8	

clean:
	rm -rf obj_dir db incremental_db

format:
	verible-verilog-format *.sv --inplace && clang-format *.cpp -i

build-fpga: *.sv *.qsf *.qpf rom.bin build-rom
	quartus_sh --flow compile chip8 && ./make_cdf.sh  && \
		notify-send "Quartus Build Complete"

run-fpga: 
	quartus_pgm -m jtag -o "p;./output_files/chip8.sof" ./output_files/chip8.cdf

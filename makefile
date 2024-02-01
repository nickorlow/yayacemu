.PHONY: run clean format

SDL_CFLAGS = `sdl2-config --cflags`
SDL_LDFLAGS = `sdl2-config --libs`

lint:
	verilator --lint-only --timing *.sv

build: lint
	verilator --cc --exe --build --timing -j 0 --top-module chip8 *.sv yayacemu.cpp -CFLAGS "${SDL_CFLAGS}" -LDFLAGS "${SDL_LDFLAGS}" && clear

run: build
	obj_dir/Vchip8 ${ROM_FILE}	

clean:
	rm -rf obj_dir

format:
	verible-verilog-format *.sv --inplace && clang-format *.cpp -i




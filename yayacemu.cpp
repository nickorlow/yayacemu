#include "svdpi.h"
#include "Vyayacemu__Dpi.h"
#include <stdio.h>
#include <memory.h>

#include "Vyayacemu.h"
#include "verilated.h"

#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <SDL2/SDL_quit.h>
#include <SDL2/SDL_timer.h>
#include <inttypes.h>

#define SCREEN_WIDTH 64
#define SCREEN_HEIGHT 32
#define EMULATION_HZ 480

FILE *rom_file;
SDL_Window *window;
SDL_Renderer *renderer;
SDL_Texture *texture;
char* rom_name;

void init_screen() {
  SDL_Init(SDL_INIT_EVERYTHING);
  window =
      SDL_CreateWindow("Yet Another Yet Another Chip-8 Emulator", // creates a window
                       SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
                       SCREEN_WIDTH * 10, SCREEN_HEIGHT * 10, 0);
  renderer =
      SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888,
                                           SDL_TEXTUREACCESS_STREAMING,
                                           SCREEN_WIDTH, SCREEN_HEIGHT);
  printf("INF_EMU: Screen initialized\n");
}

void draw_screen(const svLogicVecVal* vram) {
  uint32_t *screen = (uint32_t*) malloc(SCREEN_WIDTH*SCREEN_HEIGHT*32);
  for(int i = 0; i < SCREEN_WIDTH * SCREEN_HEIGHT; i++) {
      screen[i] = vram[i].aval;
  }
  SDL_UpdateTexture(texture, NULL, screen,
                        sizeof(screen[0]) * SCREEN_WIDTH);
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
  printf("INF_EMU: Drawing Frame\n");
}

int load_rom() {
  printf("INF_EMU: Loading ROM %s\n", rom_name);

  rom_file = fopen(rom_name, "r");

  if (rom_file == NULL) {
    printf("INF_EMU: Error reading ROM file. Panicing.\n");
    exit(1); 
  }

  fseek(rom_file, 0L, SEEK_END);
  int rom_size = ftell(rom_file);
  fseek(rom_file, 0L, SEEK_SET);
  printf("INF_EMU: ROM size is %d bytes\n", rom_size);

  return rom_size;
}

svBitVecVal get_next_instr() {
    return (uint8_t) fgetc(rom_file);
}

void close_rom() {
    fclose(rom_file);
}

int get_num() {
    return 1;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        printf("Use: yayacemu [ROM_NAME]");
        exit(1);
    }
    rom_name = argv[1];
    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Vyayacemu* top = new Vyayacemu{contextp};
    //while (!contextp->gotFinish()) {
    for (int i = 0; i < 2000; i++) { 
        top->clk_in ^= 1;
        top->eval(); 
        usleep(1000000/EMULATION_HZ);
    }
    printf("TB     : Testbench has reached end of simulation. Pausing for 10 seconds before exiting");
    fflush(stdout);
    usleep(3000000);
    delete top;
    delete contextp;
    return 0;
}

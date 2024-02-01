#include "svdpi.h"
#include "Vchip8__Dpi.h"
#include <iostream>
#include <memory.h>
#include "Vchip8.h"
#include "verilated.h"
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <SDL2/SDL_quit.h>
#include <SDL2/SDL_timer.h>
#include <inttypes.h>

#define SCREEN_WIDTH 64
#define SCREEN_HEIGHT 32
#define EMULATION_HZ 2000

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
  std::cout << "INF_EMU: Screen initialized" << '\n';
}

void set_beep(const svBit beep) {
  if (beep == 1)
      SDL_SetTextureColorMod(texture, 255, 0, 0);
  else
      SDL_SetTextureColorMod(texture, 255, 255, 255);
}

void draw_screen(const svLogicVecVal* vram) {
  uint32_t *screen = (uint32_t*) malloc(SCREEN_WIDTH*SCREEN_HEIGHT*32);
  for(int i = 0; i < SCREEN_WIDTH * SCREEN_HEIGHT; i++) {
      screen[i] = vram[i].aval;
  }
  SDL_UpdateTexture(texture, NULL, screen, sizeof(screen[0]) * SCREEN_WIDTH);
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
  free(screen);
  std::cout << "INF_EMU: Drawing Frame" << '\n';
}

int load_rom() {
    std::cout << "INF_EMU: Loading ROM " << rom_name << '\n';
  rom_file = fopen(rom_name, "r");

  if (rom_file == NULL) {
      std::cout << "INF_EMU: Error reading ROM file. Panicing." << '\n';
    exit(1); 
  }

  fseek(rom_file, 0L, SEEK_END);
  int rom_size = ftell(rom_file);
  fseek(rom_file, 0L, SEEK_SET);
  std::cout << "INF_EMU: ROM size is %d bytes " << rom_size << '\n';

  return rom_size;
}

svBitVecVal get_next_instr() {
    return (uint8_t) fgetc(rom_file);
}

void close_rom() {
    fclose(rom_file);
}

svBitVecVal get_key() {
    SDL_Event event;
    uint8_t down = 0;

    while(SDL_PollEvent(&event)) {
        switch(event.type) {
            case SDL_KEYDOWN:
                down = 128;
            case SDL_KEYUP: 
                switch(event.key.keysym.sym) {
                    case SDLK_0:
                        return down | (uint8_t) 0;
                    case SDLK_1:
                        return down | (uint8_t) 1;
                    case SDLK_2:
                        return down | (uint8_t) 2;
                    case SDLK_3:
                        return down | (uint8_t) 3;
                    case SDLK_4:
                        return down | (uint8_t) 4;
                    case SDLK_5:
                        return down | (uint8_t) 5;
                    case SDLK_6:
                        return down | (uint8_t) 6;
                    case SDLK_7:
                        return down | (uint8_t) 7;
                    case SDLK_8:
                        return down | (uint8_t) 8;
                    case SDLK_9:
                        return down | (uint8_t) 9;
                    case SDLK_a:
                        return down | (uint8_t) 10;
                    case SDLK_b:
                        return down | (uint8_t) 11;
                    case SDLK_c:
                        return down | (uint8_t) 12;
                    case SDLK_d:
                        return down | (uint8_t) 13;
                    case SDLK_e:
                        return down | (uint8_t) 14;
                    case SDLK_f:
                        return down | (uint8_t) 15;
                    default:
                        return 255;
                }
                
            
            default:
                return 255; 
        }
    }
    return 255;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::cout << "Use: yayacemu [ROM_NAME]" << '\n';
        exit(1);
    }

    rom_name = argv[1];

    VerilatedContext* contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);

    Vchip8* dut = new Vchip8{contextp};

    while (true) { 
        dut->clk_in ^= 1;
        dut->eval(); 
        usleep(1000000/EMULATION_HZ);
        if (SDL_QuitRequested()) {
          std::cout << "INF_EMU: Received Quit from SDL. Goodbye!" << '\n';
          break;
        }
    }

    fflush(stdout);
    delete dut;
    delete contextp;
    return 0;
}

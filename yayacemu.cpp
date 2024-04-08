#include "Vchip8.h"
#include "Vchip8__Dpi.h"
#include "svdpi.h"
#include "verilated.h"
#include <SDL2/SDL.h>
#include <SDL2/SDL_image.h>
#include <SDL2/SDL_quit.h>
#include <SDL2/SDL_timer.h>
#include <inttypes.h>
#include <iostream>
#include <memory.h>

#define SCREEN_WIDTH 128 
#define SCREEN_HEIGHT 64 
#define EMULATION_HZ 10000

SDL_Window *window;
SDL_Renderer *renderer;
SDL_Texture *texture;

void init_screen() {
  SDL_Init(SDL_INIT_EVERYTHING);
  window = SDL_CreateWindow(
      "Yet Another Yet Another Chip-8 Emulator", // creates a window
      SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, SCREEN_WIDTH * 10,
      SCREEN_HEIGHT * 10, 0);
  renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED);

  texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888,
                              SDL_TEXTUREACCESS_STREAMING, SCREEN_WIDTH,
                              SCREEN_HEIGHT);
  std::cout << "INF_EMU: Screen initialized" << '\n';
}

void set_beep(const svBit beep) {
  if (beep == 1)
    SDL_SetTextureColorMod(texture, 255, 0, 0);
  else
    SDL_SetTextureColorMod(texture, 255, 255, 255);
}

void draw_screen(const svLogicVecVal *vram) {
  uint32_t *screen = (uint32_t *)malloc(SCREEN_WIDTH * SCREEN_HEIGHT * 32);
  for (int i = 0; i < 1024; i++) {
      uint8_t line_byte = (uint8_t) vram[i].aval;
      for (int j = 0; j < 8; j++) {
            uint8_t pixel_val = (line_byte >> (7-j)) & 1;
            screen[(i*8) + j] = pixel_val == 1 ? 0xFFFFFFFF : 0x00000000;
      }
  }
  SDL_UpdateTexture(texture, NULL, screen, sizeof(screen[0]) * SCREEN_WIDTH);
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
  free(screen);
  std::cout << "INF_EMU: Drawing Frame" << '\n';
}

svBitVecVal get_key() {
  SDL_Event event;
  uint8_t down = 0;

  while (SDL_PollEvent(&event)) {
    switch (event.type) {
    case SDL_KEYDOWN:
      down = 128;
    case SDL_KEYUP:
      switch (event.key.keysym.sym) {
      case SDLK_0:
        return down | (uint8_t)0;
      case SDLK_1:
        return down | (uint8_t)1;
      case SDLK_2:
        return down | (uint8_t)2;
      case SDLK_3:
        return down | (uint8_t)3;
      case SDLK_4:
        return down | (uint8_t)4;
      case SDLK_5:
        return down | (uint8_t)5;
      case SDLK_6:
        return down | (uint8_t)6;
      case SDLK_7:
        return down | (uint8_t)7;
      case SDLK_8:
        return down | (uint8_t)8;
      case SDLK_9:
        return down | (uint8_t)9;
      case SDLK_a:
        return down | (uint8_t)10;
      case SDLK_b:
        return down | (uint8_t)11;
      case SDLK_c:
        return down | (uint8_t)12;
      case SDLK_d:
        return down | (uint8_t)13;
      case SDLK_e:
        return down | (uint8_t)14;
      case SDLK_f:
        return down | (uint8_t)15;
      default:
        return 255;
      }

    default:
      return 255;
    }
  }
  return 255;
}

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);

  Vchip8 *dut = new Vchip8{contextp};

  dut->rst_in = 0;
  dut->fpga_clk = 1;
  while (true) {
    dut->fpga_clk ^= 1;
    dut->eval();

    usleep(1000000 / EMULATION_HZ);

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

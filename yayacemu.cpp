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
#define EMULATION_HZ 100000

SDL_Window *window;
SDL_Renderer *renderer;
SDL_Texture *texture;

int keys[16];
bool is_beeping;

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
}

void draw_screen(const svLogicVecVal *vram) {
  uint32_t *screen = (uint32_t *)malloc(SCREEN_WIDTH * SCREEN_HEIGHT * 32);
  for (int i = 0; i < 1024; i++) {
    uint8_t line_byte = (uint8_t)vram[i].aval;
    for (int j = 0; j < 8; j++) {
      uint8_t pixel_val = (line_byte >> (7 - j)) & 1;
      screen[(i * 8) + j] = pixel_val == 1 ? 0xFFFFFFFF : (is_beeping ? 0xFF000000 : 0x00000000);
    }
  }
  SDL_UpdateTexture(texture, NULL, screen, sizeof(screen[0]) * SCREEN_WIDTH);
  SDL_RenderClear(renderer);
  SDL_RenderCopy(renderer, texture, NULL, NULL);
  SDL_RenderPresent(renderer);
  free(screen);
}

uint8_t get_key(uint8_t col) {
  SDL_Event event;
  uint8_t res = 0xFF;

  while (SDL_PollEvent(&event)) {
    uint8_t down = 0;
    switch (event.type) {
    case SDL_KEYDOWN:
      down = 1;
    case SDL_KEYUP:
      switch (event.key.keysym.sym) {

      case SDLK_1:
        keys[1] = down;
        break;
      case SDLK_2:
        keys[2] = down;
        break;
      case SDLK_3:
        keys[3] = down;
        break;
      case SDLK_a:
        keys[10] = down;
        break;

      case SDLK_4:
        keys[4] = down;
        break;
      case SDLK_5:
        keys[5] = down;
        break;
      case SDLK_6:
        keys[6] = down;
        break;
      case SDLK_7:
        keys[7] = down;
        break;
      case SDLK_b:
        keys[11] = down;
        break;

      case SDLK_8:
        keys[8] = down;
        break;
      case SDLK_9:
        keys[9] = down;
        break;
      case SDLK_c:
        keys[12] = down;
        break;

      case SDLK_0:
        keys[0] = down;
        break;
      case SDLK_e:
        keys[14] = down;
        break;
      case SDLK_f:
        keys[15] = down;
        break;
      case SDLK_d:
        keys[13] = down;
        break;
      }
    }
  }

  if (keys[0] == 1) {
    if (col == 0b1110)
      res = res & 0b0111;
  }

  if (keys[1] == 1) {
    if (col == 0b1101)
      res = res & 0b1110;
  }

  if (keys[2] == 1) {
    if (col == 0b1110)
      res = res & 0b1110;
  }

  if (keys[3] == 1) {
    if (col == 0b1011)
      res = res & 0b1110;
  }

  if (keys[4] == 1) {
    if (col == 0b1101)
      res = res & 0b1101;
  }
  if (keys[5] == 1) {
    if (col == 0b1110)
      res = res & 0b1101;
  }
  if (keys[6] == 1) {
    if (col == 0b1011)
      res = res & 0b1101;
  }
  if (keys[7] == 1) {
    if (col == 0b1101)
      res = res & 0b1011;
  }

  if (keys[8] == 1) {
    if (col == 0b1110)
      res = res & 0b1011;
  }
  if (keys[9] == 1) {
    if (col == 0b1011)
      res = res & 0b1011;
  }

  if (keys[10] == 1) {
    if (col == 0b1101)
      res = res & 0b0111;
  }

  if (keys[11] == 1) {
    if (col == 0b1011)
      res = res & 0b0111;
  }

  if (keys[12] == 1) {
    if (col == 0b0111)
      res = res & 0b1110;
  }

  if (keys[13] == 1) {
    if (col == 0b0111)
      res = res & 0b1101;
  }

  if (keys[14] == 1) {
    if (col == 0b0111)
      res = res & 0b1011;
  }

  if (keys[15] == 1) {
    if (col == 0b0111)
      res = res & 0b0111;
  }

  return res;
}

int main(int argc, char **argv) {
  VerilatedContext *contextp = new VerilatedContext;
  contextp->commandArgs(argc, argv);

  Vchip8 *dut = new Vchip8{contextp};

  dut->rst_in = 0;
  dut->fpga_clk = 1;
  while (true) {
    dut->row = get_key(dut->col);
    dut->fpga_clk ^= 1;
    dut->eval();

    is_beeping = dut->beep == 1;

    if (SDL_QuitRequested()) {
      std::cout << "Goodbye!" << '\n';
      break;
    }
  }

  fflush(stdout);
  delete dut;
  delete contextp;
  return 0;
}

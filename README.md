# Yet another yet another Chip-8 emulator (yayacemu)

[Because one just wasn't enough](https://github.com/nickorlow/yacemu). 

A Chip-8 emulator (interpreter) written in SystemVerilog with I/O simulated with C++ also depends on SDL2.

### Building & Testing 

In order to run yayacemu, you must have sdl2, verilator, and make installed.

Once you have the dependencies installed, you can build the emulator with:
```shell
make build
```

You can build start the emulator with:
```shell
make run ROM_FILE=[PATH_TO_YOUR_ROM]
```


### Running

If you have a binary, you can run it with the following:

```shell
yayacemu [PATH_TO_YOUR_ROM]
```

### Todo
- [x] Graphics
- [x] Corax+ Required Instructions
- [x] Proper Flag Handling 
- [x] Working Input
- [x] More Instructions
- [x] Tetris Working Running
- [x] Pass Quirks Test 
- [x] Add beeper (instead of sound, screen becomes red)
- [x] Add all Instructions
- [x] Implement a real (synthesizeable, pseudorandom) random module 
- [x] Code cleanup
- [ ] Deploying to an FPGA with a real screen, keypad, and beeper 

### Screenshots

![Chip 8 Logo Demo on an FPGA!](https://github.com/nickorlow/yayacemu/blob/main/screenshots/chip8_fpga.jpg?raw=true)
![Chip 8 Logo Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/chip8-logo.png?raw=true)
![IBM Logo Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/ibm-logo.png?raw=true)
![CORAX+ Test Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/corax.png?raw=true)
![Flag Test Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/flags.png?raw=true)
![Quirk Test Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/quirks.png?raw=true)
![Tetris Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/tetris.png?raw=true)
![Beeper Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/beeper.png?raw=true)

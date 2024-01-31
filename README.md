# Yet Another Yet Another Chip-8 Emulator (yayacemu)

[Because one just wasn't enough](https://github.com/nickorlow/yacemu). 

A Chip-8 emulator (interpreter) written in SystemVerilog with I/O simulated with C++ also depends on SDL2.

Note: Code quality is bad at the moment because I just wanted to get graphics working and didn't pay much attention to it. I will fix tomorrow.

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
- [ ] Add beeper (instead of sound, screen becomes red)
- [ ] Implement a real random module 
- [ ] Code cleanup
- [x] All Instructions

### Screenshots

![Chip 8 Logo Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/chip8-logo.png?raw=true)
![IBM Logo Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/ibm-logo.png?raw=true)
![CORAX+ Test Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/corax.png?raw=true)
![Flag Test Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/flags.png?raw=true)
![Quirk Test Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/quirks.png?raw=true)
![Tetris Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/tetris.png?raw=true)

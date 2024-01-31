# Yet Another Yet Another Chip-8 Emulator (yayacemu)

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
- [ ] Corax+ Required Instructions
- [ ] Proper Flag Handling 
- [ ] Working Input
- [ ] More Instructions
- [ ] Tetris Working Running
- [ ] Pass Quirks Test (DispQuirk is a bit touchy) 
- [ ] Add beeper (instead of sound, screen becomes red)
- [ ] Code cleanup
- [ ] All Instructions

### Screenshots

![Chip 8 Logo Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/chip8-logo.png?raw=true)
![IBM Logo Demo](https://github.com/nickorlow/yayacemu/blob/main/screenshots/ibm-logo.png?raw=true)

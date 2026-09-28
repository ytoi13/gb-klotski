# Game Boy Klotski

![](https://s1.img-e.com/20260928/6aba793baf3d3.png)![](https://s1.img-e.com/20260928/6aba793bacbd2.png)

![](https://s1.img-e.com/20260928/6aba79416c98c.png)![](https://s1.img-e.com/20260928/6aba79416b51d.png)

This project is an assembly implementation of Klotski (华容道) designed for the Nintendo Game Boy.

The source code was last modified on **January 7, 2025**.

## Download

https://github.com/ytoi13/gb-klotski/releases/download/v1.0.0/main.gb

## Build From Source

### Installing the Toolchain

**RGBDS v0.8.0:** Please check the page https://rgbds.gbdev.io/docs/v0.8.0.

Due to breaking changes introduced in RGBDS 1.0+, compilation is only verified on **v0.8.0**.

### Running the Toolchain

```bash
rgbasm main.asm -o main.o # assemble
rgblink main.o -o main.gb # link
rgbfix -v -p 0xFF main.gb # fix header
```

## Run

You need a Game Boy emulator to run the game. **mGBA** is one of the recommendations for ease of use. Please check the page https://mgba.io/downloads.html.

Install an emulator, download or build your `.gb` file, and open it with the emulator.

## Play

The goal of Klotski is to slide the wooden blocks to help Cao Cao (曹操, the 2x2 square block) escape through the opening at the bottom of the board.

* Watch out: You must solve the puzzle in under **255 steps**!
* For full game background and design details, see `report.pdf`.

### Controls

| Game Boy Button | mGBA (Default PC Key) | Action                                      |
| --------------- | --------------------- | ------------------------------------------- |
| **D-Pad**       | Arrow Keys            | Move cursor / move selected block           |
| **A Button**    | `X`                   | Select/grab block (press direction to move) |
| **B Button**    | `Z`                   | Skip to the next level                      |
| **Select**      | `Backspace`           | Restart current level                       |
| **Start**       | `Enter`               | Start game / confirm                        |

## Acknowledgments

* Prof. Guillaume Hoffmann from CONICET
* My teammates: Chen Nuo, Liu Mingsong, Wang Shang from GTIIT
* Main reference: https://gbdev.io/gb-asm-tutorial/index.html
* `hardware.inc`: https://github.com/gbdev/hardware.inc

## License

MIT

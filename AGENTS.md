# AGENTS.md -- AI Agent Guide for SNES Development with SNESser

## SNES Architecture Overview

The SNES has three main processors:

- **65816 CPU** (Ricoh 5A22): 16-bit CPU running at 3.58 MHz (FastROM) or 2.68 MHz (SlowROM). Executes game logic. 24-bit address space (16MB).
- **PPU** (Picture Processing Unit): Handles all graphics. 64KB VRAM, 512 bytes CGRAM (palette), 544 bytes OAM (sprites). Supports 8 background modes, 128 sprites.
- **SPC700** (Sony DSP): Independent 8-bit audio CPU with 64KB RAM. Communicates with main CPU via 4 I/O ports ($2140-$2143).

### Memory Map (LoROM)

| Address | Contents |
|---------|----------|
| $00:0000-$00:1FFF | WRAM (first 8KB, mirrored) |
| $00:2100-$00:213F | PPU registers |
| $00:2140-$00:2143 | APU (SPC700) I/O ports |
| $00:4200-$00:421F | CPU I/O registers |
| $00:4300-$00:437F | DMA registers |
| $00:8000-$00:FFFF | ROM bank 0 (32KB) |
| $7E:0000-$7F:FFFF | Full 128KB WRAM |

## Framework Structure

```
snesser/
├── lib/                    # Reusable assembly libraries
│   ├── registers.inc       # All hardware register definitions
│   ├── header.inc          # ROM header + vector table macros
│   ├── init.asm            # Boot initialization (CPU, PPU, RAM clear)
│   ├── input.asm           # Joypad reading with edge detection
│   ├── dma.asm             # DMA helpers (VRAM, CGRAM, OAM)
│   ├── ppu.asm             # PPU mode/layer/brightness setup
│   ├── math.asm            # Hardware multiply/divide wrappers
│   └── spc700.asm          # SPC700 sound driver upload + control
├── cfg/
│   └── lorom256k.cfg       # Linker config for 256KB LoROM
├── tools/
│   ├── setup.sh            # Install cc65 + Python deps
│   └── png2snes.py         # PNG -> SNES 4bpp tiles + palette
├── games/tetris/           # Full Tetris implementation
└── templates/hello/        # Minimal ROM starting point
```

## Creating a New Game

1. Copy the template:
   ```bash
   cp -r templates/hello/ games/mygame/
   ```

2. Edit `games/mygame/main.asm` -- update ROM_HEADER title, add init and game loop.

3. Edit `games/mygame/Makefile` -- add source files and lib modules.

4. Build:
   ```bash
   make -C games/mygame
   ```

## Critical 65816 Pitfalls

These are the most common bugs in SNES assembly. Every one of these has caused real crashes in this codebase.

### B Accumulator Pollution (Most Common Bug)

The 65816 accumulator is always 16-bit internally: `C = B:A`. The `sep #$20` instruction makes **A** 8-bit, but the hidden **B** byte persists and is NOT cleared by mode switches.

**The problem:** `tax` and `tay` always transfer the full 16-bit C register (B:A), not just A. In 8-bit mode, if B contains garbage, your index register gets corrupted.

```asm
; BROKEN -- B byte pollutes X
sep #$20
.a8
lda some_byte       ; A = value, B = unknown garbage
tax                  ; X = B:A, NOT just A!
lda table,x         ; Reads from wrong address

; CORRECT -- zero-extend before transfer
sep #$20
.a8
lda some_byte
rep #$20
.a16
and #$00FF           ; Clears B byte
tax                  ; X = $00:A, correct
sep #$20
.a8
lda table,x
```

**Rule:** Every `tax` or `tay` where A is in 8-bit mode MUST be preceded by `rep #$20; and #$00FF` (or `and #$003F`, `and #$000F`, etc. depending on the valid range).

### Stack Size Mismatch

`pha` and `pla` push/pop different sizes depending on the M flag (8-bit vs 16-bit A):

```asm
; FATAL -- stack imbalance corrupts return address
sep #$20
.a8
pha                  ; Pushes 1 byte
; ... later ...
rep #$20
.a16
pla                  ; Pops 2 bytes! Eats 1 byte of return address
; rts now jumps to garbage
```

**Rule:** Always match `pha`/`pla` in the same register width. Use `php`/`plp` to save/restore the processor status if you need to change widths within a function.

### VBlank Timing Overflow

LoROM SlowROM ($20 map mode) runs at 2.68 MHz = ~6,300 CPU cycles per VBlank. VRAM is only writable during VBlank or force blank. Writes outside VBlank are **silently dropped** (no error, no crash -- just missing graphics).

If your rendering takes more than ~6,300 cycles, use force blank:

```asm
; Force blank during heavy VRAM writes
lda #$80
sta INIDISP          ; Screen off (force blank, VRAM writable)

; ... do all VRAM writes ...

lda #$0F
sta INIDISP          ; Screen on, full brightness
```

This causes a brief screen blank but guarantees all writes succeed. The Tetris game uses this approach in `render_frame`.

### Write-Only Registers

Many SNES registers are write-only (NMITIMEN, INIDISP, BGMODE, etc.). Reading them returns open bus garbage. Never do read-modify-write on write-only registers:

```asm
; BROKEN
lda NMITIMEN         ; Returns garbage (write-only)
ora #$01
sta NMITIMEN

; CORRECT
lda #$81             ; NMI enable + auto-joypad
sta NMITIMEN
```

### Init Order Matters

The 65816 boots in emulation mode (8-bit, 6502 compatible). You must switch to native mode and set up the stack BEFORE calling any subroutines:

```asm
reset_handler:
    sei              ; Disable interrupts
    clc
    xce              ; Switch to native 65816 mode
    rep #$38         ; 16-bit A/X/Y, clear decimal
    ldx #$1FFF
    txs              ; Set stack
    ; NOW safe to jsr
```

If `snes_init` is called while still in emulation mode, the stack is only 256 bytes ($0100-$01FF) and nested calls overflow it immediately.

## Common Patterns

### VBlank Rendering Loop

```asm
main_loop:
    lda #$01
    sta nmi_ready
@wait:
    wai
    lda nmi_ready
    bne @wait
    ; ... game logic ...
    bra main_loop

nmi_handler:
    lda RDNMI        ; Acknowledge NMI
    lda nmi_ready
    beq @skip
    jsr render_frame  ; VRAM writes here
    stz nmi_ready
@skip:
    rti
```

### DMA Transfers

Use DMA for bulk data transfers to VRAM. Never write large amounts byte-by-byte.

```asm
rep #$20
lda #$0400           ; VRAM word address
sta VMADDL
sep #$20
lda #$01             ; Word transfer, incrementing
sta DMAP0
lda #$18             ; Destination: VMDATAL
sta BBAD0
rep #$20
lda #my_data         ; Source address
sta A1T0L
sep #$20
stz A1B0             ; Source bank = 0
rep #$20
lda #data_size       ; Byte count
sta DAS0L
sep #$20
lda #$01
sta MDMAEN           ; Trigger DMA channel 0
```

### Input Handling

```asm
jsr input_read       ; Call once per frame

rep #$20
lda joy1_pressed     ; Buttons just pressed this frame (edge-triggered)
and #JOY_A
beq @no_a
; A was just pressed
@no_a:

lda joy1_current     ; Buttons currently held
and #JOY_LEFT
beq @no_left
; Left is being held
@no_left:
```

### Button Constants

| Constant | Bit | Button |
|----------|-----|--------|
| JOY_B | $8000 | B |
| JOY_Y | $4000 | Y |
| JOY_SELECT | $2000 | Select |
| JOY_START | $1000 | Start |
| JOY_UP | $0800 | D-pad Up |
| JOY_DOWN | $0400 | D-pad Down |
| JOY_LEFT | $0200 | D-pad Left |
| JOY_RIGHT | $0100 | D-pad Right |
| JOY_A | $0080 | A |
| JOY_X | $0040 | X |
| JOY_L | $0020 | L shoulder |
| JOY_R | $0010 | R shoulder |

## Register Quick Reference

### PPU Control
| Register | Address | Purpose |
|----------|---------|---------|
| INIDISP | $2100 | Screen on/off + brightness (0-15). Bit 7 = force blank. |
| BGMODE | $2105 | BG mode (0-7) |
| BGnSC | $2107-$210A | BG tilemap VRAM address + size |
| BG12NBA | $210B | BG1/2 tile data VRAM address |
| VMAIN | $2115 | VRAM address increment mode. $80 = increment after high byte write. |
| VMADDL/H | $2116-$2117 | VRAM word address |
| VMDATAL/H | $2118-$2119 | VRAM data write |
| CGADD | $2121 | Palette address |
| CGDATA | $2122 | Palette data write |
| TM | $212C | Main screen layer enable |

### CPU/DMA
| Register | Address | Purpose |
|----------|---------|---------|
| NMITIMEN | $4200 | NMI/IRQ/auto-joypad enable (write-only) |
| RDNMI | $4210 | NMI flag (read to acknowledge) |
| HVBJOY | $4212 | VBlank/auto-joypad status |
| JOY1L/H | $4218-$4219 | Joypad 1 state |
| MDMAEN | $420B | DMA channel enable/trigger |
| WRDIVL | $4204 | Division dividend (16-bit) |
| WRDIVB | $4206 | Division divisor (8-bit, triggers calc) |
| RDDIVL | $4214 | Division quotient (16-bit, read after 8 NOPs) |
| RDMPYL | $4216 | Division remainder (16-bit) |

## Graphics Pipeline

1. Create art as PNG (8x8 pixel grid, max 16 colors per palette)
2. Convert: `python3 tools/png2snes.py art.png --tiles tiles.inc --palette palette.inc`
3. Include in .asm: `.include "tiles.inc"` and `.include "palette.inc"`
4. Upload to VRAM during init using DMA
5. Write tilemap entries to set which tiles appear where

### SNES Color Format
15-bit color, little-endian: `0bbbbbgggggrrrrr`

### 4bpp Tile Format
Each 8x8 tile is 32 bytes. Bitplanes interleaved: bytes 0-15 for BP0/BP1, bytes 16-31 for BP2/BP3.

### Tilemap Entry Format
16-bit: `vhopppcc cccccccc` -- v=vflip, h=hflip, o=priority, ppp=palette, c=tile index.

## Piece Rotation Data Format

Tetromino rotations are stored as 16-bit bitmasks in a 4x4 grid (row-major):
- Bit 15 = (row 0, col 0), bit 0 = (row 3, col 3)
- Within each nibble: bit 3 = leftmost column, bit 0 = rightmost
- Index into table: `piece_id * 8 + rotation * 2`
- All rotations use SRS (Super Rotation System) positioning

## Sound

The SPC700 is currently disabled (`spc_init` commented out in `main.asm`). The upload protocol needs debugging. Sound effect calls are safe no-ops when `spc_ready = 0`.

Sound effect IDs: $01 = click, $02 = line clear, $03 = tetris, $04 = game over, $FF = silence.

## Build Commands

```bash
make setup              # Install cc65 toolchain
make                    # Build all games
make -C games/tetris    # Build just Tetris
make -C templates/hello # Build hello template
make clean              # Remove all build artifacts
```

## Debugging Tips

- **bsnes-plus** or **Mesen-S** have the best SNES debuggers: breakpoints, VRAM viewer, trace logging.
- **Black screen**: Check INIDISP ($0F for full brightness), TM (enable BG layers), tilemap/chr address config, and that you switched to native mode before calling subroutines.
- **Crash after N pieces/lines**: Almost certainly B accumulator pollution on a `tax`/`tay`. Add `rep #$20; and #$00FF` before every transfer.
- **Garbled graphics**: Tile format mismatch (2bpp vs 4bpp), wrong VRAM address, bitplane order wrong.
- **No input**: NMITIMEN bit 0 must be set (auto-joypad). Wait for HVBJOY bit 0 to clear before reading.
- **Score crash**: Check for stack size mismatches (pha in 8-bit mode, pla in 16-bit mode).
- **Silent VRAM drops**: Writes outside VBlank/force-blank are silently ignored. Use force blank for heavy rendering.

## 65816 Assembly Tips

- Always track register sizes. Use `.a8`, `.a16`, `.i8`, `.i16` directives after `sep`/`rep`.
- `sep #$20` = 8-bit A, `rep #$20` = 16-bit A.
- `sep #$10` = 8-bit index, `rep #$10` = 16-bit index.
- `rep #$30` = 16-bit A + index. `sep #$30` = 8-bit both.
- Zero page ($0000-$00FF) is fast -- use `.segment "ZEROPAGE"` for frequent variables.
- `wai` halts CPU until next interrupt -- use for frame timing.
- Hardware division (WRDIVL/WRDIVB) needs 8 NOP cycles before reading the result.
- `.exportzp` / `.importzp` for zero-page cross-module references, `.export` / `.import` for everything else.

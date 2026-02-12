; =============================================================================
; ppu.asm — PPU Helper Routines
; =============================================================================
; Mode setup, BG configuration, layer enable, brightness control.
; =============================================================================

.include "registers.inc"

.segment "CODE"

.export ppu_set_mode, ppu_set_bg1, ppu_set_bg2, ppu_enable_layers, ppu_set_brightness

; ppu_set_mode — Set the BG mode
; Input: A (8-bit) = mode value for BGMODE register
;   Mode 0: 4 BGs, 4-color each (2bpp)
;   Mode 1: BG1/BG2 16-color (4bpp), BG3 4-color (2bpp)
;   Mode 2: BG1/BG2 16-color (4bpp), offset-per-tile
;   Mode 3: BG1 256-color (8bpp), BG2 16-color (4bpp)
;   Mode 7: Rotation/scaling, 256-color
.proc ppu_set_mode
    sep #$20
    .a8
    sta BGMODE
    rts
.endproc

; ppu_set_bg1 — Configure BG1 tilemap and character data addresses
; Input:
;   A (8-bit) = BG1SC value (tilemap VRAM address >> 8, + size bits)
;               Bits 7-2: VRAM word address >> 10 (tilemap base)
;               Bits 1-0: tilemap size (0=32x32, 1=64x32, 2=32x64, 3=64x64)
;   X (8-bit) = BG12NBA low nibble (BG1 character base VRAM addr >> 12)
.proc ppu_set_bg1
    sep #$20
    .a8
    sta BG1SC               ; Set BG1 tilemap address + size

    txa
    sta BG12NBA             ; Set BG1 chr data address (low nibble = BG1)

    rts
.endproc

; ppu_set_bg2 — Configure BG2 tilemap and character data addresses
; Input:
;   A (8-bit) = BG2SC value
;   X (8-bit) = high nibble of BG12NBA (BG2 chr base >> 12, shifted left 4)
.proc ppu_set_bg2
    sep #$30
    .a8
    .i8
    sta BG2SC

    ; Merge BG2 nibble into BG12NBA without disturbing BG1 nibble
    lda BG12NBA
    and #$0F                ; Keep BG1 nibble
    stx BBAD0               ; Temp store (we'll read X back) — actually just use ora
    ; X has BG2 nibble already shifted
    .repeat 0               ; skip, just OR directly
    .endrepeat
    ; Actually we expect caller to pass X with value already in high nibble
    ora BBAD0               ; No — let's just accept X is the full byte value for simplicity
    ; Simplify: caller sets full BG12NBA value when both BGs are configured
    ; For BG2-only setup, read-modify-write
    txa
    and #$F0
    ora BG12NBA
    sta BG12NBA

    rep #$10
    .i16
    rts
.endproc

; ppu_enable_layers — Enable BG/OBJ layers on main screen
; Input: A (8-bit) = TM register value
;   Bit 0: BG1, Bit 1: BG2, Bit 2: BG3, Bit 3: BG4, Bit 4: OBJ
.proc ppu_enable_layers
    sep #$20
    .a8
    sta TM
    rts
.endproc

; ppu_set_brightness — Set screen brightness
; Input: A (8-bit) = brightness value for INIDISP
;   $00-$0F: brightness 0 (black) to 15 (full)
;   $80: force blank (screen off)
;   $0F: full brightness, screen on
.proc ppu_set_brightness
    sep #$20
    .a8
    sta INIDISP
    rts
.endproc

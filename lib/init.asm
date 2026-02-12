; =============================================================================
; init.asm — SNES Boot Initialization
; =============================================================================
; Sets CPU to native 65816 mode, clears RAM, initializes PPU to known state.
; Call snes_init as the first thing from the RESET vector.
; =============================================================================

.include "registers.inc"

.segment "CODE"

.export snes_init

.proc snes_init
    ; Assumes: native 65816 mode, stack at $1FFF, WRAM cleared.
    ; Caller (reset_handler) handles mode switch, stack, and WRAM.
    sep #$20
    .a8

    ; Force blank (screen off)
    lda #$80
    sta INIDISP

    ; Disable NMI, IRQ, auto-joypad
    stz NMITIMEN

    ; Disable HDMA
    stz HDMAEN

    ; Clear PPU registers
    stz OBSEL               ; OBJ size/base = 0
    stz BGMODE              ; Mode 0
    stz BG1SC
    stz BG2SC
    stz BG3SC
    stz BG4SC
    stz BG12NBA
    stz BG34NBA

    ; Zero all BG scroll registers (write twice for each)
    stz BG1HOFS
    stz BG1HOFS
    stz BG1VOFS
    stz BG1VOFS
    stz BG2HOFS
    stz BG2HOFS
    stz BG2VOFS
    stz BG2VOFS
    stz BG3HOFS
    stz BG3HOFS
    stz BG3VOFS
    stz BG3VOFS
    stz BG4HOFS
    stz BG4HOFS
    stz BG4VOFS
    stz BG4VOFS

    ; VRAM increment mode: increment after writing $2119 (high byte)
    lda #$80
    sta VMAIN

    ; Clear TM/TS (disable all layers)
    stz TM
    stz TS

    ; Clear color math
    stz CGWSEL
    stz CGADSUB

    ; Set fixed color to black
    lda #$E0
    sta COLDATA

    ; Clear SETINI
    stz SETINI

    ; --- Clear VRAM (64KB) via DMA ---
    ; First write a zero byte to use as DMA source
    ; We'll use a fixed source address (we write $00 to VMDATAL first)
    rep #$20
    .a16
    stz VMADDL              ; VRAM address = $0000

    sep #$20
    .a8

    ; Use DMA channel 0 to clear VRAM
    ; Transfer mode: fixed source, write to $2118/$2119 alternating (word)
    lda #$09                ; Transfer pattern: 2-register write, fixed source
    sta DMAP0
    lda #$18                ; Destination: VMDATAL ($2118)
    sta BBAD0

    ; Source address = address of a zero byte in ROM (we'll use part of this code)
    ; Point to the known zero we'll put at _zero_byte
    lda #<_zero_byte
    sta A1T0L
    lda #>_zero_byte
    sta A1T0H
    stz A1B0                ; Bank 0

    ; Transfer size: 64KB ($0000 wraps to $10000 for DMA)
    stz DAS0L
    stz DAS0H

    lda #$01                ; Enable DMA channel 0
    sta MDMAEN

    ; --- Clear CGRAM (512 bytes) ---
    stz CGADD               ; CGRAM address = 0

    ; Reuse DMA channel 0 for CGRAM
    lda #$08                ; Fixed source, single register
    sta DMAP0
    lda #$22                ; Destination: CGDATA ($2122)
    sta BBAD0

    lda #<_zero_byte
    sta A1T0L
    lda #>_zero_byte
    sta A1T0H
    stz A1B0

    ; 512 bytes
    rep #$20
    .a16
    lda #$0200
    sta DAS0L

    sep #$20
    .a8
    lda #$01
    sta MDMAEN

    ; --- Clear OAM (544 bytes) ---
    stz OAMADDL
    stz OAMADDH

    lda #$08                ; Fixed source, single register
    sta DMAP0
    lda #$04                ; Destination: OAMDATA ($2104)
    sta BBAD0

    lda #<_zero_byte
    sta A1T0L
    lda #>_zero_byte
    sta A1T0H
    stz A1B0

    rep #$20
    .a16
    lda #$0220              ; 544 bytes
    sta DAS0L

    sep #$20
    .a8
    lda #$01
    sta MDMAEN

    ; Read RDNMI to clear any pending NMI flag
    lda RDNMI

    rts

_zero_byte:
    .byte $00, $00
.endproc

; =============================================================================
; dma.asm — DMA Transfer Helpers
; =============================================================================
; Routines for transferring data to VRAM, CGRAM, and OAM via DMA channel 0.
; All routines expect 65816 native mode.
; =============================================================================

.include "registers.inc"

.segment "CODE"

.export dma_vram, dma_cgram, dma_oam

; dma_vram — Transfer data to VRAM
; Input:
;   A (16-bit) = VRAM destination word address
;   X (16-bit) = Source address (low 16 bits)
;   Y (16-bit) = Transfer size in bytes
;   DB register should be set so source bank is correct,
;   or call dma_vram_bank with bank in A (8-bit) after setting up.
;
; For simplicity, this uses bank 0. Use dma_vram_banked for other banks.
.proc dma_vram
    php
    rep #$30
    .a16
    .i16

    ; Set VRAM address
    sta VMADDL              ; Write A to VRAM address (16-bit write)

    sep #$20
    .a8

    ; VRAM increment mode: increment after high byte write
    lda #$80
    sta VMAIN

    ; DMA channel 0 setup
    lda #$01                ; Transfer mode: 2-register write (word), incrementing
    sta DMAP0
    lda #$18                ; Destination: VMDATAL ($2118)
    sta BBAD0

    ; Source address
    rep #$20
    .a16
    txa
    sta A1T0L               ; Source address low 16 bits
    sep #$20
    .a8
    stz A1B0                ; Source bank = 0

    ; Transfer size
    rep #$20
    .a16
    tya
    sta DAS0L

    sep #$20
    .a8

    ; Trigger DMA
    lda #$01
    sta MDMAEN

    plp
    rts
.endproc

; dma_cgram — Transfer palette data to CGRAM
; Input:
;   A (8-bit) = CGRAM start address (color index, 0-255)
;   X (16-bit) = Source address (bank 0)
;   Y (16-bit) = Transfer size in bytes
.proc dma_cgram
    php
    sep #$20
    .a8
    sta CGADD               ; Set CGRAM address

    ; DMA channel 0 setup
    lda #$00                ; Transfer mode: single register, incrementing
    sta DMAP0
    lda #$22                ; Destination: CGDATA ($2122)
    sta BBAD0

    ; Source address
    rep #$20
    .a16
    txa
    sta A1T0L
    sep #$20
    .a8
    stz A1B0                ; Bank 0

    ; Transfer size
    rep #$20
    .a16
    tya
    sta DAS0L

    sep #$20
    .a8

    ; Trigger DMA
    lda #$01
    sta MDMAEN

    plp
    rts
.endproc

; dma_oam — Transfer OAM data
; Input:
;   X (16-bit) = Source address (bank 0)
;   Y (16-bit) = Transfer size in bytes (usually $0220 = 544)
.proc dma_oam
    php
    sep #$20
    .a8

    ; Reset OAM address to 0
    stz OAMADDL
    stz OAMADDH

    ; DMA channel 0 setup
    lda #$00                ; Single register, incrementing
    sta DMAP0
    lda #$04                ; Destination: OAMDATA ($2104)
    sta BBAD0

    ; Source address
    rep #$20
    .a16
    txa
    sta A1T0L
    sep #$20
    .a8
    stz A1B0                ; Bank 0

    ; Transfer size
    rep #$20
    .a16
    tya
    sta DAS0L

    sep #$20
    .a8

    ; Trigger DMA
    lda #$01
    sta MDMAEN

    plp
    rts
.endproc

; =============================================================================
; hello/main.asm — Minimal SNES ROM: Solid Color Screen
; =============================================================================
; This is the simplest possible SNES ROM. It initializes the hardware,
; sets the background color, and loops forever.
; Great starting point for new games.
; =============================================================================

.include "registers.inc"
.include "header.inc"

; =============================================================================
; ROM Header and Vectors
; =============================================================================
ROM_HEADER "SNESSER HELLO", $20, $00, $08, $00, $01, $00
VECTOR_TABLE nmi_handler, reset_handler, irq_handler

; =============================================================================
; RESET Handler
; =============================================================================
.segment "CODE"

.import snes_init

.proc reset_handler
    jsr snes_init

    sep #$20
    .a8

    ; Set background color to a nice blue
    ; CGRAM address 0 = backdrop color
    stz CGADD               ; CGRAM address = 0

    ; SNES color: 0bbbbbgggggrrrrr (little-endian)
    ; Blue = $7C00 → low byte = $00, high byte = $7C
    lda #$00
    sta CGDATA
    lda #$50                ; Medium blue
    sta CGDATA

    ; Enable NMI
    lda #$80
    sta NMITIMEN

    ; Turn on screen (full brightness)
    lda #$0F
    sta INIDISP

    ; Main loop: just wait forever
@loop:
    wai
    bra @loop
.endproc

; =============================================================================
; NMI Handler — Acknowledge and return
; =============================================================================
.proc nmi_handler
    pha
    sep #$20
    .a8
    lda RDNMI               ; Acknowledge NMI
    pla
    rti
.endproc

; =============================================================================
; IRQ Handler — Not used
; =============================================================================
.proc irq_handler
    rti
.endproc

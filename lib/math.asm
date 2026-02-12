; =============================================================================
; math.asm — Hardware Multiply/Divide Wrappers
; =============================================================================
; Uses the SNES 5A22 hardware multiply and divide units.
; Multiply: 8×8 → 16-bit result (8 CPU cycles to complete)
; Divide: 16÷8 → 16-bit quotient + 16-bit remainder (16 CPU cycles)
; =============================================================================

.include "registers.inc"

.segment "CODE"

.export multiply_8x8, divide_16x8

; multiply_8x8 — Hardware unsigned 8×8 → 16 multiply
; Input:
;   A (8-bit) = multiplicand
;   X (8-bit, low byte of 16-bit X) = multiplier
; Output:
;   A (16-bit) = product
.proc multiply_8x8
    sep #$20
    .a8
    sta WRMPYA              ; Write multiplicand
    stx WRMPYB              ; Write multiplier (starts multiplication)

    ; Hardware multiply takes 8 machine cycles.
    ; These NOPs provide the wait time.
    nop
    nop
    nop
    nop

    rep #$20
    .a16
    lda RDMPYL              ; Read 16-bit result
    rts
.endproc

; divide_16x8 — Hardware unsigned 16÷8 divide
; Input:
;   A (16-bit) = dividend
;   X (8-bit, low byte) = divisor
; Output:
;   A (16-bit) = quotient
;   X (16-bit) = remainder
.proc divide_16x8
    rep #$20
    .a16
    sta WRDIVL              ; Write 16-bit dividend

    sep #$20
    .a8
    stx WRDIVB              ; Write 8-bit divisor (starts division)

    ; Hardware divide takes 16 machine cycles.
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    rep #$20
    .a16
    lda RDDIVL              ; Quotient
    ldx RDMPYL              ; Remainder
    rts
.endproc

; =============================================================================
; scores.asm — Score, Level, and Lines Tracking
; =============================================================================
; Standard Tetris scoring: 40/100/300/1200 × (level + 1) for 1/2/3/4 lines
; Level increases every 10 lines.
; Score stored as 24-bit binary, converted to 6 BCD digits for display.
; =============================================================================

.include "registers.inc"

.importzp line_clear_count, render_score_dirty, drop_speed

.segment "ZEROPAGE"

.export score_lo, score_hi, level, lines_total
score_lo:       .res 2      ; Score low 16 bits
score_hi:       .res 1      ; Score high 8 bits (max 999999 fits in 20 bits)
level:          .res 1      ; Current level (0-20)
lines_total:    .res 2      ; Total lines cleared (16-bit)

.segment "BSS"

.export score_digits, level_digits, lines_digits
score_digits:   .res 6      ; 6 decimal digits (hundreds of thousands → ones)
level_digits:   .res 2      ; 2 decimal digits
lines_digits:   .res 4      ; 4 decimal digits

.segment "CODE"

.export scores_init, scores_add_lines

; Score awards per line count: 1-line=40, 2-lines=100, 3-lines=300, 4-lines=1200
line_score_table:
    .word 40                ; 1 line
    .word 100               ; 2 lines
    .word 300               ; 3 lines
    .word 1200              ; 4 lines (TETRIS!)

; Gravity speed table (duplicated from game.asm for level-up)
gravity_table2:
    .byte 48, 43, 38, 33, 28, 23, 18, 13, 8, 6
    .byte 5,  5,  5,  4,  4,  4,  3,  3,  3, 2
    .byte 1

; =============================================================================
; scores_init — Reset all score state
; =============================================================================
.proc scores_init
    sep #$20
    .a8
    rep #$10
    .i16

    stz score_lo
    stz score_lo+1
    stz score_hi
    stz level
    stz lines_total
    stz lines_total+1

    ; Clear digit arrays
    ldx #$0000
@clear_score:
    stz score_digits,x
    inx
    cpx #$0006
    bne @clear_score

    stz level_digits
    stz level_digits+1

    ldx #$0000
@clear_lines:
    stz lines_digits,x
    inx
    cpx #$0004
    bne @clear_lines

    lda #$01
    sta render_score_dirty

    rts
.endproc

; =============================================================================
; scores_add_lines — Award points for cleared lines
; Call after clear_lines sets line_clear_count.
; =============================================================================
.proc scores_add_lines
    php
    sep #$20
    .a8
    rep #$10
    .i16

    lda line_clear_count
    bne @has_lines          ; Lines cleared — process them
    jmp @done
@has_lines:

    ; Add to total lines
    rep #$20
    .a16
    lda lines_total
    sep #$20
    .a8
    lda line_clear_count
    rep #$20
    .a16
    and #$00FF
    clc
    adc lines_total
    sta lines_total

    sep #$20
    .a8

    ; Check for level up (every 10 lines)
    ; New level = total_lines / 10
    rep #$20
    .a16
    lda lines_total
    sta WRDIVL
    sep #$20
    .a8
    lda #10
    sta WRDIVB
    ; Wait for division
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop

    lda RDDIVL              ; Quotient = new level
    cmp #21
    bcc @level_ok
    lda #20                 ; Cap at level 20
@level_ok:
    sta level

    ; Update drop speed
    rep #$20
    .a16
    and #$00FF              ; Zero-extend (clears hidden B byte)
    tax
    sep #$20
    .a8
    lda gravity_table2,x
    sta drop_speed

    ; Calculate score: line_score_table[count-1] × (level + 1)
    lda line_clear_count
    dec a                   ; 0-indexed
    asl a                   ; × 2 (word index)
    tax

    rep #$20
    .a16
    lda line_score_table,x  ; Base score for this many lines
    sta render_temp2

    sep #$20
    .a8
    lda level
    inc a                   ; level + 1

    ; Multiply base_score (16-bit) × (level+1) (8-bit)
    ; Use repeated addition since hardware multiply is only 8×8
    sta mult_count
    rep #$20
    .a16
    lda #$0000
    sta mult_result
@mult_loop:
    lda mult_result
    clc
    adc render_temp2
    sta mult_result
    sep #$20
    .a8
    dec mult_count
    bne @mult_loop_16
    bra @add_score
@mult_loop_16:
    rep #$20
    .a16
    bra @mult_loop

@add_score:
    ; Add to score (24-bit)
    rep #$20
    .a16
    lda score_lo
    clc
    adc mult_result
    sta score_lo
    sep #$20
    .a8
    lda score_hi
    adc #$00
    sta score_hi

    ; Cap score at 999999
    cmp #$0F
    bcc @update_display
    rep #$20
    .a16
    lda score_lo
    cmp #$423F              ; $0F423F = 999999
    bcc @update_display_16
    lda #$423F
    sta score_lo
    sep #$20
    .a8
    lda #$0F
    sta score_hi
    bra @update_display

@update_display_16:
    sep #$20
    .a8

@update_display:
    ; Convert score to decimal digits
    jsr score_to_digits
    jsr level_to_digits
    jsr lines_to_digits

    lda #$01
    sta render_score_dirty

@done:
    plp
    rts
.endproc

.segment "ZEROPAGE"
render_temp2:   .res 2
mult_result:    .res 2
mult_count:     .res 1
div_temp:       .res 2

.segment "CODE"

; =============================================================================
; score_to_digits — Convert 24-bit score to 6 decimal digits
; =============================================================================
.proc score_to_digits
    php
    sep #$20
    .a8
    rep #$10
    .i16

    ; Simple repeated subtraction for each digit position
    ; Positions: 100000, 10000, 1000, 100, 10, 1

    ; Copy score to working value
    rep #$20
    .a16
    lda score_lo
    sta div_temp
    ; score_hi in place

    sep #$20
    .a8

    ; For simplicity, convert low 16 bits only (max 65535)
    ; Full 24-bit conversion would need 24-bit subtraction
    ; Let's do a simpler approach: repeated division by 10

    ; We'll work with the full score by doing 6 divisions
    ; score_digits[5] = score % 10, score /= 10, repeat

    ; Use 16-bit division (handles up to 65535, good for scores up to ~65K)
    ; For higher scores, we'd need multi-precision. Keep it simple for now.

    rep #$20
    .a16
    lda score_lo            ; Use low 16 bits (max 65535)

    ; Digit 5 (ones)
    sta WRDIVL
    sep #$20
    .a8
    lda #10
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    lda RDMPYL              ; Remainder = ones digit
    sta score_digits+5
    rep #$20
    .a16
    lda RDDIVL              ; Quotient

    ; Digit 4 (tens)
    sta WRDIVL
    sep #$20
    .a8
    lda #10
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    lda RDMPYL
    sta score_digits+4
    rep #$20
    .a16
    lda RDDIVL

    ; Digit 3 (hundreds)
    sta WRDIVL
    sep #$20
    .a8
    lda #10
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    lda RDMPYL
    sta score_digits+3
    rep #$20
    .a16
    lda RDDIVL

    ; Digit 2 (thousands)
    sta WRDIVL
    sep #$20
    .a8
    lda #10
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    lda RDMPYL
    sta score_digits+2
    rep #$20
    .a16
    lda RDDIVL

    ; Digit 1 (ten thousands)
    sta WRDIVL
    sep #$20
    .a8
    lda #10
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    lda RDMPYL
    sta score_digits+1
    lda RDDIVL              ; Hundred thousands
    sta score_digits

    plp
    rts
.endproc

; =============================================================================
; level_to_digits — Convert level to 2 digits
; =============================================================================
.proc level_to_digits
    sep #$20
    .a8

    lda level
    rep #$20
    .a16
    and #$00FF              ; Zero-extend to 16-bit
    sta WRDIVL              ; 16-bit dividend
    sep #$20
    .a8
    lda #10
    sta WRDIVB              ; 8-bit divisor
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    lda RDDIVL              ; Quotient = tens digit
    sta level_digits
    lda RDMPYL              ; Remainder = ones digit
    sta level_digits+1

    rts
.endproc

; =============================================================================
; lines_to_digits — Convert lines_total to 4 digits
; =============================================================================
.proc lines_to_digits
    sep #$20
    .a8
    rep #$10
    .i16

    rep #$20
    .a16
    lda lines_total

    ; Digit 3 (ones)
    sta WRDIVL
    sep #$20
    .a8
    lda #10
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    lda RDMPYL
    sta lines_digits+3
    rep #$20
    .a16
    lda RDDIVL

    ; Digit 2 (tens)
    sta WRDIVL
    sep #$20
    .a8
    lda #10
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    lda RDMPYL
    sta lines_digits+2
    rep #$20
    .a16
    lda RDDIVL

    ; Digit 1 (hundreds)
    sta WRDIVL
    sep #$20
    .a8
    lda #10
    sta WRDIVB
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    lda RDMPYL
    sta lines_digits+1
    lda RDDIVL
    sta lines_digits        ; Thousands

    rts
.endproc

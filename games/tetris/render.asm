; =============================================================================
; render.asm — Tetris Board and UI Rendering
; =============================================================================

.include "registers.inc"
.include "playfield.inc"
.include "tiles.inc"
.include "palette.inc"
.include "font.inc"

.import board, piece_rotations, piece_colors
.importzp current_piece, current_rotation, current_x, current_y
.importzp next_piece
.import score_digits, level_digits, lines_digits

.segment "ZEROPAGE"

.exportzp render_board_dirty, render_score_dirty
render_board_dirty: .res 1
render_score_dirty: .res 1
render_temp:        .res 2
render_temp2:       .res 2
piece_bitmask:      .res 2

.segment "CODE"

.export render_init, render_frame, render_playfield_border

; Write a single tilemap entry (tile index, palette 0)
.macro WRITE_TILE tilenum
    lda #tilenum
    sta VMDATAL
    stz VMDATAH
.endmacro

; =============================================================================
; render_init — Upload tile and palette data to VRAM/CGRAM
; =============================================================================
.proc render_init
    php
    sep #$20
    .a8
    rep #$10
    .i16

    lda #$80
    sta VMAIN

    ; Upload tile data to VRAM $0000
    rep #$20
    .a16
    lda #$0000
    sta VMADDL
    sep #$20
    .a8
    lda #$01
    sta DMAP0
    lda #$18
    sta BBAD0
    rep #$20
    .a16
    lda #tile_data
    sta A1T0L
    sep #$20
    .a8
    stz A1B0
    rep #$20
    .a16
    lda #(tile_data_end - tile_data)
    sta DAS0L
    sep #$20
    .a8
    lda #$01
    sta MDMAEN

    ; Upload font data to VRAM $0100 (tile index 16 * 16 bytes/tile = 256 words)
    rep #$20
    .a16
    lda #$0100
    sta VMADDL
    sep #$20
    .a8
    lda #$01
    sta DMAP0
    lda #$18
    sta BBAD0
    rep #$20
    .a16
    lda #font_data
    sta A1T0L
    sep #$20
    .a8
    stz A1B0
    rep #$20
    .a16
    lda #(font_data_end - font_data)
    sta DAS0L
    sep #$20
    .a8
    lda #$01
    sta MDMAEN

    ; Upload palette to CGRAM
    stz CGADD
    lda #$00
    sta DMAP0
    lda #$22
    sta BBAD0
    rep #$20
    .a16
    lda #palette_data
    sta A1T0L
    sep #$20
    .a8
    stz A1B0
    rep #$20
    .a16
    lda #(palette_data_end - palette_data)
    sta DAS0L
    sep #$20
    .a8
    lda #$01
    sta MDMAEN

    plp
    rts
.endproc

; =============================================================================
; calc_tilemap_addr — Calculate VRAM tilemap address
; Input: A (8-bit) = screen Y, render_temp low byte = screen X
; Output: VMADDL set
; =============================================================================
.proc calc_tilemap_addr
    ; A = screen_y
    rep #$20
    .a16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a                   ; y * 32
    sta render_temp2

    sep #$20
    .a8
    lda render_temp         ; screen_x
    rep #$20
    .a16
    and #$00FF
    clc
    adc render_temp2
    adc #$0400              ; tilemap base
    sta VMADDL

    sep #$20
    .a8
    rts
.endproc

; =============================================================================
; render_playfield_border — Draw static border
; =============================================================================
.proc render_playfield_border
    php
    sep #$20
    .a8
    rep #$10
    .i16

    lda #$80
    sta VMAIN

    ldx #$0000
@loop:
    lda playfield_border,x
    cmp #$FF
    bne @not_done
    jmp @done
@not_done:
    sta render_temp         ; X coord
    lda playfield_border+1,x  ; Y coord
    jsr calc_tilemap_addr

    lda playfield_border+2,x  ; Tile ID
    sta VMDATAL
    stz VMDATAH

    inx
    inx
    inx
    jmp @loop

@done:
    plp
    rts
.endproc

; =============================================================================
; render_frame — Called during VBlank
; =============================================================================
.proc render_frame
    php
    sep #$20
    .a8

    ; Check if anything needs rendering
    lda render_board_dirty
    ora render_score_dirty
    beq @done

    ; Force blank — VRAM only writable during VBlank or force blank.
    ; LoROM SlowROM VBlank (~6300 cycles) is too short for full board +
    ; piece + score rendering (~8000 cycles).  Force blank guarantees
    ; all writes succeed at the cost of a brief screen blank.
    lda #$80
    sta INIDISP

    lda render_board_dirty
    beq @check_score
    jsr render_board
    stz render_board_dirty

@check_score:
    lda render_score_dirty
    beq @restore
    jsr render_score
    stz render_score_dirty

@restore:
    ; Restore full brightness
    lda #$0F
    sta INIDISP

@done:
    plp
    rts
.endproc

; =============================================================================
; render_board — Write board + active piece to tilemap
; =============================================================================
.segment "ZEROPAGE"
temp_render_row: .res 1
temp_render_col: .res 1
temp_piece_row:  .res 1
temp_piece_col:  .res 1

.segment "CODE"

.proc render_board
    php
    sep #$20
    .a8
    rep #$10
    .i16

    lda #$80
    sta VMAIN               ; Auto-increment after VMDATAH write

    ldy #$0000              ; Board index (0-199)
    stz temp_render_row

@row_loop:
    ; Set VRAM address once per row (auto-increment handles columns)
    ; VRAM addr = $0400 + (FIELD_Y + row) * 32 + FIELD_X
    lda temp_render_row
    rep #$20
    .a16
    and #$00FF
    asl a
    asl a
    asl a
    asl a
    asl a                   ; row * 32
    clc
    adc #($0400 + FIELD_Y * 32 + FIELD_X)
    sta VMADDL
    sep #$20
    .a8

    ldx #10                 ; 10 columns per row

@col_loop:
    ; Get board cell
    lda board,y
    beq @empty

    ; Filled: tile 1, palette = color
    pha
    lda #$01
    sta VMDATAL
    pla
    asl a
    asl a
    sta VMDATAH             ; VRAM addr auto-increments
    bra @next

@empty:
    stz VMDATAL
    stz VMDATAH             ; VRAM addr auto-increments

@next:
    iny
    dex
    bne @col_loop

    inc temp_render_row
    lda temp_render_row
    cmp #20
    bcc @row_loop

    jsr render_active_piece

    plp
    rts
.endproc

; =============================================================================
; render_active_piece — Overlay current piece on tilemap
; =============================================================================
.proc render_active_piece
    sep #$20
    .a8
    rep #$10
    .i16

    ; Load piece bitmask
    lda current_piece
    asl a
    asl a
    asl a
    clc
    adc current_rotation
    adc current_rotation
    rep #$20
    .a16
    and #$003F              ; Zero-extend (clears hidden B byte)
    tax
    lda piece_rotations,x
    sta piece_bitmask
    sep #$20
    .a8

    ; Get palette
    lda current_piece
    rep #$20
    .a16
    and #$00FF              ; Zero-extend (clears hidden B byte)
    tax
    sep #$20
    .a8
    lda piece_colors,x
    pha                     ; Palette on stack

    stz temp_piece_row

@row_loop:
    stz temp_piece_col

@col_loop:
    ; Test bit: index = piece_row * 4 + piece_col, bit = 15 - index
    lda temp_piece_row
    asl a
    asl a
    clc
    adc temp_piece_col
    eor #$0F
    rep #$20
    .a16
    and #$000F              ; Zero-extend (clears hidden B byte)
    tax
    lda piece_bitmask
@shr:
    cpx #$0000
    beq @shr_done
    lsr a
    dex
    bra @shr
@shr_done:
    sep #$20
    .a8
    and #$01
    bne @cell_set
    jmp @next_col
@cell_set:

    ; Check bounds
    lda temp_piece_row
    clc
    adc current_y
    bpl @row_pos
    jmp @next_col
@row_pos:
    cmp #20
    bcc @row_ok
    jmp @next_col
@row_ok:

    clc
    adc #FIELD_Y
    sta temp_render_row     ; screen_y

    lda temp_piece_col
    clc
    adc current_x
    bpl @col_pos
    jmp @next_col
@col_pos:
    cmp #10
    bcc @col_ok
    jmp @next_col
@col_ok:

    clc
    adc #FIELD_X
    sta render_temp         ; screen_x

    lda temp_render_row
    jsr calc_tilemap_addr

    lda #$01
    sta VMDATAL
    pla
    pha
    asl a
    asl a
    sta VMDATAH

@next_col:
    inc temp_piece_col
    lda temp_piece_col
    cmp #$04
    bcc @col_loop

    inc temp_piece_row
    lda temp_piece_row
    cmp #$04
    bcc @row_loop

    pla                     ; Clean palette
    rts
.endproc

; =============================================================================
; render_score — Display SCORE, LEVEL, LINES, NEXT text + values
; =============================================================================
.proc render_score
    php
    sep #$20
    .a8
    rep #$10
    .i16

    lda #$80
    sta VMAIN

    ; "SCORE" at (SCORE_X, SCORE_Y)
    rep #$20
    .a16
    lda #(SCORE_Y * 32 + SCORE_X + $0400)
    sta VMADDL
    sep #$20
    .a8
    WRITE_TILE 44                           ; S
    WRITE_TILE 28                           ; C
    WRITE_TILE 40                           ; O
    WRITE_TILE 43                           ; R
    WRITE_TILE 30                           ; E

    ; Score digits
    rep #$20
    .a16
    lda #((SCORE_Y + 1) * 32 + SCORE_X + $0400)
    sta VMADDL
    sep #$20
    .a8
    ldx #$0000
@score_loop:
    lda score_digits,x
    clc
    adc #16
    sta VMDATAL
    stz VMDATAH
    inx
    cpx #$0006
    bne @score_loop

    ; "LEVEL"
    rep #$20
    .a16
    lda #(LEVEL_Y * 32 + LEVEL_X + $0400)
    sta VMADDL
    sep #$20
    .a8
    WRITE_TILE 37                           ; L
    WRITE_TILE 30                           ; E
    WRITE_TILE 47                           ; V
    WRITE_TILE 30                           ; E
    WRITE_TILE 37                           ; L

    ; Level digits
    rep #$20
    .a16
    lda #((LEVEL_Y + 1) * 32 + LEVEL_X + $0400)
    sta VMADDL
    sep #$20
    .a8
    ldx #$0000
@level_loop:
    lda level_digits,x
    clc
    adc #16
    sta VMDATAL
    stz VMDATAH
    inx
    cpx #$0002
    bne @level_loop

    ; "LINES"
    rep #$20
    .a16
    lda #(LINES_Y * 32 + LINES_X + $0400)
    sta VMADDL
    sep #$20
    .a8
    WRITE_TILE 37                           ; L
    WRITE_TILE 34                           ; I
    WRITE_TILE 39                           ; N
    WRITE_TILE 30                           ; E
    WRITE_TILE 44                           ; S

    ; Lines digits
    rep #$20
    .a16
    lda #((LINES_Y + 1) * 32 + LINES_X + $0400)
    sta VMADDL
    sep #$20
    .a8
    ldx #$0000
@lines_loop:
    lda lines_digits,x
    clc
    adc #16
    sta VMDATAL
    stz VMDATAH
    inx
    cpx #$0004
    bne @lines_loop

    ; "NEXT"
    rep #$20
    .a16
    lda #(NEXT_Y * 32 + NEXT_X + $0400)
    sta VMADDL
    sep #$20
    .a8
    WRITE_TILE 39                           ; N
    WRITE_TILE 30                           ; E
    WRITE_TILE 49                           ; X
    WRITE_TILE 45                           ; T

    plp
    rts
.endproc

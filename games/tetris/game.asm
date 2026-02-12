; =============================================================================
; game.asm — Core Tetris Game Logic
; =============================================================================
; Board state, piece movement, collision detection, line clearing, gravity.
; Board is 10 wide × 20 tall stored in WRAM.
; =============================================================================

.include "registers.inc"

.import piece_rotations, piece_colors, PIECE_COUNT
.importzp render_board_dirty, render_score_dirty

.segment "ZEROPAGE"

.exportzp current_piece, current_rotation, current_x, current_y
.exportzp next_piece, game_state, game_over_flag
.exportzp drop_timer, drop_speed, line_clear_count

current_piece:      .res 1  ; Current piece ID (0-6)
current_rotation:   .res 1  ; Current rotation (0-3)
current_x:          .res 1  ; Piece X position on board (signed, column)
current_y:          .res 1  ; Piece Y position on board (signed, row)
next_piece:         .res 1  ; Next piece ID
game_state:         .res 1  ; 0=title, 1=playing, 2=game_over
game_over_flag:     .res 1  ; Set when game ends
drop_timer:         .res 1  ; Frames until next auto-drop
drop_speed:         .res 1  ; Current drop speed (frames per row)
rng_state:          .res 2  ; 16-bit LFSR for random numbers
line_clear_count:   .res 1  ; Lines cleared this move (0-4)
piece_temp2:        .res 2  ; Temp storage for piece bitmask
temp_row:           .res 1
temp_col:           .res 1
temp_mult:          .res 1
temp_board_idx:     .res 1

.segment "BSS"

.export board
board:              .res 200 ; 10 × 20 = 200 bytes (0 = empty, 1-7 = piece color)

.segment "CODE"

.export game_init, game_update, spawn_piece, move_left, move_right
.export move_down, rotate_cw, hard_drop, check_collision
.export clear_lines, lock_piece

; Gravity speed table: frames per drop at each level (0-20)
gravity_table:
    .byte 48, 43, 38, 33, 28, 23, 18, 13, 8, 6
    .byte 5,  5,  5,  4,  4,  4,  3,  3,  3, 2
    .byte 1

; =============================================================================
; game_init — Initialize game state
; =============================================================================
.proc game_init
    sep #$20
    .a8
    rep #$10
    .i16

    ; Clear board
    lda #$00
    ldx #$0000
@clear_board:
    sta board,x
    inx
    cpx #200
    bne @clear_board

    ; Initialize RNG with a seed
    rep #$20
    .a16
    lda #$A395
    sta rng_state
    sep #$20
    .a8

    ; Reset game state
    lda #$01
    sta game_state

    stz game_over_flag
    stz current_rotation
    stz line_clear_count

    ; Set initial drop speed (level 0)
    lda gravity_table
    sta drop_speed
    sta drop_timer

    ; Spawn first piece
    jsr random_piece
    sta next_piece
    jsr spawn_piece

    lda #$01
    sta render_board_dirty

    rts
.endproc

; =============================================================================
; game_update — Main game tick (call once per frame while playing)
; =============================================================================
.proc game_update
    sep #$20
    .a8

    lda game_state
    cmp #$01
    bne @done

    dec drop_timer
    bne @done
    lda drop_speed
    sta drop_timer

    jsr move_down
    bcs @done
    ; Couldn't move down — lock the piece
    jsr lock_piece
    jsr clear_lines
    jsr spawn_piece

@done:
    rts
.endproc

; =============================================================================
; spawn_piece — Spawn the next piece at the top
; =============================================================================
.proc spawn_piece
    sep #$20
    .a8

    lda next_piece
    sta current_piece

    jsr random_piece
    sta next_piece

    lda #3
    sta current_x
    stz current_y
    stz current_rotation

    lda drop_speed
    sta drop_timer

    jsr check_collision
    bcc @ok
    lda #$02
    sta game_state
    lda #$01
    sta game_over_flag
@ok:
    lda #$01
    sta render_board_dirty
    sta render_score_dirty
    rts
.endproc

; =============================================================================
; random_piece — Generate a random piece ID (0-6)
; =============================================================================
.proc random_piece
    rep #$20
    .a16
    lda rng_state
    lsr a
    bcc @no_tap
    eor #$B400
@no_tap:
    sta rng_state
    sep #$20
    .a8
    lda rng_state
    and #$07
    cmp #$07
    bcc @done
    sbc #$07
@done:
    rts
.endproc

; =============================================================================
; move_left — Move piece left if possible
; =============================================================================
.proc move_left
    sep #$20
    .a8
    dec current_x
    jsr check_collision
    bcc @ok
    inc current_x
    clc
    rts
@ok:
    lda #$01
    sta render_board_dirty
    sec
    rts
.endproc

; =============================================================================
; move_right — Move piece right if possible
; =============================================================================
.proc move_right
    sep #$20
    .a8
    inc current_x
    jsr check_collision
    bcc @ok
    dec current_x
    clc
    rts
@ok:
    lda #$01
    sta render_board_dirty
    sec
    rts
.endproc

; =============================================================================
; move_down — Move piece down if possible
; Output: Carry set if moved, clear if blocked
; =============================================================================
.proc move_down
    sep #$20
    .a8
    inc current_y
    jsr check_collision
    bcc @ok
    dec current_y
    clc
    rts
@ok:
    lda #$01
    sta render_board_dirty
    sec
    rts
.endproc

; =============================================================================
; rotate_cw — Rotate piece clockwise with basic wall-kick
; =============================================================================
.proc rotate_cw
    sep #$20
    .a8

    lda current_rotation
    pha

    inc current_rotation
    lda current_rotation
    and #$03
    sta current_rotation

    jsr check_collision
    bcc @ok

    dec current_x
    jsr check_collision
    bcc @ok

    inc current_x
    inc current_x
    jsr check_collision
    bcc @ok

    dec current_x
    pla
    sta current_rotation
    clc
    rts

@ok:
    pla
    lda #$01
    sta render_board_dirty
    sec
    rts
.endproc

; =============================================================================
; hard_drop — Instantly drop piece to bottom
; =============================================================================
.proc hard_drop
    sep #$20
    .a8
@loop:
    inc current_y
    jsr check_collision
    bcc @loop
    dec current_y

    jsr lock_piece
    jsr clear_lines
    jsr spawn_piece
    rts
.endproc

; =============================================================================
; load_piece_bitmask — Load current piece rotation bitmask into piece_temp2
; Also sets up 16-bit index mode.
; =============================================================================
.proc load_piece_bitmask
    sep #$20
    .a8
    rep #$10
    .i16

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
    sta piece_temp2
    sep #$20
    .a8
    rts
.endproc

; =============================================================================
; test_piece_bit — Test if piece cell at (temp_row, temp_col) is set
; Input: piece_temp2 has bitmask, temp_row/temp_col set
; Output: Z flag clear if cell occupied, Z flag set if empty
; =============================================================================
.proc test_piece_bit
    lda temp_row
    asl a
    asl a
    clc
    adc temp_col
    eor #$0F
    rep #$20
    .a16
    and #$000F              ; Zero-extend (clears hidden B byte)
    tax
    lda piece_temp2
@shr:
    cpx #$0000
    beq @done
    lsr a
    dex
    bra @shr
@done:
    sep #$20
    .a8
    and #$01
    rts
.endproc

; =============================================================================
; check_collision — Test if current piece position overlaps board or walls
; Output: Carry set if collision, clear if position is valid
; =============================================================================
.proc check_collision
    php
    jsr load_piece_bitmask

    lda #$00
    sta temp_row

@row_loop:
    lda #$00
    sta temp_col

@col_loop:
    jsr test_piece_bit
    beq @next_col

    ; Cell occupied — check board position
    lda temp_row
    clc
    adc current_y
    bmi @collides
    cmp #20
    bcs @collides
    sta temp_board_idx

    lda temp_col
    clc
    adc current_x
    bmi @collides
    cmp #10
    bcs @collides

    ; board index = board_row * 10 + board_col
    pha
    lda temp_board_idx
    asl a
    sta temp_mult
    asl a
    asl a
    clc
    adc temp_mult
    sta temp_board_idx
    pla
    clc
    adc temp_board_idx

    rep #$30                ; 16-bit A + index
    .a16
    .i16
    and #$00FF              ; Zero-extend (clears hidden B byte)
    tax
    sep #$20
    .a8
    lda board,x
    bne @collides

@next_col:
    inc temp_col
    lda temp_col
    cmp #$04
    bcc @col_loop

    inc temp_row
    lda temp_row
    cmp #$04
    bcc @row_loop

    plp
    clc
    rts

@collides:
    plp
    sec
    rts
.endproc

; =============================================================================
; lock_piece — Write current piece into the board array
; =============================================================================
.proc lock_piece
    php
    jsr load_piece_bitmask

    ; Get piece color
    lda current_piece
    rep #$20
    .a16
    and #$00FF              ; Zero-extend (clears hidden B byte)
    tax
    sep #$20
    .a8
    lda piece_colors,x
    pha                     ; Save color on stack

    lda #$00
    sta temp_row

@row_loop:
    lda #$00
    sta temp_col

@col_loop:
    jsr test_piece_bit
    beq @next_col

    ; Write to board
    lda temp_row
    clc
    adc current_y
    asl a
    sta temp_mult
    asl a
    asl a
    clc
    adc temp_mult

    clc
    adc temp_col
    clc
    adc current_x

    rep #$30                ; 16-bit A + index
    .a16
    .i16
    and #$00FF              ; Zero-extend (clears hidden B byte)
    tax
    sep #$20
    .a8
    pla
    pha                     ; Keep color on stack
    sta board,x

@next_col:
    inc temp_col
    lda temp_col
    cmp #$04
    bcc @col_loop

    inc temp_row
    lda temp_row
    cmp #$04
    bcc @row_loop

    pla                     ; Clean up stack

    lda #$01
    sta render_board_dirty

    plp
    rts
.endproc

; =============================================================================
; clear_lines — Scan board for complete rows, remove them
; =============================================================================
.proc clear_lines
    php
    sep #$20
    .a8
    rep #$10
    .i16

    stz line_clear_count

    lda #19
    sta temp_row

@check_row:
    ; Calculate row start index = row * 10
    lda temp_row
    asl a
    sta temp_mult
    asl a
    asl a
    clc
    adc temp_mult
    rep #$20
    .a16
    and #$00FF              ; Zero-extend (clears hidden B byte)
    tax
    sep #$20
    .a8

    ldy #10                 ; Check 10 columns
@check_col:
    lda board,x
    beq @row_not_full
    inx
    dey
    bne @check_col

    ; Row is full
    inc line_clear_count

    ; Shift rows above down (use a loop, not .repeat)
    lda temp_row
    sta temp_board_idx

@shift_down:
    lda temp_board_idx
    beq @clear_top_row

    ; dest = temp_board_idx * 10
    lda temp_board_idx
    asl a
    sta temp_mult
    asl a
    asl a
    clc
    adc temp_mult
    rep #$20
    .a16
    and #$00FF              ; Zero-extend (clears hidden B byte)
    tax
    sep #$20
    .a8

    ; source = (temp_board_idx - 1) * 10
    lda temp_board_idx
    dec a
    asl a
    sta temp_mult
    asl a
    asl a
    clc
    adc temp_mult
    rep #$20
    .a16
    and #$00FF              ; Zero-extend (clears hidden B byte)
    tay
    sep #$20
    .a8

    ; Copy 10 bytes (loop instead of .repeat to save space)
    lda #10
    sta temp_col            ; Reuse as counter
@copy_loop:
    lda board,y
    sta board,x
    inx
    iny
    dec temp_col
    bne @copy_loop

    dec temp_board_idx
    jmp @shift_down

@clear_top_row:
    ; Zero out row 0
    ldx #$0000
    lda #$00
    ldy #10
@zero_loop:
    sta board,x
    inx
    dey
    bne @zero_loop

    ; Re-check same row (it shifted down)
    jmp @check_row

@row_not_full:
    dec temp_row
    bmi @done
    jmp @check_row

@done:
    plp
    rts
.endproc

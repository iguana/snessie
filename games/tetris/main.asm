; =============================================================================
; main.asm — SNESSER Tetris: Entry Point, NMI Handler, Main Loop
; =============================================================================

.include "registers.inc"
.include "header.inc"

; --- Imports ---
.import snes_init
.import input_init, input_read
.importzp joy1_current, joy1_pressed
.import ppu_set_mode, ppu_set_bg1, ppu_enable_layers, ppu_set_brightness
.import spc_init, spc_play_sfx, spc_silence
.import game_init, game_update, spawn_piece
.import move_left, move_right, move_down, rotate_cw, hard_drop
.import scores_init, scores_add_lines
.import render_init, render_frame, render_playfield_border
.import render_board_dirty, render_score_dirty
.importzp game_state, game_over_flag, line_clear_count
.import board

; --- Zero page ---
.segment "ZEROPAGE"
nmi_ready:      .res 1      ; Flag: main loop signals VBlank work ready
frame_counter:  .res 2      ; Frame counter for timing/RNG
das_timer:      .res 1      ; Delayed auto-shift timer
das_direction:  .res 1      ; 0=none, 1=left, 2=right

; DAS (Delayed Auto-Shift) constants
DAS_DELAY = 16              ; Frames before auto-repeat starts
DAS_REPEAT = 6              ; Frames between auto-repeat moves

; =============================================================================
; ROM Header and Vectors
; =============================================================================
ROM_HEADER "SNESSER TETRIS", $20, $00, $08, $00, $01, $00
VECTOR_TABLE nmi_handler, reset_handler, irq_handler

; =============================================================================
; RESET Handler — Entry point
; =============================================================================
.segment "CODE"

.proc reset_handler
    ; --- CPU initialization (must happen before any subroutine calls) ---
    sei                     ; Disable interrupts
    clc
    xce                     ; Switch to native 65816 mode

    rep #$38                ; 16-bit A/X/Y, clear decimal
    .a16
    .i16

    ldx #$1FFF
    txs                     ; Set stack pointer to $1FFF

    ; Clear WRAM ($0000-$1FFF) before any subroutine calls
    lda #$0000
    ldx #$0000
@clear_wram:
    sta $0000,x
    inx
    inx
    cpx #$2000
    bne @clear_wram

    sep #$20
    .a8

    ; Initialize SNES hardware (PPU registers, VRAM, CGRAM, OAM)
    jsr snes_init

    ; Initialize subsystems
    jsr input_init
    jsr render_init

    ; Set up PPU: Mode 1, BG1 for playfield
    sep #$20
    .a8

    ; BG Mode 1 (BG1 = 4bpp, BG2 = 4bpp, BG3 = 2bpp)
    lda #$01
    jsr ppu_set_mode

    ; BG1: tilemap at VRAM $0400 (word addr), 32×32 tiles
    ; BG1SC = (tilemap_addr / $0400) << 2 | size = (1 << 2) | 0 = $04
    lda #$04
    ldx #$00                ; BG1 chr data at VRAM $0000
    jsr ppu_set_bg1

    ; Enable BG1 on main screen
    lda #$01
    jsr ppu_enable_layers

    ; Draw static playfield border
    jsr render_playfield_border

    ; Initialize game
    jsr scores_init
    jsr game_init

    ; Enable NMI
    sep #$20
    .a8
    lda #$81                ; NMI enable + auto-joypad
    sta NMITIMEN

    ; Turn on screen (full brightness)
    lda #$0F
    jsr ppu_set_brightness

    ; TODO: SPC700 upload protocol needs debugging — skip for now
    ; Sound effects are no-ops when spc_ready=0 (default after WRAM clear)
    ; jsr spc_init

    cli                     ; Enable IRQ (NMI already enabled via NMITIMEN)

    ; --- Main loop ---
main_loop:
    ; Wait for VBlank (NMI handler will set nmi_ready to 0)
    lda #$01
    sta nmi_ready
@wait_nmi:
    wai                     ; Wait for interrupt
    lda nmi_ready
    bne @wait_nmi

    ; Read input
    jsr input_read

    ; Increment frame counter
    rep #$20
    .a16
    inc frame_counter
    sep #$20
    .a8

    ; Check game state
    lda game_state
    cmp #$01
    beq @playing
    cmp #$02
    beq @game_over
    bra main_loop           ; Unknown state, loop

@playing:
    ; Process input
    jsr process_input

    ; Update game logic (gravity, etc.)
    jsr game_update

    ; Check if lines were cleared → add score
    lda line_clear_count
    beq @no_lines
    jsr scores_add_lines

    ; Play line clear sound
    lda line_clear_count
    cmp #$04
    bcc @normal_clear
    lda #$03                ; Tetris sound
    bra @play_sound
@normal_clear:
    lda #$02                ; Normal line clear sound
@play_sound:
    jsr spc_play_sfx
    stz line_clear_count

@no_lines:
    bra main_loop

@game_over:
    ; Game over state: wait for START to restart
    rep #$20
    .a16
    lda joy1_pressed
    and #JOY_START
    beq @game_over_wait
    sep #$20
    .a8
    jsr scores_init
    jsr game_init
    bra main_loop

@game_over_wait:
    sep #$20
    .a8
    bra main_loop
.endproc

; =============================================================================
; process_input — Handle joypad input during gameplay
; =============================================================================
.proc process_input
    sep #$20
    .a8
    rep #$10
    .i16

    ; Check LEFT (just pressed)
    rep #$20
    .a16
    lda joy1_pressed
    and #JOY_LEFT
    beq @no_left_press
    sep #$20
    .a8
    jsr move_left
    lda #DAS_DELAY
    sta das_timer
    lda #$01
    sta das_direction
    bra @check_right

@no_left_press:
    ; Check LEFT (held — auto-repeat)
    rep #$20
    .a16
    lda joy1_current
    and #JOY_LEFT
    sep #$20
    .a8
    beq @check_right
    lda das_direction
    cmp #$01
    bne @check_right
    dec das_timer
    bne @check_right
    jsr move_left
    lda #DAS_REPEAT
    sta das_timer

@check_right:
    ; Check RIGHT (just pressed)
    rep #$20
    .a16
    lda joy1_pressed
    and #JOY_RIGHT
    beq @no_right_press
    sep #$20
    .a8
    jsr move_right
    lda #DAS_DELAY
    sta das_timer
    lda #$02
    sta das_direction
    bra @check_down

@no_right_press:
    ; Check RIGHT (held — auto-repeat)
    rep #$20
    .a16
    lda joy1_current
    and #JOY_RIGHT
    sep #$20
    .a8
    beq @check_down
    lda das_direction
    cmp #$02
    bne @check_down
    dec das_timer
    bne @check_down
    jsr move_right
    lda #DAS_REPEAT
    sta das_timer

@check_down:
    ; Check DOWN (soft drop)
    rep #$20
    .a16
    lda joy1_current
    and #JOY_DOWN
    beq @check_rotate
    sep #$20
    .a8
    jsr move_down

@check_rotate:
    sep #$20
    .a8

    ; Check A or UP (rotate clockwise)
    rep #$20
    .a16
    lda joy1_pressed
    and #(JOY_A | JOY_UP)
    beq @check_hard_drop
    sep #$20
    .a8
    jsr rotate_cw

@check_hard_drop:
    sep #$20
    .a8

    ; Check UP for hard drop (already used for rotate above)
    ; Use B button for hard drop instead
    rep #$20
    .a16
    lda joy1_pressed
    and #JOY_B
    beq @check_start
    sep #$20
    .a8
    jsr hard_drop
    ; Play lock sound
    lda #$01
    jsr spc_play_sfx

@check_start:
    sep #$20
    .a8

    ; Clear DAS if neither left/right held
    rep #$20
    .a16
    lda joy1_current
    and #(JOY_LEFT | JOY_RIGHT)
    bne @das_ok
    sep #$20
    .a8
    stz das_direction
@das_ok:
    sep #$20
    .a8
    rts
.endproc

; =============================================================================
; NMI Handler — VBlank interrupt
; =============================================================================
.proc nmi_handler
    pha
    phx
    phy
    php

    sep #$20
    .a8

    ; Acknowledge NMI
    lda RDNMI

    ; Do VBlank rendering if main loop is ready
    lda nmi_ready
    beq @done

    jsr render_frame

    stz nmi_ready           ; Signal main loop that VBlank is done

@done:
    plp
    ply
    plx
    pla
    rti
.endproc

; =============================================================================
; IRQ Handler — Not used, just return
; =============================================================================
.proc irq_handler
    rti
.endproc

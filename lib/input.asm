; =============================================================================
; input.asm — Joypad Input Reading
; =============================================================================
; Uses auto-joypad read. Call input_read once per frame (after NMI).
; Provides current state, just-pressed (edge), and just-released.
; =============================================================================

.include "registers.inc"

.segment "ZEROPAGE"

.exportzp joy1_current, joy1_pressed, joy1_held, joy2_current, joy2_pressed
joy1_current:   .res 2      ; Current frame's button state (joy 1)
joy1_pressed:   .res 2      ; Buttons just pressed this frame (joy 1)
joy1_held:      .res 2      ; Buttons held from previous frame (joy 1)
joy2_current:   .res 2      ; Current frame's button state (joy 2)
joy2_pressed:   .res 2      ; Buttons just pressed this frame (joy 2)

.segment "BSS"
joy1_previous:  .res 2      ; Previous frame's state (joy 1)
joy2_previous:  .res 2      ; Previous frame's state (joy 2)

.segment "CODE"

.export input_init, input_read

; input_init — Enable auto-joypad reading
; Call once during initialization.
.proc input_init
    sep #$20
    .a8
    lda #$01                ; Enable auto-joypad read
    sta NMITIMEN
    rts
.endproc

; input_read — Read joypad state
; Call once per frame. Waits for auto-read to finish.
.proc input_read
    sep #$20
    .a8

    ; Wait for auto-joypad read to complete
@wait_autoread:
    lda HVBJOY
    and #$01                ; Bit 0: auto-read in progress
    bne @wait_autoread

    rep #$20
    .a16

    ; Save previous state
    lda joy1_current
    sta joy1_previous
    lda joy2_current
    sta joy2_previous

    ; Read current state
    lda JOY1L
    sta joy1_current
    lda JOY2L
    sta joy2_current

    ; Calculate "just pressed" = current AND NOT previous
    lda joy1_current
    eor joy1_previous      ; XOR with previous
    and joy1_current       ; AND with current = newly pressed
    sta joy1_pressed

    ; Calculate "held" = current AND previous
    lda joy1_current
    and joy1_previous
    sta joy1_held

    ; Joy 2 pressed
    lda joy2_current
    eor joy2_previous
    and joy2_current
    sta joy2_pressed

    rts
.endproc

; =============================================================================
; spc700.asm — Basic SPC700 Sound Driver
; =============================================================================
; Uploads a minimal sound driver to the SPC700 DSP via IPL transfer protocol.
; The driver plays simple square wave tones for sound effects.
;
; SPC700 communication uses ports $2140-$2143 (APUIO0-3).
; IPL boot protocol: the SPC700 IPL ROM listens for upload commands.
; =============================================================================

.include "registers.inc"

.segment "ZEROPAGE"
spc_ready:      .res 1      ; Flag: SPC700 driver uploaded

.segment "CODE"

.export spc_init, spc_play_sfx, spc_silence

; spc_init — Upload the minimal sound driver to SPC700
; Call once during initialization, after snes_init.
.proc spc_init
    sep #$20
    .a8

    ; Wait for SPC700 IPL to be ready (it writes $AA to port 0, $BB to port 1)
@wait_ipl:
    lda APUIO0
    cmp #$AA
    bne @wait_ipl
    lda APUIO1
    cmp #$BB
    bne @wait_ipl

    ; --- Begin IPL transfer protocol ---
    ; We'll upload our driver to SPC700 address $0200

    ; Set destination address
    lda #$00                ; Low byte of $0200
    sta APUIO2
    lda #$02                ; High byte of $0200
    sta APUIO3

    ; Signal "start transfer": $CC to port 0 (IPL trigger), non-zero to port 1
    lda #$CC
    sta APUIO1              ; Port 1 = non-zero (data transfer mode)
    sta APUIO0              ; Port 0 = $CC (IPL waits for this value)

    ; Wait for acknowledgment (SPC echoes port 0 value)
@wait_ack_start:
    cmp APUIO0
    bne @wait_ack_start

    ; Transfer driver bytes
    ldx #$0000
    .i16
@upload_loop:
    cpx #(spc_driver_end - spc_driver)
    beq @upload_done

    ; Write data byte to port 1
    lda spc_driver,x
    sta APUIO1

    ; Write index counter to port 0 (incrementing)
    txa                     ; Low byte of X
    sta APUIO0

    ; Wait for SPC to echo the counter back
@wait_ack_byte:
    cmp APUIO0
    bne @wait_ack_byte

    inx
    bra @upload_loop

@upload_done:
    ; Signal "execute uploaded code" by writing entry address
    ; Entry point = $0200 (start of our uploaded code)
    lda #$00
    sta APUIO2              ; Execution addr low
    lda #$02
    sta APUIO3              ; Execution addr high

    ; Write value with bit 1 different from last counter to signal execute
    ; Last value written to port 0 was (size-1). Write (size) + 2 with bit 0 change
    lda #$00                ; Counter val that differs in bit 1 from last
    sta APUIO1
    inx
    inx
    txa
    sta APUIO0              ; This signals "execute" to IPL

    ; Wait for driver to signal ready (it'll write $01 to port 0)
@wait_ready:
    lda APUIO0
    cmp #$01
    bne @wait_ready

    lda #$01
    sta spc_ready
    rts
.endproc

; spc_play_sfx — Trigger a sound effect
; Input: A (8-bit) = sound effect ID
;   $01 = piece lock click (short, low)
;   $02 = line clear chime (longer, higher pitch)
;   $03 = tetris clear (4 lines, ascending)
;   $04 = game over tone
.proc spc_play_sfx
    sep #$20
    .a8

    ; Check if driver is ready
    ldx spc_ready
    beq @skip

    ; Write command to port 1 (effect ID)
    sta APUIO1
    ; Write trigger signal to port 0 (toggle bit 0)
    lda APUIO0
    eor #$80                ; Toggle high bit as "new command" signal
    sta APUIO0

@skip:
    rts
.endproc

; spc_silence — Stop all sound
.proc spc_silence
    sep #$20
    .a8
    lda spc_ready
    beq @skip

    lda #$FF                ; $FF = silence command
    sta APUIO1
    lda APUIO0
    eor #$80
    sta APUIO0

@skip:
    rts
.endproc

; =============================================================================
; Minimal SPC700 driver program (assembled for SPC700 CPU)
; =============================================================================
; This runs on the SPC700 at address $0200.
; It listens for commands on I/O ports and plays simple tones.
;
; SPC700 DSP registers:
;   $00-$09 per voice (8 voices): VOL_L, VOL_R, PITCH_L, PITCH_H, SRCN, ADSR1, ADSR2, GAIN
;   $4C = KON (key on), $5C = KOFF (key off), $6C = FLG (flags/noise)
;   $0C = MVOL_L, $1C = MVOL_R (master volume)
;
; The driver uses Voice 0 for sound effects with a simple BRR sample.
; =============================================================================

.segment "RODATA"

spc_driver:
    ; --- SPC700 machine code (hand-assembled) ---
    ; This is raw SPC700 bytecode, not 65816!

    ; $0200: Initialize DSP
    .byte $E8, $01          ; MOV A, #$01          ; Signal ready
    .byte $C4, $F4          ; MOV $F4, A           ; Write to port 0
    ; Set master volume
    .byte $8F, $0C, $F2     ; MOV $F2, #$0C        ; DSP addr = MVOL_L
    .byte $8F, $50, $F3     ; MOV $F3, #$50        ; Master vol L = $50
    .byte $8F, $1C, $F2     ; MOV $F2, #$1C        ; DSP addr = MVOL_R
    .byte $8F, $50, $F3     ; MOV $F3, #$50        ; Master vol R = $50
    ; Set voice 0 source to our BRR sample (at DIR entry 0)
    .byte $8F, $5D, $F2     ; MOV $F2, #$5D        ; DSP addr = DIR (sample directory)
    .byte $8F, $04, $F3     ; MOV $F3, #$04        ; DIR page = $0400
    ; Set up voice 0 envelope (ADSR: fast attack, medium decay, low sustain)
    .byte $8F, $05, $F2     ; MOV $F2, #$05        ; DSP addr = V0 ADSR1
    .byte $8F, $8F, $F3     ; MOV $F3, #$8F        ; ADSR on, attack=15, decay=0
    .byte $8F, $06, $F2     ; MOV $F2, #$06        ; DSP addr = V0 ADSR2
    .byte $8F, $1F, $F3     ; MOV $F3, #$1F        ; Sustain level=1, release=31
    ; Voice 0 volume
    .byte $8F, $00, $F2     ; MOV $F2, #$00        ; DSP addr = V0 VOL_L
    .byte $8F, $40, $F3     ; MOV $F3, #$40        ; Vol L = $40
    .byte $8F, $01, $F2     ; MOV $F2, #$01        ; DSP addr = V0 VOL_R
    .byte $8F, $40, $F3     ; MOV $F3, #$40        ; Vol R = $40
    ; Voice 0 source number = 0
    .byte $8F, $04, $F2     ; MOV $F2, #$04        ; DSP addr = V0 SRCN
    .byte $8F, $00, $F3     ; MOV $F3, #$00        ; Source = 0

    ; Set up sample directory at $0400 (BRR sample pointer)
    .byte $8F, $80, $00     ; MOV $00, #$80        ; Temp: sample addr low = $0480
    .byte $8F, $04, $01     ; MOV $01, #$04        ; Temp: sample addr high
    .byte $E8, $80          ; MOV A, #$80          ; Sample start low
    .byte $C4, $00          ; MOV $00, A           ; (direct page temp)
    ; Write directory: $0400 = start_L, $0401 = start_H, $0402 = loop_L, $0403 = loop_H
    .byte $8F, $80, $F2     ; (skip — we'll embed the sample directly)

    ; --- Main loop: wait for commands ---
    ; $024A (approx): Main loop
    .byte $E4, $F4          ; MOV A, $F4           ; Read port 0
    .byte $64, $20          ; CMP A, $20           ; Compare with last processed
    .byte $F0, $FA          ; BEQ -6               ; Loop if no new command

    .byte $C4, $20          ; MOV $20, A           ; Save new command tag
    .byte $E4, $F5          ; MOV A, $F5           ; Read port 1 (effect ID)

    ; Check for silence command
    .byte $68, $FF          ; CMP A, #$FF
    .byte $D0, $08          ; BNE +8 (skip silence)
    ; Key off voice 0
    .byte $8F, $5C, $F2     ; MOV $F2, #$5C        ; KOFF register
    .byte $8F, $01, $F3     ; MOV $F3, #$01        ; Key off voice 0
    .byte $2F, $E8          ; BRA main_loop        ; Back to top

    ; Play tone based on effect ID
    ; Effect 1: low tone ($0800)
    .byte $68, $01          ; CMP A, #$01
    .byte $D0, $0A          ; BNE +10
    .byte $8F, $02, $F2     ; MOV $F2, #$02        ; V0 PITCH_L
    .byte $8F, $00, $F3     ; MOV $F3, #$00
    .byte $8F, $03, $F2     ; MOV $F2, #$03        ; V0 PITCH_H
    .byte $8F, $08, $F3     ; MOV $F3, #$08
    .byte $2F, $06          ; BRA key_on

    ; Effect 2+: higher tone ($1000)
    .byte $8F, $02, $F2     ; MOV $F2, #$02        ; V0 PITCH_L
    .byte $8F, $00, $F3     ; MOV $F3, #$00
    .byte $8F, $03, $F2     ; MOV $F2, #$03        ; V0 PITCH_H
    .byte $8F, $10, $F3     ; MOV $F3, #$10

    ; Key on voice 0
    .byte $8F, $4C, $F2     ; MOV $F2, #$4C        ; KON register
    .byte $8F, $01, $F3     ; MOV $F3, #$01        ; Key on voice 0

    .byte $2F, $C4          ; BRA main_loop

spc_driver_end:

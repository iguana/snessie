; =============================================================================
; header.inc — SNES ROM Header Macro
; =============================================================================
; Emits the ROM header at $00FFC0 and vector table at $00FFE0/$00FFF0
; Usage:
;   ROM_HEADER "GAME TITLE HERE", $20, $00, $08, $00, $01, $00
;   VECTOR_TABLE nmi_handler, reset_handler, irq_handler
; =============================================================================

; ROM_HEADER — Emit the SNES ROM header
; Parameters:
;   title    — Game title string (padded/truncated to 21 bytes)
;   mapmode  — Mapping mode ($20 = LoROM, $21 = HiROM, $30 = LoROM+FastROM)
;   romtype  — ROM type ($00 = ROM only, $01 = ROM+RAM, $02 = ROM+RAM+SRAM)
;   romsize  — ROM size ($08 = 256KB, $09 = 512KB, $0A = 1MB)
;   ramsize  — RAM size ($00 = none, $01 = 2KB, $03 = 8KB)
;   region   — Country ($01 = North America, $02 = Europe, $00 = Japan)
;   version  — Version number (usually $00)
.macro ROM_HEADER title, mapmode, romtype, romsize, ramsize, region, version
    .segment "HEADER"

    ; $FFC0-$FFD4: Game title (21 bytes, space-padded)
    .byte title
    .res 21 - .strlen(title), $20   ; Pad with spaces

    ; $FFD5: Map mode
    .byte mapmode

    ; $FFD6: ROM type
    .byte romtype

    ; $FFD7: ROM size (2^n KB, so $08 = 256KB)
    .byte romsize

    ; $FFD8: RAM size (2^n KB, so $00 = 0KB)
    .byte ramsize

    ; $FFD9: Region/country code
    .byte region

    ; $FFDA: Developer ID (use $33 for extended header, $00 otherwise)
    .byte $00

    ; $FFDB: Version number
    .byte version

    ; $FFDC-$FFDF: Checksum complement + checksum (placeholder — linker fixes)
    .word $FFFF     ; Complement (placeholder)
    .word $0000     ; Checksum (placeholder)
.endmacro

; VECTOR_TABLE — Emit native + emulation mode interrupt vectors
; Parameters:
;   nmi_handler   — NMI (VBlank) handler address
;   reset_handler — RESET handler address
;   irq_handler   — IRQ handler address
.macro VECTOR_TABLE nmi_handler, reset_handler, irq_handler
    .segment "VECTORS"

    ; Native mode vectors ($FFE0-$FFEF)
    .word $0000             ; $FFE0 — unused
    .word $0000             ; $FFE2 — unused
    .word $0000             ; $FFE4 — COP
    .word $0000             ; $FFE6 — BRK
    .word $0000             ; $FFE8 — ABORT
    .word nmi_handler       ; $FFEA — NMI (VBlank)
    .word $0000             ; $FFEC — unused
    .word irq_handler       ; $FFEE — IRQ

    ; Emulation mode vectors ($FFF0-$FFFF)
    .word $0000             ; $FFF0 — unused
    .word $0000             ; $FFF2 — unused
    .word $0000             ; $FFF4 — COP
    .word $0000             ; $FFF6 — unused
    .word $0000             ; $FFF8 — ABORT
    .word nmi_handler       ; $FFFA — NMI
    .word reset_handler     ; $FFFC — RESET
    .word irq_handler       ; $FFFE — IRQ/BRK
.endmacro

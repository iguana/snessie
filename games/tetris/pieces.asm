; =============================================================================
; pieces.asm — Tetromino Definitions and Rotation Tables
; =============================================================================
; 7 tetrominoes (I, O, T, S, Z, J, L), each with 4 rotation states.
; Each state stored as a 4×4 bitmask (2 bytes = 16 bits, row-major).
; Bit layout: row0[3:0], row1[3:0], row2[3:0], row3[3:0]
;   bit 15..12 = row 0 (top), bit 11..8 = row 1, bit 7..4 = row 2, bit 3..0 = row 3
;   Within each nibble: bit3=col0(left), bit2=col1, bit1=col2, bit0=col3(right)
; =============================================================================

.segment "RODATA"

.export piece_rotations, piece_colors, PIECE_COUNT

PIECE_COUNT = 7

; Piece color palette indices (which subpalette to use: 1-7)
piece_colors:
    .byte 1     ; I = cyan (palette 1)
    .byte 2     ; O = yellow (palette 2)
    .byte 3     ; T = purple (palette 3)
    .byte 4     ; S = green (palette 4)
    .byte 5     ; Z = red (palette 5)
    .byte 6     ; J = blue (palette 6)
    .byte 7     ; L = orange (palette 7)

; Rotation table: 7 pieces × 4 rotations × 2 bytes = 56 bytes
; Index: piece_id * 8 + rotation * 2
piece_rotations:

; --- I-piece (piece 0) ---
; Rot 0:        Rot 1:        Rot 2:        Rot 3:
; . . . .       . . X .       . . . .       . X . .
; X X X X       . . X .       . . . .       . X . .
; . . . .       . . X .       X X X X       . X . .
; . . . .       . . X .       . . . .       . X . .
    .word %0000111100000000   ; Rotation 0
    .word %0010001000100010   ; Rotation 1
    .word %0000000011110000   ; Rotation 2 (same shape, shifted down)
    .word %0100010001000100   ; Rotation 3

; --- O-piece (piece 1) ---
; All rotations same:
; . . . .
; . X X .
; . X X .
; . . . .
    .word %0000011001100000   ; Rotation 0
    .word %0000011001100000   ; Rotation 1
    .word %0000011001100000   ; Rotation 2
    .word %0000011001100000   ; Rotation 3

; --- T-piece (piece 2) ---
; Rot 0:        Rot 1:        Rot 2:        Rot 3:
; . X . .       . X . .       . . . .       . X . .
; X X X .       . X X .       X X X .       X X . .
; . . . .       . X . .       . X . .       . X . .
; . . . .       . . . .       . . . .       . . . .
    .word %0100111000000000   ; Rotation 0: $4E00
    .word %0100011001000000   ; Rotation 1: $4640
    .word %0000111001000000   ; Rotation 2: $0E40
    .word %0100110001000000   ; Rotation 3: $4C40

; --- S-piece (piece 3) ---
; Rot 0:        Rot 1:
; . X X .       X . . .
; X X . .       X X . .
; . . . .       . X . .
; . . . .       . . . .
    .word %0110110000000000   ; Rotation 0: $6C00
    .word %1000110001000000   ; Rotation 1: $8C40
    .word %0110110000000000   ; Rotation 2: $6C00
    .word %1000110001000000   ; Rotation 3: $8C40

; --- Z-piece (piece 4) ---
; Rot 0:        Rot 1:
; X X . .       . X . .
; . X X .       X X . .
; . . . .       X . . .
; . . . .       . . . .
    .word %1100011000000000   ; Rotation 0: $C600
    .word %0010011001000000   ; Rotation 1: $2640
    .word %1100011000000000   ; Rotation 2: $C600
    .word %0010011001000000   ; Rotation 3: $2640

; --- J-piece (piece 5) ---
; Rot 0:        Rot 1:        Rot 2:        Rot 3:
; X . . .       . X X .       . . . .       . X . .
; X X X .       . X . .       X X X .       . X . .
; . . . .       . X . .       . . X .       X X . .
; . . . .       . . . .       . . . .       . . . .
    .word %1000111000000000   ; Rotation 0: $8E00
    .word %0110010001000000   ; Rotation 1: $6440
    .word %0000111000100000   ; Rotation 2: $0E20
    .word %0100010011000000   ; Rotation 3: $44C0

; --- L-piece (piece 6) ---
; Rot 0:        Rot 1:        Rot 2:        Rot 3:
; . . X .       . X . .       . . . .       X X . .
; X X X .       . X . .       X X X .       . X . .
; . . . .       . X X .       X . . .       . X . .
; . . . .       . . . .       . . . .       . . . .
    .word %0010111000000000   ; Rotation 0: $2E00
    .word %0100010001100000   ; Rotation 1: $4460
    .word %0000111010000000   ; Rotation 2: $0E80
    .word %1100010001000000   ; Rotation 3: $C440

; =============================================================================
; Helper: Get piece cell at (row, col) from bitmask
; =============================================================================
; piece_get_cell — Check if piece has a cell at given position
; Input:
;   X = pointer to piece rotation word (in piece_rotations)
;   A (8-bit) = row * 4 + col (0-15)
; Output:
;   Carry set if cell is occupied, clear if empty
; =============================================================================

.segment "CODE"

.export piece_get_cell

.proc piece_get_cell
    ; A = bit position (0-15), piece data at address in X
    ; We need to test bit (15-A) of the 16-bit word
    pha
    rep #$20
    .a16
    lda $0000,x             ; Load piece bitmask
    sta piece_temp
    sep #$20
    .a8
    pla

    ; Bit to test = 15 - A
    eor #$0F                ; A = 15 - original A
    tax

    rep #$20
    .a16
    lda piece_temp
    ; Shift right by X positions
    cpx #$0000
    beq @done
@shift:
    lsr a
    dex
    bne @shift
@done:
    ; Bit 0 now has our answer
    lsr a                   ; Shift into carry
    sep #$20
    .a8
    rts
.endproc

.segment "ZEROPAGE"
piece_temp: .res 2

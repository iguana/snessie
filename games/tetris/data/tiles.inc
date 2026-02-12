; =============================================================================
; tiles.inc — 4bpp Tile Graphics for Tetris
; =============================================================================
; Tiles (8x8 each, 32 bytes per tile in 4bpp planar format):
;   Tile 0: Empty/transparent
;   Tile 1: Solid block (filled square with highlight)
;   Tile 2: Border top-left corner
;   Tile 3: Border horizontal
;   Tile 4: Border vertical
;   Tile 5: Border top-right corner
;   Tile 6: Border bottom-left corner
;   Tile 7: Border bottom-right corner
; =============================================================================

tile_data:

; --- Tile 0: Empty (all zeros) ---
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00

; --- Tile 1: Solid block (used for all tetromino cells) ---
; Pattern: bright outer edge (color 1), mid shadow (color 2), fill (color 3)
; 4bpp interleaved format: bp0_rowN, bp1_rowN pairs, then bp2/bp3 pairs
; Color indices: 1=highlight, 2=shadow, 3=fill
;   Row 0: 1 1 1 1 1 1 1 1   (all color 1)
;   Row 1: 1 2 2 2 2 2 2 1
;   Row 2: 1 2 3 3 3 3 2 1
;   Row 3: 1 2 3 3 3 3 2 1
;   Row 4: 1 2 3 3 3 3 2 1
;   Row 5: 1 2 3 3 3 3 2 1
;   Row 6: 1 2 2 2 2 2 2 1
;   Row 7: 1 1 1 1 1 1 1 1
; Bitplanes 0,1 interleaved (bp0_row, bp1_row):
    .byte %11111111, %00000000  ; row 0: all idx 1 (bp0=1,bp1=0)
    .byte %10000001, %01111110  ; row 1: edges=1, inner=2
    .byte %10111101, %01000010  ; row 2: edge=1, shadow=2, fill=3
    .byte %10111101, %01000010  ; row 3
    .byte %10111101, %01000010  ; row 4
    .byte %10111101, %01000010  ; row 5
    .byte %10000001, %01111110  ; row 6
    .byte %11111111, %00000000  ; row 7
; Bitplanes 2,3 interleaved (all zero — only using colors 0-3)
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00

; --- Tile 2: Border top-left corner ---
; Pattern: ╔
    .byte %00000000, %00000000  ; row 0: bp0, bp1
    .byte %00000000, %00000000  ; row 1
    .byte %00111111, %00111111  ; row 2
    .byte %00100000, %00100000  ; row 3
    .byte %00100000, %00100000  ; row 4
    .byte %00100000, %00100000  ; row 5
    .byte %00100000, %00100000  ; row 6
    .byte %00100000, %00100000  ; row 7
    .byte $00, $00, $00, $00, $00, $00, $00, $00   ; bp2-3
    .byte $00, $00, $00, $00, $00, $00, $00, $00

; --- Tile 3: Border horizontal ---
; Pattern: ═
    .byte %00000000, %00000000  ; row 0
    .byte %00000000, %00000000  ; row 1
    .byte %11111111, %11111111  ; row 2
    .byte %00000000, %00000000  ; row 3
    .byte %00000000, %00000000  ; row 4
    .byte %00000000, %00000000  ; row 5
    .byte %00000000, %00000000  ; row 6
    .byte %00000000, %00000000  ; row 7
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00

; --- Tile 4: Border vertical ---
; Pattern: ║
    .byte %00100000, %00100000  ; row 0
    .byte %00100000, %00100000  ; row 1
    .byte %00100000, %00100000  ; row 2
    .byte %00100000, %00100000  ; row 3
    .byte %00100000, %00100000  ; row 4
    .byte %00100000, %00100000  ; row 5
    .byte %00100000, %00100000  ; row 6
    .byte %00100000, %00100000  ; row 7
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00

; --- Tile 5: Border top-right corner ---
; Pattern: ╗
    .byte %00000000, %00000000
    .byte %00000000, %00000000
    .byte %11111100, %11111100
    .byte %00000100, %00000100
    .byte %00000100, %00000100
    .byte %00000100, %00000100
    .byte %00000100, %00000100
    .byte %00000100, %00000100
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00

; --- Tile 6: Border bottom-left corner ---
; Pattern: ╚
    .byte %00100000, %00100000
    .byte %00100000, %00100000
    .byte %00111111, %00111111
    .byte %00000000, %00000000
    .byte %00000000, %00000000
    .byte %00000000, %00000000
    .byte %00000000, %00000000
    .byte %00000000, %00000000
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00

; --- Tile 7: Border bottom-right corner ---
; Pattern: ╝
    .byte %00000100, %00000100
    .byte %00000100, %00000100
    .byte %11111100, %11111100
    .byte %00000000, %00000000
    .byte %00000000, %00000000
    .byte %00000000, %00000000
    .byte %00000000, %00000000
    .byte %00000000, %00000000
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00

; --- Tile 8: Border vertical (right side) ---
; Pattern: ║ (line at bit 2, matching right corner tiles 5 and 7)
    .byte %00000100, %00000100  ; row 0
    .byte %00000100, %00000100  ; row 1
    .byte %00000100, %00000100  ; row 2
    .byte %00000100, %00000100  ; row 3
    .byte %00000100, %00000100  ; row 4
    .byte %00000100, %00000100  ; row 5
    .byte %00000100, %00000100  ; row 6
    .byte %00000100, %00000100  ; row 7
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00

tile_data_end:

; =============================================================================
; playfield.inc — Background Tilemap for Tetris Playfield Border
; =============================================================================
; The playfield is 10 columns × 20 rows of game cells.
; On the SNES 32×32 tilemap (256×256 px), we center the playfield:
;   Left border at column 3, playfield columns 4-13, right border at column 14
;   Top border at row 1, playfield rows 2-21, bottom border at row 22
;
; Tilemap entries are 16-bit: vhopppcc cccccccc
;   v = V-flip, h = H-flip, o = priority, ppp = palette, cccccccccc = tile #
;
; Tile indices: 0=empty, 2=TL corner, 3=horiz, 4=vert, 5=TR corner, 6=BL, 7=BR
; All borders use palette 0
;
; This data defines only the border frame. The playfield interior (tiles 4-13,
; rows 2-21) is dynamically written by the game renderer.
;
; We store this as a list of (column, row, tile) entries for the init routine
; to write, rather than a full 32×32 tilemap (which would be 2KB).
; =============================================================================

; Playfield geometry constants
FIELD_LEFT   = 3        ; Tilemap column of left border
FIELD_RIGHT  = 14       ; Tilemap column of right border
FIELD_TOP    = 1        ; Tilemap row of top border
FIELD_BOTTOM = 22       ; Tilemap row of bottom border
FIELD_X      = 4        ; First playfield column
FIELD_Y      = 2        ; First playfield row
FIELD_W      = 10       ; Playfield width in tiles
FIELD_H      = 20       ; Playfield height in tiles

; "Next piece" preview area
NEXT_X       = 17       ; Column for "NEXT" label
NEXT_Y       = 3        ; Row for "NEXT" label
NEXT_BOX_X   = 17       ; Preview box X
NEXT_BOX_Y   = 5        ; Preview box Y

; Score/level/lines display positions
SCORE_X      = 17
SCORE_Y      = 10
LEVEL_X      = 17
LEVEL_Y      = 14
LINES_X      = 17
LINES_Y      = 18

; Border tilemap data: x, y, tile_id (terminated by $FF)
; Each entry is 3 bytes.
playfield_border:
    ; Top border: TL corner, horizontal × 10, TR corner
    .byte FIELD_LEFT, FIELD_TOP, 2       ; Top-left corner
    .byte FIELD_LEFT+1, FIELD_TOP, 3     ; Horizontal
    .byte FIELD_LEFT+2, FIELD_TOP, 3
    .byte FIELD_LEFT+3, FIELD_TOP, 3
    .byte FIELD_LEFT+4, FIELD_TOP, 3
    .byte FIELD_LEFT+5, FIELD_TOP, 3
    .byte FIELD_LEFT+6, FIELD_TOP, 3
    .byte FIELD_LEFT+7, FIELD_TOP, 3
    .byte FIELD_LEFT+8, FIELD_TOP, 3
    .byte FIELD_LEFT+9, FIELD_TOP, 3
    .byte FIELD_LEFT+10, FIELD_TOP, 3
    .byte FIELD_RIGHT, FIELD_TOP, 5      ; Top-right corner

    ; Left border: vertical × 20
    .repeat 20, i
        .byte FIELD_LEFT, FIELD_TOP+1+i, 4
    .endrepeat

    ; Right border: vertical × 20 (tile 8 = right-side vertical, matches corners 5/7)
    .repeat 20, i
        .byte FIELD_RIGHT, FIELD_TOP+1+i, 8
    .endrepeat

    ; Bottom border: BL corner, horizontal × 10, BR corner
    .byte FIELD_LEFT, FIELD_BOTTOM, 6    ; Bottom-left corner
    .byte FIELD_LEFT+1, FIELD_BOTTOM, 3
    .byte FIELD_LEFT+2, FIELD_BOTTOM, 3
    .byte FIELD_LEFT+3, FIELD_BOTTOM, 3
    .byte FIELD_LEFT+4, FIELD_BOTTOM, 3
    .byte FIELD_LEFT+5, FIELD_BOTTOM, 3
    .byte FIELD_LEFT+6, FIELD_BOTTOM, 3
    .byte FIELD_LEFT+7, FIELD_BOTTOM, 3
    .byte FIELD_LEFT+8, FIELD_BOTTOM, 3
    .byte FIELD_LEFT+9, FIELD_BOTTOM, 3
    .byte FIELD_LEFT+10, FIELD_BOTTOM, 3
    .byte FIELD_RIGHT, FIELD_BOTTOM, 7   ; Bottom-right corner

    .byte $FF   ; Terminator

playfield_border_end:

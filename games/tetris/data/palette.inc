; =============================================================================
; palette.inc — SNES CGRAM Palette Data for Tetris
; =============================================================================
; SNES color format: 15-bit, little-endian: 0bbbbbgg gggrrrrr
; Each palette has 16 colors (4bpp mode), 32 bytes per palette.
; We define 8 palettes (subpalettes 0-7):
;   Palette 0: Background/UI (border, empty cells)
;   Palette 1: I-piece (cyan)
;   Palette 2: O-piece (yellow)
;   Palette 3: T-piece (purple)
;   Palette 4: S-piece (green)
;   Palette 5: Z-piece (red)
;   Palette 6: J-piece (blue)
;   Palette 7: L-piece (orange)
;
; For each subpalette, color 0 = transparent/BG, colors 1-3 = block shading
;   Color 0: Background color (shared, transparent in BG layer)
;   Color 1: Light highlight edge
;   Color 2: Mid shadow
;   Color 3: Main fill color
; =============================================================================

palette_data:

; --- Palette 0: Background / UI ---
; 0: Black (BG), 1: White (border highlight), 2: Gray (border mid), 3: Light gray (border)
    .word $0000     ; 0: Black
    .word $7FFF     ; 1: White
    .word $294A     ; 2: Dark gray
    .word $4E73     ; 3: Light gray
    .word $0000, $0000, $0000, $0000    ; 4-7: unused
    .word $0000, $0000, $0000, $0000    ; 8-11: unused
    .word $0000, $0000, $0000, $0000    ; 12-15: unused

; --- Palette 1: I-piece (Cyan) ---
    .word $0000     ; 0: Transparent
    .word $7FFF     ; 1: White highlight
    .word $4C90     ; 2: Dark cyan
    .word $5F17     ; 3: Bright cyan
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000

; --- Palette 2: O-piece (Yellow) ---
    .word $0000
    .word $7FFF     ; 1: White highlight
    .word $02DF     ; 2: Dark yellow
    .word $03FF     ; 3: Bright yellow
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000

; --- Palette 3: T-piece (Purple) ---
    .word $0000
    .word $7FFF
    .word $5010     ; 2: Dark purple
    .word $7C1F     ; 3: Bright purple
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000

; --- Palette 4: S-piece (Green) ---
    .word $0000
    .word $7FFF
    .word $0260     ; 2: Dark green
    .word $03E0     ; 3: Bright green
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000

; --- Palette 5: Z-piece (Red) ---
    .word $0000
    .word $7FFF
    .word $0013     ; 2: Dark red
    .word $001F     ; 3: Bright red
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000

; --- Palette 6: J-piece (Blue) ---
    .word $0000
    .word $7FFF
    .word $5800     ; 2: Dark blue
    .word $7C00     ; 3: Bright blue
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000

; --- Palette 7: L-piece (Orange) ---
    .word $0000
    .word $7FFF
    .word $011F     ; 2: Dark orange
    .word $02BF     ; 3: Bright orange
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000
    .word $0000, $0000, $0000, $0000

palette_data_end:

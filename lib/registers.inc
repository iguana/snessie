; =============================================================================
; registers.inc — SNES Hardware Register Definitions
; =============================================================================
; All registers as .define constants for ca65/ld65
; Reference: SNES Development Manual, fullsnes.txt
; =============================================================================

; --- PPU Registers ($2100-$213F) ---

; Screen display control
.define INIDISP     $2100   ; Screen display register (brightness + force blank)
.define OBSEL       $2101   ; Object size and character base
.define OAMADDL     $2102   ; OAM address (low)
.define OAMADDH     $2103   ; OAM address (high)
.define OAMDATA     $2104   ; OAM data write

; BG mode and mosaic
.define BGMODE      $2105   ; BG mode and character size
.define MOSAIC      $2106   ; Mosaic size and enable

; BG tilemap address
.define BG1SC       $2107   ; BG1 tilemap address and size
.define BG2SC       $2108   ; BG2 tilemap address and size
.define BG3SC       $2109   ; BG3 tilemap address and size
.define BG4SC       $210A   ; BG4 tilemap address and size

; BG character (tile) data address
.define BG12NBA     $210B   ; BG1/BG2 character data address
.define BG34NBA     $210C   ; BG3/BG4 character data address

; BG scroll registers
.define BG1HOFS     $210D   ; BG1 horizontal scroll
.define BG1VOFS     $210E   ; BG1 vertical scroll
.define BG2HOFS     $210F   ; BG2 horizontal scroll
.define BG2VOFS     $2110   ; BG2 vertical scroll
.define BG3HOFS     $2111   ; BG3 horizontal scroll
.define BG3VOFS     $2112   ; BG3 vertical scroll
.define BG4HOFS     $2113   ; BG4 horizontal scroll
.define BG4VOFS     $2114   ; BG4 vertical scroll

; VRAM access
.define VMAIN       $2115   ; VRAM address increment mode
.define VMADDL      $2116   ; VRAM address (low)
.define VMADDH      $2117   ; VRAM address (high)
.define VMDATAL     $2118   ; VRAM data write (low)
.define VMDATAH     $2119   ; VRAM data write (high)

; CGRAM (color palette) access
.define CGADD       $2121   ; CGRAM address
.define CGDATA      $2122   ; CGRAM data write

; Window registers
.define W12SEL      $2123   ; Window mask settings for BG1/BG2
.define W34SEL      $2124   ; Window mask settings for BG3/BG4
.define WOBJSEL     $2125   ; Window mask settings for OBJ/Color
.define WH0         $2126   ; Window 1 left position
.define WH1         $2127   ; Window 1 right position
.define WH2         $2128   ; Window 2 left position
.define WH3         $2129   ; Window 2 right position
.define WBGLOG      $212A   ; Window mask logic for BGs
.define WOBJLOG     $212B   ; Window mask logic for OBJ/Color

; Screen designation
.define TM          $212C   ; Main screen designation
.define TS          $212D   ; Sub screen designation
.define TMW         $212E   ; Window mask for main screen
.define TSW         $212F   ; Window mask for sub screen

; Color math
.define CGWSEL      $2130   ; Color addition select
.define CGADSUB     $2131   ; Color math designation
.define COLDATA     $2132   ; Fixed color data

; Display mode
.define SETINI      $2133   ; Screen mode/video select

; PPU read registers
.define MPYL        $2134   ; Mode 7 multiply result (low)
.define MPYM        $2135   ; Mode 7 multiply result (mid)
.define MPYH        $2136   ; Mode 7 multiply result (high)
.define SLHV        $2137   ; Software latch for H/V counter
.define OAMDATAREAD $2138   ; OAM data read
.define VMDATALREAD $2139   ; VRAM data read (low)
.define VMDATAHREAD $213A   ; VRAM data read (high)
.define CGDATAREAD  $213B   ; CGRAM data read
.define OPHCT       $213C   ; Horizontal scanline counter
.define OPVCT       $213D   ; Vertical scanline counter
.define STAT77      $213E   ; PPU status flag 1
.define STAT78      $213F   ; PPU status flag 2

; --- CPU I/O Registers ($4200-$421F) ---

.define NMITIMEN    $4200   ; Interrupt enable (NMI, IRQ, auto-joypad)
.define WRIO        $4201   ; Programmable I/O port (out)
.define WRMPYA      $4202   ; Multiplicand A
.define WRMPYB      $4203   ; Multiplicand B (starts multiply)
.define WRDIVL      $4204   ; Dividend (low)
.define WRDIVH      $4205   ; Dividend (high)
.define WRDIVB      $4206   ; Divisor (starts divide)
.define HTIMEL      $4207   ; H-Count timer (low)
.define HTIMEH      $4208   ; H-Count timer (high)
.define VTIMEL      $4209   ; V-Count timer (low)
.define VTIMEH      $420A   ; V-Count timer (high)
.define MDMAEN      $420B   ; DMA enable
.define HDMAEN      $420C   ; HDMA enable
.define MEMSEL      $420D   ; ROM access speed

; CPU read registers
.define RDNMI       $4210   ; NMI flag and 5A22 version
.define TIMEUP      $4211   ; IRQ flag
.define HVBJOY      $4212   ; PPU status (VBlank, HBlank, auto-joypad)
.define RDIO        $4213   ; Programmable I/O port (in)
.define RDDIVL      $4214   ; Quotient of divide (low)
.define RDDIVH      $4215   ; Quotient of divide (high)
.define RDMPYL      $4216   ; Product/remainder (low)
.define RDMPYH      $4217   ; Product/remainder (high)

; Joypad registers (auto-read results)
.define JOY1L       $4218   ; Joypad 1 (low)
.define JOY1H       $4219   ; Joypad 1 (high)
.define JOY2L       $421A   ; Joypad 2 (low)
.define JOY2H       $421B   ; Joypad 2 (high)
.define JOY3L       $421C   ; Joypad 3 (low)
.define JOY3H       $421D   ; Joypad 3 (high)
.define JOY4L       $421E   ; Joypad 4 (low)
.define JOY4H       $421F   ; Joypad 4 (high)

; --- DMA Registers ($4300-$437F) ---
; Channels 0-7: base + ($10 * channel)

; Channel 0
.define DMAP0       $4300   ; DMA control (channel 0)
.define BBAD0       $4301   ; DMA destination (B-bus address, channel 0)
.define A1T0L       $4302   ; DMA source address (low, channel 0)
.define A1T0H       $4303   ; DMA source address (high, channel 0)
.define A1B0        $4304   ; DMA source bank (channel 0)
.define DAS0L       $4305   ; DMA size (low, channel 0)
.define DAS0H       $4306   ; DMA size (high, channel 0)

; Channel 1
.define DMAP1       $4310   ; DMA control (channel 1)
.define BBAD1       $4311   ; DMA destination (channel 1)
.define A1T1L       $4312   ; DMA source address (low, channel 1)
.define A1T1H       $4313   ; DMA source address (high, channel 1)
.define A1B1        $4314   ; DMA source bank (channel 1)
.define DAS1L       $4315   ; DMA size (low, channel 1)
.define DAS1H       $4316   ; DMA size (high, channel 1)

; Channel 2
.define DMAP2       $4320   ; DMA control (channel 2)
.define BBAD2       $4321   ; DMA destination (channel 2)
.define A1T2L       $4322   ; DMA source address (low, channel 2)
.define A1T2H       $4323   ; DMA source address (high, channel 2)
.define A1B2        $4324   ; DMA source bank (channel 2)
.define DAS2L       $4325   ; DMA size (low, channel 2)
.define DAS2H       $4326   ; DMA size (high, channel 2)

; Channel 7 (commonly used for general DMA)
.define DMAP7       $4370   ; DMA control (channel 7)
.define BBAD7       $4371   ; DMA destination (channel 7)
.define A1T7L       $4372   ; DMA source address (low, channel 7)
.define A1T7H       $4373   ; DMA source address (high, channel 7)
.define A1B7        $4374   ; DMA source bank (channel 7)
.define DAS7L       $4375   ; DMA size (low, channel 7)
.define DAS7H       $4376   ; DMA size (high, channel 7)

; --- SPC700 Communication Ports ---

.define APUIO0      $2140   ; APU I/O register 0
.define APUIO1      $2141   ; APU I/O register 1
.define APUIO2      $2142   ; APU I/O register 2
.define APUIO3      $2143   ; APU I/O register 3

; --- Button Masks (for joypad reads) ---

.define JOY_B       $8000
.define JOY_Y       $4000
.define JOY_SELECT  $2000
.define JOY_START   $1000
.define JOY_UP      $0800
.define JOY_DOWN    $0400
.define JOY_LEFT    $0200
.define JOY_RIGHT   $0100
.define JOY_A       $0080
.define JOY_X       $0040
.define JOY_L       $0020
.define JOY_R       $0010

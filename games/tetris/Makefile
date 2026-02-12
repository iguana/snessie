# =============================================================================
# Tetris — Game Build Makefile
# =============================================================================

# Tools
CA65 = ca65
LD65 = ld65

# Paths
ROOT     = ../..
CFG      = $(ROOT)/cfg/lorom256k.cfg
LIBDIR   = $(ROOT)/lib
INCLUDES = -I $(LIBDIR) -I data

# Source files
ASM_SRCS = main.asm game.asm pieces.asm render.asm scores.asm
LIB_SRCS = $(LIBDIR)/init.asm $(LIBDIR)/input.asm $(LIBDIR)/dma.asm \
           $(LIBDIR)/ppu.asm $(LIBDIR)/math.asm $(LIBDIR)/spc700.asm

# Object files
ASM_OBJS = $(ASM_SRCS:.asm=.o)
LIB_OBJS = init.o input.o dma.o ppu.o math.o spc700.o

# Output
ROM = tetris.sfc

.PHONY: all clean

all: $(ROM)

# Link all objects into ROM
$(ROM): $(ASM_OBJS) $(LIB_OBJS)
	$(LD65) -C $(CFG) -o $@ $^

# Game source assembly
%.o: %.asm
	$(CA65) --cpu 65816 $(INCLUDES) -o $@ $<

# Library source assembly
init.o: $(LIBDIR)/init.asm
	$(CA65) --cpu 65816 -I $(LIBDIR) -o $@ $<

input.o: $(LIBDIR)/input.asm
	$(CA65) --cpu 65816 -I $(LIBDIR) -o $@ $<

dma.o: $(LIBDIR)/dma.asm
	$(CA65) --cpu 65816 -I $(LIBDIR) -o $@ $<

ppu.o: $(LIBDIR)/ppu.asm
	$(CA65) --cpu 65816 -I $(LIBDIR) -o $@ $<

math.o: $(LIBDIR)/math.asm
	$(CA65) --cpu 65816 -I $(LIBDIR) -o $@ $<

spc700.o: $(LIBDIR)/spc700.asm
	$(CA65) --cpu 65816 -I $(LIBDIR) -o $@ $<

clean:
	rm -f *.o $(ROM)

# =============================================================================
# Hello — Minimal ROM Template Build
# =============================================================================

CA65 = ca65
LD65 = ld65

ROOT     = ../..
CFG      = $(ROOT)/cfg/lorom256k.cfg
LIBDIR   = $(ROOT)/lib
INCLUDES = -I $(LIBDIR)

ROM = hello.sfc

.PHONY: all clean

all: $(ROM)

$(ROM): main.o init.o
	$(LD65) -C $(CFG) -o $@ $^

main.o: main.asm
	$(CA65) --cpu 65816 $(INCLUDES) -o $@ $<

init.o: $(LIBDIR)/init.asm
	$(CA65) --cpu 65816 -I $(LIBDIR) -o $@ $<

clean:
	rm -f *.o $(ROM)

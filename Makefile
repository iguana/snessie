# =============================================================================
# SNESser — Top-Level Makefile
# =============================================================================

.PHONY: all clean setup tetris hello

all: tetris hello

tetris:
	$(MAKE) -C games/tetris

hello:
	$(MAKE) -C templates/hello

clean:
	$(MAKE) -C games/tetris clean
	$(MAKE) -C templates/hello clean

setup:
	bash tools/setup.sh

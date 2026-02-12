#!/usr/bin/env bash
# =============================================================================
# setup.sh — Install dependencies for SNESser development
# =============================================================================
set -euo pipefail

echo "=== SNESser Development Setup ==="

# Check for Homebrew (macOS)
if command -v brew &>/dev/null; then
    # Install cc65 (provides ca65, ld65)
    if command -v ca65 &>/dev/null; then
        echo "[OK] ca65 found: $(ca65 --version 2>&1 | head -1)"
    else
        echo "[INSTALL] Installing cc65 via Homebrew..."
        brew install cc65
    fi
else
    # Check if ca65 is available anyway
    if command -v ca65 &>/dev/null; then
        echo "[OK] ca65 found: $(ca65 --version 2>&1 | head -1)"
    else
        echo "[ERROR] ca65 not found. Install cc65:"
        echo "  macOS:  brew install cc65"
        echo "  Ubuntu: sudo apt-get install cc65"
        echo "  Arch:   sudo pacman -S cc65"
        exit 1
    fi
fi

# Verify ld65
if command -v ld65 &>/dev/null; then
    echo "[OK] ld65 found: $(ld65 --version 2>&1 | head -1)"
else
    echo "[ERROR] ld65 not found (should be part of cc65 package)"
    exit 1
fi

# Check Python 3
if command -v python3 &>/dev/null; then
    echo "[OK] Python 3 found: $(python3 --version)"

    # Check for Pillow
    if python3 -c "import PIL" 2>/dev/null; then
        echo "[OK] Pillow (PIL) is installed"
    else
        echo "[INSTALL] Installing Pillow..."
        pip3 install Pillow
    fi
else
    echo "[WARN] Python 3 not found — png2snes.py graphics converter won't work"
    echo "  Install Python 3 for graphics conversion support"
fi

echo ""
echo "=== Setup Complete ==="
echo "Run 'make' to build all games."

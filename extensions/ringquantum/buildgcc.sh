#!/bin/bash
set -e

ROOT="$PWD/../.."
SRC="$PWD"
BIN_DIR="$ROOT/bin"

mkdir -p "$BIN_DIR"

echo "🏗 Building RingQuantum (GCC)..."

gcc -shared -o "$BIN_DIR/libring_quantum.so" -O3 -fPIC -fopenmp \
    ring_quantum.c \
    -I "$ROOT/language/include" \
    -L "$ROOT/lib" -lring -lm

echo "✅ RingQuantum built successfully!"
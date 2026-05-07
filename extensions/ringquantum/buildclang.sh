#!/bin/bash
set -e

# تحديد المسارات
ROOT="$PWD/../.."
BIN_DIR="$ROOT/bin"

mkdir -p "$BIN_DIR"

echo "🏗 Building RingQuantum (Clang)..."

clang -c -fPIC -O3 ring_quantum.c -I "$ROOT/language/include" -o ring_quantum.o
clang -dynamiclib -o "$BIN_DIR/libring_quantum.dylib" ring_quantum.o \
      -L "$ROOT/lib" -lring

rm ring_quantum.o

echo "✅ RingQuantum built successfully!"
#!/usr/bin/env bash
# Step 1b: Build example-beast using Conan (Boost with Beast).
# Run from repo root. Logs and timings go to evidence/step1-conan/.
# Requires: conan in PATH, cmake, g++

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE="${REPO_ROOT}/evidence/step1-conan"
mkdir -p "$EVIDENCE"
LOG="${EVIDENCE}/conan-build.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== Step 1b: Conan + Boost (Beast) (start: $(date -Iseconds)) ==="

cd "$REPO_ROOT/example-beast"
BUILD_DIR="$REPO_ROOT/example-beast/build-conan"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Ensure Conan default profile exists (required on first run)
if ! conan profile show default &>/dev/null; then
  echo "Creating default Conan profile (conan profile detect)..."
  conan profile detect
fi

echo "--- conan install (timed) ---"
start=$(date +%s.%N)
conan install . --output-folder="$BUILD_DIR" --build=missing
end=$(date +%s.%N)
echo "conan_install_seconds: $(echo "$end - $start" | bc)" | tee "${EVIDENCE}/timing.txt"

echo "--- CMake configure (timed) ---"
start=$(date +%s.%N)
cmake -B "$BUILD_DIR" -DCMAKE_TOOLCHAIN_FILE="$BUILD_DIR/conan_toolchain.cmake" -DCMAKE_BUILD_TYPE=Release
end=$(date +%s.%N)
echo "cmake_configure_seconds: $(echo "$end - $start" | bc)" >> "${EVIDENCE}/timing.txt"

echo "--- CMake build (timed) ---"
start=$(date +%s.%N)
cmake --build "$BUILD_DIR"
end=$(date +%s.%N)
echo "cmake_build_seconds: $(echo "$end - $start" | bc)" >> "${EVIDENCE}/timing.txt"

"$BUILD_DIR/example_beast"
echo "=== Step 1b end: $(date -Iseconds) ==="

#!/usr/bin/env bash
# Step 1a: Build example-beast using vcpkg (modular Boost.Beast).
# Run from repo root. Logs and timings go to evidence/step1-vcpkg/.
# Requires: vcpkg in PATH or VCPKG_ROOT set, cmake, g++

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE="${REPO_ROOT}/evidence/step1-vcpkg"
mkdir -p "$EVIDENCE"
LOG="${EVIDENCE}/vcpkg-build.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== Step 1a: vcpkg + Boost.Beast (start: $(date -Iseconds)) ==="

# Resolve vcpkg and toolchain path
if [[ -n "${VCPKG_ROOT}" ]]; then
  VCPKG="$VCPKG_ROOT/vcpkg"
  VCPKG_SCRIPT="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
elif [[ -x "$REPO_ROOT/vcpkg/vcpkg" ]]; then
  VCPKG_ROOT="$REPO_ROOT/vcpkg"
  VCPKG="$VCPKG_ROOT/vcpkg"
  VCPKG_SCRIPT="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
elif command -v vcpkg &>/dev/null; then
  VCPKG=vcpkg
  echo "vcpkg found in PATH; set VCPKG_ROOT to the vcpkg tree (containing scripts/buildsystems/vcpkg.cmake)"
  [[ -z "${VCPKG_ROOT}" ]] && { echo "VCPKG_ROOT not set. Aborting."; exit 1; }
  VCPKG_SCRIPT="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
else
  echo "vcpkg not found. Clone and bootstrap:"
  echo "  git clone https://github.com/microsoft/vcpkg.git $REPO_ROOT/vcpkg"
  echo "  $REPO_ROOT/vcpkg/bootstrap-vcpkg.sh"
  echo "  export VCPKG_ROOT=$REPO_ROOT/vcpkg"
  exit 1
fi

cd "$REPO_ROOT/example-beast"
BUILD_DIR="$REPO_ROOT/example-beast/build-vcpkg"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "--- vcpkg install (timed) ---"
start=$(date +%s.%N)
"$VCPKG" install --x-wait-for-lock
end=$(date +%s.%N)
echo "vcpkg_install_seconds: $(echo "$end - $start" | bc)" | tee "${EVIDENCE}/timing.txt"

echo "--- CMake configure (timed) ---"
start=$(date +%s.%N)
cmake -B "$BUILD_DIR" -DCMAKE_TOOLCHAIN_FILE="$VCPKG_SCRIPT"
end=$(date +%s.%N)
echo "cmake_configure_seconds: $(echo "$end - $start" | bc)" >> "${EVIDENCE}/timing.txt"

echo "--- CMake build (timed) ---"
start=$(date +%s.%N)
cmake --build "$BUILD_DIR"
end=$(date +%s.%N)
echo "cmake_build_seconds: $(echo "$end - $start" | bc)" >> "${EVIDENCE}/timing.txt"

"$BUILD_DIR/example_beast"
echo "=== Step 1a end: $(date -Iseconds) ==="

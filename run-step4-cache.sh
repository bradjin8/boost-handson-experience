#!/usr/bin/env bash
# Step 4: Build caching — build example_beast with ccache/sccache; cold build, then warm (incremental).
# Run from repo root. Logs and timings → evidence/step4-cache/.
# Requires: step 2 done (install-boost), cmake, g++; ccache or sccache (one of them)

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE="${REPO_ROOT}/evidence/step4-cache"
INSTALL_PREFIX="${REPO_ROOT}/install-boost"
BUILD_DIR="${REPO_ROOT}/example-beast/build-step4"
mkdir -p "$EVIDENCE"
LOG="${EVIDENCE}/cache.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== Step 4: Build caching (start: $(date -Iseconds)) ==="

if [[ ! -d "$INSTALL_PREFIX/include/boost" ]]; then
  echo "Error: install-boost not found. Run ./run-step2-source-build.sh first."
  exit 1
fi

# Prefer ccache, then sccache
CACHE_LAUNCHER=""
if command -v ccache &>/dev/null; then
  CACHE_LAUNCHER=ccache
  export CCACHE_DIR="${CCACHE_DIR:-$REPO_ROOT/.ccache}"
  mkdir -p "$CCACHE_DIR"
elif command -v sccache &>/dev/null; then
  CACHE_LAUNCHER=sccache
else
  echo "Error: ccache or sccache required. Install one (e.g. apt install ccache)."
  exit 1
fi
echo "Using compiler launcher: $CACHE_LAUNCHER"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Cold build (empty or fresh cache for this project)
echo "--- cold build with $CACHE_LAUNCHER (timed) ---"
start=$(date +%s.%N)
cmake -B "$BUILD_DIR" \
  -DCMAKE_CXX_COMPILER_LAUNCHER="$CACHE_LAUNCHER" \
  -DBoost_ROOT="$INSTALL_PREFIX" \
  -DBoost_NO_SYSTEM_PATHS=ON \
  -DCMAKE_BUILD_TYPE=Release \
  "$REPO_ROOT/example-beast"
cmake --build "$BUILD_DIR"
end=$(date +%s.%N)
cold_seconds=$(echo "$end - $start" | bc)
echo "cold_build_seconds: $cold_seconds" | tee "${EVIDENCE}/timing.txt"

# Touch a source file to force recompile
echo "--- touch source, warm build (timed) ---"
touch "$REPO_ROOT/example-beast/main.cpp"
start=$(date +%s.%N)
cmake --build "$BUILD_DIR"
end=$(date +%s.%N)
warm_seconds=$(echo "$end - $start" | bc)
echo "warm_build_seconds: $warm_seconds" >> "${EVIDENCE}/timing.txt"

# Cache stats
echo "--- cache stats ---"
if [[ "$CACHE_LAUNCHER" == ccache ]]; then
  ccache -s >> "${EVIDENCE}/cache-stats.txt" 2>&1 || true
  ccache -s
elif [[ "$CACHE_LAUNCHER" == sccache ]]; then
  sccache --show-stats >> "${EVIDENCE}/cache-stats.txt" 2>&1 || true
  sccache --show-stats
fi

echo "=== Step 4 end: $(date -Iseconds) ==="

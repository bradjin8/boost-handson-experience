#!/usr/bin/env bash
# Step 4: Build caching for the Boost library — add a space to a .h/.cpp under boost/beast, then b2 with ccache (cold, then warm).
# Requirement: test caching for Boost (not the example project) by modifying a file under boost/beast.
# Run from repo root. Logs and timings → evidence/step4-cache/.
# Requires: step 2 done (boost-src, b2), g++, ccache (or sccache)

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE="${REPO_ROOT}/evidence/step4-cache"
BOOST_SRC="${REPO_ROOT}/boost-src"
mkdir -p "$EVIDENCE"
LOG="${EVIDENCE}/cache.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== Step 4: Build caching for Boost library (start: $(date -Iseconds)) ==="

if [[ ! -d "$BOOST_SRC" ]] || [[ ! -x "$BOOST_SRC/b2" ]]; then
  echo "Error: boost-src or b2 not found. Run ./run-step2-source-build.sh first."
  exit 1
fi

# Same file as Step 3: a .h under boost/beast
BEAST_FILE="${BOOST_SRC}/libs/beast/include/boost/beast/core/string_param.hpp"
if [[ ! -f "$BEAST_FILE" ]]; then
  echo "Error: $BEAST_FILE not found."
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

# Add a space/comment to a .h under boost/beast (per requirement)
add_space_to_beast_file() {
  if ! grep -q "Step 4 cache build marker" "$BEAST_FILE" 2>/dev/null; then
    echo "" >> "$BEAST_FILE"
    echo "// Step 4 cache build marker" >> "$BEAST_FILE"
  fi
  touch "$BEAST_FILE"
}

# Wrapper so b2 invokes ccache g++ / ccache gcc
REAL_GXX=$(command -v g++)
REAL_GCC=$(command -v gcc)
CCACHE_BIN="${EVIDENCE}/ccache-bin"
mkdir -p "$CCACHE_BIN"
echo '#!/bin/sh
exec '"$CACHE_LAUNCHER"' '"$REAL_GXX"' "$@"' > "$CCACHE_BIN/g++"
echo '#!/bin/sh
exec '"$CACHE_LAUNCHER"' '"$REAL_GCC"' "$@"' > "$CCACHE_BIN/gcc"
chmod +x "$CCACHE_BIN/g++" "$CCACHE_BIN/gcc"
export PATH="${CCACHE_BIN}:${PATH}"

cd "$BOOST_SRC"

# Cold build: add space to beast file, run b2 with cache (first time)
echo "--- add space to boost/beast file, b2 headers with $CACHE_LAUNCHER — cold (timed) ---"
add_space_to_beast_file
start=$(date +%s.%N)
./b2 headers toolset=gcc -j$(nproc)
end=$(date +%s.%N)
cold_seconds=$(echo "$end - $start" | bc)
echo "cold_build_seconds: $cold_seconds" | tee "${EVIDENCE}/timing.txt"

# Warm build: add space again, run b2 (cache hits expected)
echo "--- add space again, b2 headers with $CACHE_LAUNCHER — warm (timed) ---"
add_space_to_beast_file
start=$(date +%s.%N)
./b2 headers toolset=gcc -j$(nproc)
end=$(date +%s.%N)
warm_seconds=$(echo "$end - $start" | bc)
echo "warm_build_seconds: $warm_seconds" >> "${EVIDENCE}/timing.txt"

# Cache stats
echo "--- cache stats ---"
if [[ "$CACHE_LAUNCHER" == ccache ]]; then
  ccache -s > "${EVIDENCE}/cache-stats.txt" 2>&1 || true
  ccache -s
elif [[ "$CACHE_LAUNCHER" == sccache ]]; then
  sccache --show-stats > "${EVIDENCE}/cache-stats.txt" 2>&1 || true
  sccache --show-stats
fi

echo "=== Step 4 end: $(date -Iseconds) ==="

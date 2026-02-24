#!/usr/bin/env bash
# Step 3: Incremental build — change one file in Boost.Beast, rebuild with GCC and Clang (b2).
# Runs WITHOUT cache and WITH cache (ccache), recording timings for both.
# Run from repo root. Requires step 2 done (boost-src, b2). Logs → evidence/step3-incremental/.
# Requires: g++, clang++ (optional), ccache (for "with cache" run)

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE="${REPO_ROOT}/evidence/step3-incremental"
BOOST_SRC="${REPO_ROOT}/boost-src"
mkdir -p "$EVIDENCE"
LOG="${EVIDENCE}/incremental.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== Step 3: Incremental build with/without cache (start: $(date -Iseconds)) ==="

if [[ ! -d "$BOOST_SRC" ]] || [[ ! -x "$BOOST_SRC/b2" ]]; then
  echo "Error: boost-src or b2 not found. Run ./run-step2-source-build.sh first."
  exit 1
fi

BEAST_FILE="${BOOST_SRC}/libs/beast/include/boost/beast/core/string_param.hpp"
if [[ ! -f "$BEAST_FILE" ]]; then
  echo "Error: $BEAST_FILE not found."
  exit 1
fi

# Ensure marker is present for incremental change
ensure_marker() {
  local marker="// Step 3 incremental build marker"
  if ! grep -q "Step 3 incremental build marker" "$BEAST_FILE" 2>/dev/null; then
    echo "$marker" >> "$BEAST_FILE"
  fi
}

# Touch file so b2 sees a change for next incremental run
touch_file() {
  touch "$BEAST_FILE"
}

cd "$BOOST_SRC"

# ---- Part A: WITHOUT cache ----
echo "--- Part A: Incremental build WITHOUT cache ---"
ensure_marker
touch_file

echo "--- b2 headers toolset=gcc, no cache (timed) ---"
start=$(date +%s.%N)
./b2 headers toolset=gcc -j$(nproc)
end=$(date +%s.%N)
gcc_no_cache=$(echo "$end - $start" | bc)
echo "b2_headers_gcc_no_cache_seconds: $gcc_no_cache" | tee "${EVIDENCE}/timing-without-cache.txt"

if command -v clang++ &>/dev/null; then
  echo "--- b2 headers toolset=clang, no cache (timed) ---"
  start=$(date +%s.%N)
  ./b2 headers toolset=clang -j$(nproc)
  end=$(date +%s.%N)
  clang_no_cache=$(echo "$end - $start" | bc)
  echo "b2_headers_clang_no_cache_seconds: $clang_no_cache" >> "${EVIDENCE}/timing-without-cache.txt"
else
  echo "clang++ not found; skipping clang (no cache)"
  echo "b2_headers_clang_no_cache_seconds: skipped" >> "${EVIDENCE}/timing-without-cache.txt"
fi

# ---- Part B: WITH cache (ccache) ----
if ! command -v ccache &>/dev/null; then
  echo "ccache not found; skipping Part B (with cache). Install with: apt install ccache"
  echo "b2_headers_gcc_with_cache_cold_seconds: skipped" | tee "${EVIDENCE}/timing-with-cache.txt"
  echo "b2_headers_gcc_with_cache_warm_seconds: skipped" >> "${EVIDENCE}/timing-with-cache.txt"
else
  echo "--- Part B: Incremental build WITH cache (ccache) ---"
  # Wrapper so b2 invokes ccache g++ / ccache gcc
  REAL_GXX=$(command -v g++)
  REAL_GCC=$(command -v gcc)
  CCACHE_BIN="${EVIDENCE}/ccache-bin"
  mkdir -p "$CCACHE_BIN"
  echo '#!/bin/sh
exec ccache '"$REAL_GXX"' "$@"' > "$CCACHE_BIN/g++"
  echo '#!/bin/sh
exec ccache '"$REAL_GCC"' "$@"' > "$CCACHE_BIN/gcc"
  chmod +x "$CCACHE_BIN/g++" "$CCACHE_BIN/gcc"
  export PATH="${CCACHE_BIN}:${PATH}"

  touch_file
  echo "--- b2 headers toolset=gcc, with ccache — cold (timed) ---"
  start=$(date +%s.%N)
  ./b2 headers toolset=gcc -j$(nproc)
  end=$(date +%s.%N)
  gcc_cold=$(echo "$end - $start" | bc)
  echo "b2_headers_gcc_with_cache_cold_seconds: $gcc_cold" | tee "${EVIDENCE}/timing-with-cache.txt"

  touch_file
  echo "--- b2 headers toolset=gcc, with ccache — warm (timed) ---"
  start=$(date +%s.%N)
  ./b2 headers toolset=gcc -j$(nproc)
  end=$(date +%s.%N)
  gcc_warm=$(echo "$end - $start" | bc)
  echo "b2_headers_gcc_with_cache_warm_seconds: $gcc_warm" >> "${EVIDENCE}/timing-with-cache.txt"

  ccache -s > "${EVIDENCE}/cache-stats.txt" 2>/dev/null || true
  echo "--- ccache stats written to ${EVIDENCE}/cache-stats.txt ---"
fi

# Backward compatibility: timing.txt with legacy keys (no-cache values)
{
  echo "b2_headers_gcc_seconds: $gcc_no_cache"
  if [[ -n "${clang_no_cache:-}" ]]; then echo "b2_headers_clang_seconds: $clang_no_cache"; else echo "b2_headers_clang_seconds: skipped"; fi
} > "${EVIDENCE}/timing.txt"

echo "=== Step 3 end: $(date -Iseconds) ==="

#!/usr/bin/env bash
# Step 3: Incremental build — change one file in Boost.Beast, rebuild with GCC and Clang (b2).
# Run from repo root. Requires step 2 done (boost-src, b2). Logs → evidence/step3-incremental/.
# Requires: g++, clang++ (optional; step skips clang if not found)

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE="${REPO_ROOT}/evidence/step3-incremental"
BOOST_SRC="${REPO_ROOT}/boost-src"
mkdir -p "$EVIDENCE"
LOG="${EVIDENCE}/incremental.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== Step 3: Incremental build (start: $(date -Iseconds)) ==="

if [[ ! -d "$BOOST_SRC" ]] || [[ ! -x "$BOOST_SRC/b2" ]]; then
  echo "Error: boost-src or b2 not found. Run ./run-step2-source-build.sh first."
  exit 1
fi

# File to touch/edit in Boost.Beast (used by b2 headers)
BEAST_FILE="${BOOST_SRC}/libs/beast/include/boost/beast/core/string_param.hpp"
if [[ ! -f "$BEAST_FILE" ]]; then
  echo "Error: $BEAST_FILE not found."
  exit 1
fi

# 1. Make a small change in Boost.Beast (add comment for step 3)
echo "--- modify one file in Boost.Beast ---"
MARKER="// Step 3 incremental build marker"
if ! grep -q "Step 3 incremental build marker" "$BEAST_FILE" 2>/dev/null; then
  echo "$MARKER" >> "$BEAST_FILE"
fi

cd "$BOOST_SRC"

# 2. Rebuild headers with GCC
echo "--- b2 headers toolset=gcc (timed) ---"
start=$(date +%s.%N)
./b2 headers toolset=gcc -j$(nproc)
end=$(date +%s.%N)
echo "b2_headers_gcc_seconds: $(echo "$end - $start" | bc)" | tee "${EVIDENCE}/timing.txt"

# 3. Rebuild headers with Clang (if available)
if command -v clang++ &>/dev/null; then
  echo "--- b2 headers toolset=clang (timed) ---"
  start=$(date +%s.%N)
  ./b2 headers toolset=clang -j$(nproc)
  end=$(date +%s.%N)
  echo "b2_headers_clang_seconds: $(echo "$end - $start" | bc)" >> "${EVIDENCE}/timing.txt"
else
  echo "clang++ not found; skipping b2 toolset=clang"
  echo "b2_headers_clang_seconds: skipped" >> "${EVIDENCE}/timing.txt"
fi

echo "=== Step 3 end: $(date -Iseconds) ==="

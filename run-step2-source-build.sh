#!/usr/bin/env bash
# Step 2: Full Boost build from source (clone, bootstrap, b2 build, install).
# Run from repo root. Logs and timings go to evidence/step2-source-build/.
# Requires: git, python3, g++, build-essential (bootstrap needs gcc, make)

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EVIDENCE="${REPO_ROOT}/evidence/step2-source-build"
BOOST_SRC="${REPO_ROOT}/boost-src"
INSTALL_PREFIX="${REPO_ROOT}/install-boost"
mkdir -p "$EVIDENCE"
LOG="${EVIDENCE}/source-build.log"
exec > >(tee -a "$LOG") 2>&1

echo "=== Step 2: Full Boost build from source (start: $(date -Iseconds)) ==="

# 0. Record resource allocation (CPUs, RAM, disk) for the report
{
  echo "Resource allocation (captured at step start)"
  echo "CPUs (nproc): $(nproc)"
  echo "Memory (free -h):"
  free -h
  echo "Disk (df -h for repo root):"
  df -h "$REPO_ROOT"
} > "${EVIDENCE}/resource.txt" 2>&1
echo "--- resource allocation written to ${EVIDENCE}/resource.txt ---"

# 1. Clone Boost (modular: boostdep + beast deps)
if [[ ! -d "$BOOST_SRC" ]] || [[ ! -f "$BOOST_SRC/bootstrap.sh" ]]; then
  echo "--- git clone Boost (timed) ---"
  start=$(date +%s.%N)
  if [[ ! -d "$BOOST_SRC" ]]; then
    git clone https://github.com/boostorg/boost.git "$BOOST_SRC"
  fi
  cd "$BOOST_SRC"
  git submodule update --init tools/build
  git submodule update --init tools/boostdep
  if [[ -f tools/boostdep/depinst/depinst.py ]]; then
    python3 tools/boostdep/depinst/depinst.py beast
  elif [[ -f tools/boostdep/depinst.py ]]; then
    python3 tools/boostdep/depinst.py beast
  else
    echo "boostdep not found; initializing beast submodule manually"
    git submodule update --init libs/beast libs/asio libs/core libs/system libs/config libs/headers
  fi
  git submodule update --init
  end=$(date +%s.%N)
  echo "clone_seconds: $(echo "$end - $start" | bc)" | tee "${EVIDENCE}/timing.txt"
  cd "$REPO_ROOT"
else
  echo "Boost source already at $BOOST_SRC, skipping clone"
  echo "clone_seconds: 0" | tee "${EVIDENCE}/timing.txt"
fi

cd "$BOOST_SRC"

# 2. Bootstrap
echo "--- bootstrap (timed) ---"
start=$(date +%s.%N)
./bootstrap.sh --prefix="$INSTALL_PREFIX"
end=$(date +%s.%N)
echo "bootstrap_seconds: $(echo "$end - $start" | bc)" | tee -a "${EVIDENCE}/timing.txt"

# 3. Full Boost build and install (all buildable libraries + headers; can take 30+ min)
echo "--- b2 install (full build, timed) ---"
start=$(date +%s.%N)
./b2 install --prefix="$INSTALL_PREFIX" -j$(nproc)
end=$(date +%s.%N)
echo "b2_install_seconds: $(echo "$end - $start" | bc)" | tee -a "${EVIDENCE}/timing.txt"

cd "$REPO_ROOT"

# 5. Build and run example using installed Boost
echo "--- build example_beast against installed Boost (timed) ---"
BUILD_DIR="${REPO_ROOT}/example-beast/build-step2"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
start=$(date +%s.%N)
cmake -B "$BUILD_DIR" \
  -DBoost_ROOT="$INSTALL_PREFIX" \
  -DBoost_NO_SYSTEM_PATHS=ON \
  -DCMAKE_BUILD_TYPE=Release \
  "$REPO_ROOT/example-beast"
cmake --build "$BUILD_DIR"
end=$(date +%s.%N)
echo "example_build_seconds: $(echo "$end - $start" | bc)" | tee -a "${EVIDENCE}/timing.txt"

echo "--- run example_beast ---"
"$BUILD_DIR/example_beast"

echo "=== Step 2 end: $(date -Iseconds) ==="

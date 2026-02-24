#!/usr/bin/env bash
# Remove Step 2 build outputs so you can run a clean full Boost build.
# Keeps boost-src/ (and b2) so clone/bootstrap are skipped on next run.
# Run from repo root.

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "Removing Step 2 build outputs..."
rm -rf install-boost
rm -rf example-beast/build-step2
if [[ -d "boost-src" ]]; then
  rm -rf boost-src/bin.v2
  rm -rf boost-src/stage
  echo "  install-boost, example-beast/build-step2, boost-src/bin.v2, boost-src/stage removed."
else
  echo "  install-boost, example-beast/build-step2 removed (no boost-src)."
fi
echo "Done. Run ./run-step2-source-build.sh for a clean full build."

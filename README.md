# Boost hands-on experience (team-brain issue #8)

Hands-on tasks: modular Boost (vcpkg/conan), full source build, incremental build, build caching.  
Platform: **Linux, b2 (Boost.Build), GCC, LLVM/Clang.**

## Layout

- **`example-beast/`** — C++ example using Boost.Beast (for vcpkg and Conan).
- **`report/`** — Final written report (2–3 pages + appendix).
- **`evidence/`** — Timings and logs per step:
  - `step1-vcpkg/` — vcpkg install + build logs
  - `step1-conan/` — Conan install + build logs
  - `step2-source-build/` — Full Boost clone/build/install
  - `step3-incremental/` — Incremental rebuild (GCC, Clang)
  - `step4-cache/` — ccache/sccache runs

## Step 1: Modular Boost (package managers)

Do this **before** building Boost from source.

1. **vcpkg**  
   - From repo root: `./run-step1-vcpkg.sh`  
   - Requires: vcpkg (clone + bootstrap, or `VCPKG_ROOT` set).

2. **Conan**  
   - From repo root: `./run-step1-conan.sh`  
   - Requires: Conan 2 (`pip install conan` or system package).

Evidence: `evidence/step1-vcpkg/` and `evidence/step1-conan/` (logs + `timing.txt`).

## Step 2: Full build from source

- From repo root: `./run-step2-source-build.sh`
- Clone Boost (modular via boostdep), bootstrap, b2 build, install.
- Build and run example_beast against installed Boost.
- Requires: git, python3, g++, build-essential.
- Logs and timings → `evidence/step2-source-build/`.

**Clear built outputs (for a clean full rebuild):**  
`./clean-step2.sh` — removes `install-boost/`, `example-beast/build-step2/`, and `boost-src/bin.v2/`, `boost-src/stage/`. Keeps `boost-src/` so the next run skips clone and only re-runs bootstrap + b2 install.

## Step 3: Incremental build of Boost (with/without cache)

- From repo root: `./run-step3-incremental.sh`
- **Requirement:** Test incremental build for the **Boost library** (not the example project) by adding a space to a .h/.cpp under `boost/beast`. Script adds a comment/marker to `libs/beast/include/boost/beast/core/string_param.hpp`, then runs `b2 headers` with GCC and (if available) Clang.
- **Part A:** incremental build **without** cache → `timing-without-cache.txt`.
- **Part B:** incremental build **with** ccache (cold then warm) → `timing-with-cache.txt`, `cache-stats.txt`.
- Requires: step 2 done (`boost-src`), g++; clang++ optional; ccache for Part B (e.g. `apt install ccache`).
- Logs → `evidence/step3-incremental/`.

## Step 4: Build caching for Boost

- From repo root: `./run-step4-cache.sh`
- **Requirement:** Test caching for the **Boost library** (not the example project) by adding a space to a .h/.cpp under `boost/beast`. Script adds a marker to the same Beast header, then runs `b2 headers` with ccache/sccache: cold build, then add space again + warm build; writes cache stats.
- Requires: step 2 done (`boost-src`, b2), g++; ccache or sccache (e.g. `apt install ccache`).
- Logs → `evidence/step4-cache/`.

## Report

- Main body (2–3 pages) + appendix (evidence) in `report/`.
- Time every step, log output, note what worked, what broke, and mitigations.

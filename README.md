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

## Step 3: Incremental build

- Change one `.h`/`.cpp` in Boost.Beast.
- Rebuild with GCC and with LLVM/Clang (b2).
- Logs → `evidence/step3-incremental/`.

## Step 4: Build caching

- Use ccache or sccache for incremental build.
- Logs → `evidence/step4-cache/`.

## Report

- Main body (2–3 pages) + appendix (evidence) in `report/`.
- Time every step, log output, note what worked, what broke, and mitigations.

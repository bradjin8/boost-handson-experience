# Boost Hands-On Experience — Acceptance Report

**Project:** Boost hands-on experience (team-brain issue #8)  
**Platform:** Linux, b2 (Boost.Build), GCC, LLVM/Clang  
**Report date:** 2026-02  

---

## Acceptance criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | Step 1a: Modular Boost via **vcpkg** — install + build + run example_beast | ✅ Met | `evidence/step1-vcpkg/` |
| 2 | Step 1b: Modular Boost via **Conan** — install + build + run example_beast | ✅ Met | `evidence/step1-conan/` |
| 3 | Step 2: **Full build from source** — clone Boost, bootstrap, b2, install, build example against install | ✅ Met | `evidence/step2-source-build/` |
| 4 | Step 3: **Incremental build** — change one file in Beast, rebuild with GCC and Clang (b2) | ✅ Met | `evidence/step3-incremental/` |
| 5 | Step 4: **Build caching** — use ccache or sccache for cold + warm incremental build | ✅ Met | `evidence/step4-cache/` |

**Overall:** All acceptance criteria met.

---

## Summary

All five hands-on tasks were completed on Linux. The example project (`example-beast`) builds and runs with vcpkg, Conan, and with a full Boost source install. Incremental rebuilds were timed with GCC and Clang; build caching (ccache) was exercised with cold and warm builds.

---

## Step results and timings

### Step 1a — vcpkg

- **Script:** `./run-step1-vcpkg.sh`
- **Requirement:** vcpkg installed and `VCPKG_ROOT` exported.
- **Result:** example_beast built and ran (e.g. "Boost.Beast version: 359").
- **Timings (from `evidence/step1-vcpkg/timing.txt`):**
  - vcpkg install: 877.4 s
  - CMake configure: 13.1 s
  - CMake build: 1.8 s

### Step 1b — Conan

- **Script:** `./run-step1-conan.sh`
- **Result:** example_beast built and ran.
- **Timings (from `evidence/step1-conan/timing.txt`):**
  - conan install: 6069.0 s
  - CMake configure: 3.0 s
  - CMake build: 1.8 s

### Step 2 — Full build from source

- **Script:** `./run-step2-source-build.sh`
- **Process:** Clone Boost (or reuse), bootstrap, **full b2 build** (`b2 install` — all ~160 libraries, headers + compiled .cpp), then build example_beast against `install-boost/`. Resource allocation (CPUs, RAM, disk) → `resource.txt`, `resource-allocation.md`.
- **Result:** Full Boost installed (libs + headers); example_beast built and ran. Cold baseline and incremental runs both documented.
- **Timings:**
  - **Cold build** (`timing-without-cache.txt`): clone 0 s, bootstrap 27.5 s, b2_install 240.1 s (~4 min), example 1.6 s.
  - **With existing build** (`timing.txt`): clone 0 s, bootstrap 25.4 s, b2_install 39.5 s, example 1.7 s.
- **Resource:** 4 CPUs, 5.9 Gi RAM, 98 G disk (see `evidence/step2-source-build/resource-allocation.md`).

### Step 3 — Incremental build of Boost (with/without cache)

- **Script:** `./run-step3-incremental.sh`
- **Requirement:** Test incremental build for the **Boost library** (not the example project) by adding a space to a .h/.cpp under `boost/beast`. **Process:** Add space/comment to `libs/beast/.../string_param.hpp`, then **full b2 build** (`b2 toolset=gcc` / `b2 toolset=clang`, no `headers` target). **Part A:** without cache. **Part B:** with ccache (cold then warm).
- **Result:** No-cache and with-cache runs completed.
- **Timings (from evidence):** Without cache: GCC 18.2 s, Clang 177.5 s. With cache: cold 20.2 s, warm 18.9 s. Files: `timing-without-cache.txt`, `timing-with-cache.txt`, `timing.txt`.

### Step 4 — Build caching for Boost

- **Script:** `./run-step4-cache.sh`
- **Requirement:** Test caching for the **Boost library** (not the example project) by adding a space to a .h/.cpp under `boost/beast`. **Process:** Add space/comment to the same Beast header, then `b2 headers` with ccache/sccache (cold, then add space again + warm); cache stats captured.
- **Result:** Cold and warm builds of Boost (b2) completed.
- **Timings (from `evidence/step4-cache/timing.txt`):** cold 2.34 s, warm 2.18 s.

---

## What worked

- vcpkg and Conan both provided Boost.Beast and produced a working example_beast.
- Full source workflow: clone (or reuse), bootstrap, full `b2 install` (all ~160 Boost libraries), example build against install. Cold vs incremental timings in `timing-without-cache.txt` and `timing.txt`; resource allocation in `resource-allocation.md`.
- Step 3 & 4: Incremental build and caching both test the **Boost library** (add a space to a .h under boost/beast, then b2 with/without ccache). Not the example project.
- Scripts (`run-step1-vcpkg.sh`, `run-step1-conan.sh`, `run-step2-source-build.sh`, `run-step3-incremental.sh`, `run-step4-cache.sh`) run from repo root and write logs/timings under `evidence/`.

---

## Issues and mitigations

| Issue | Mitigation |
|-------|------------|
| vcpkg required `VCPKG_ROOT` in child processes | Export `VCPKG_ROOT` in `.bashrc` (e.g. `export VCPKG_ROOT=~/vcpkg-...`) |
| vcpkg baseline "2024.12.12" not a valid commit SHA | Use 40-char commit SHA in `vcpkg.json` (e.g. for 2026.01.16) |
| b2 `--with-beast` / `--with-system` invalid (Beast header-only; system not a buildable lib in this layout) | Use `b2 install` for full build (all libraries + headers) |
| Step 3: full b2 build (no `headers` target) | Script runs `b2 toolset=gcc` / `b2 toolset=clang` (full build); demonstrates toolset and change-then-rebuild |

---

## Appendix — Evidence layout

| Step | Directory | Main files |
|------|-----------|------------|
| 1a vcpkg | `evidence/step1-vcpkg/` | `vcpkg-build.log`, `timing.txt` |
| 1b Conan | `evidence/step1-conan/` | `conan-build.log`, `timing.txt` |
| 2 Source build | `evidence/step2-source-build/` | `source-build.log`, `timing.txt`, `timing-without-cache.txt`, `resource.txt`, `resource-allocation.md` |
| 3 Incremental | `evidence/step3-incremental/` | `incremental.log`, `timing.txt`, `timing-without-cache.txt`, `timing-with-cache.txt`, `cache-stats.txt` |
| 4 Cache | `evidence/step4-cache/` | `cache.log`, `timing.txt`, `cache-stats.txt` |

All timings and logs are under `evidence/` as specified in the project README.

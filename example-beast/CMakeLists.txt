# Minimal C++ project using Boost.Beast (for vcpkg or Conan)
cmake_minimum_required(VERSION 3.16)
project(example_beast CXX)

set(CMAKE_CXX_STANDARD 17)

# --- Option A: vcpkg (when CMAKE_TOOLCHAIN_FILE is set)
#     e.g. cmake -DCMAKE_TOOLCHAIN_FILE=/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake ..
# --- Option B: Conan (when using conan_toolchain or Conan provided targets)
#     e.g. conan install . --output-folder=build --build=missing
#          cmake --preset conan_release (or use -DCMAKE_TOOLCHAIN_FILE=build/conan_toolchain.cmake)

# vcpkg provides Boost; Conan 2 provides boost (lowercase)
find_package(Boost 1.70 QUIET)
if(Boost_FOUND)
  set(BEAST_INCLUDE_TARGET Boost::headers)
else()
  find_package(boost REQUIRED)
  set(BEAST_INCLUDE_TARGET boost::headers)
endif()

add_executable(example_beast main.cpp)
target_link_libraries(example_beast PRIVATE ${BEAST_INCLUDE_TARGET})

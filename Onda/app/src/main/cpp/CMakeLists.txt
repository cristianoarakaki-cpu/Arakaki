cmake_minimum_required(VERSION 3.22.1)
project(onda_mp3 C CXX)
include(FetchContent)
# Unmodified LAME source, pinned to its exact upstream commit; sources accompany the APK.
FetchContent_Declare(lame URL https://github.com/lameproject/lame/archive/1f5cc9487284d5950343aa5d4f70de433468070a.tar.gz)
FetchContent_GetProperties(lame)
if(NOT lame_POPULATED)
 FetchContent_Populate(lame)
endif()
file(GLOB LAME_SOURCES "${lame_SOURCE_DIR}/libmp3lame/*.c")
add_library(onda_mp3 SHARED mp3_jni.c ${LAME_SOURCES})
target_include_directories(onda_mp3 PRIVATE . "${lame_SOURCE_DIR}/include" "${lame_SOURCE_DIR}/libmp3lame" "${lame_SOURCE_DIR}")
target_compile_definitions(onda_mp3 PRIVATE HAVE_CONFIG_H=1)
target_compile_options(onda_mp3 PRIVATE -O2 -fvisibility=hidden)
target_link_options(onda_mp3 PRIVATE "-Wl,-z,max-page-size=16384")
target_link_libraries(onda_mp3 m)

# Recognition is loaded only when the user enables live translation. Model files
# are optional verified downloads, never part of the baseline APK.
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER OFF CACHE BOOL "" FORCE)
set(GGML_NATIVE OFF CACHE BOOL "" FORCE)
set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
set(GGML_METAL OFF CACHE BOOL "" FORCE)
set(GGML_CUDA OFF CACHE BOOL "" FORCE)
set(GGML_VULKAN OFF CACHE BOOL "" FORCE)
set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
FetchContent_Declare(whisper URL https://github.com/ggml-org/whisper.cpp/archive/a8d002cfd879315632a579e73f0148d06959de36.tar.gz URL_HASH SHA256=7b17da903114ed45d82f48c030e3be6a5a8a279f884b2f733706dbb4e832fb6b)
FetchContent_MakeAvailable(whisper)
# Distribution uses the existing signed debug variant; inference must still be
# optimized, instead of spending battery in NDK Debug/-O0 kernels.
foreach(onda_live_target whisper ggml-base ggml-cpu ggml)
 if(TARGET ${onda_live_target})
  target_compile_options(${onda_live_target} PRIVATE -O3)
 endif()
endforeach()
add_library(onda_whisper SHARED whisper_jni.cpp)
target_include_directories(onda_whisper PRIVATE "${whisper_SOURCE_DIR}/include" "${whisper_SOURCE_DIR}/ggml/include")
target_compile_options(onda_whisper PRIVATE -fvisibility=hidden)
target_link_options(onda_whisper PRIVATE "-Wl,-z,max-page-size=16384" "-Wl,--exclude-libs,ALL")
target_link_libraries(onda_whisper whisper log)

# Separate build prevents the optional chat runtime's ggml revision from
# replacing/interposing the already shipped Whisper ggml implementation.
include(ExternalProject)
FetchContent_Declare(onda_llama_source URL https://github.com/ggml-org/llama.cpp/archive/5fce5f948df8f189a5401a8ecaa9753106e75abb.tar.gz URL_HASH SHA256=6f3d91375567c0540f3b4ded5edd267e0dd306c3b7ab86eb7edc77d875025189)
FetchContent_GetProperties(onda_llama_source)
if(NOT onda_llama_source_POPULATED)
 FetchContent_Populate(onda_llama_source)
endif()
set(ONDA_LLAMA_BUILD "${CMAKE_CURRENT_BINARY_DIR}/onda-ai-core")
set(ONDA_LLAMA_LIBS "${ONDA_LLAMA_BUILD}/src/libllama.a" "${ONDA_LLAMA_BUILD}/ggml/src/libggml.a" "${ONDA_LLAMA_BUILD}/ggml/src/libggml-cpu.a" "${ONDA_LLAMA_BUILD}/ggml/src/libggml-base.a")
ExternalProject_Add(onda_ai_core
 SOURCE_DIR "${onda_llama_source_SOURCE_DIR}"
 BINARY_DIR "${ONDA_LLAMA_BUILD}"
 DOWNLOAD_COMMAND ""
 CMAKE_ARGS "-DCMAKE_TOOLCHAIN_FILE=${CMAKE_TOOLCHAIN_FILE}" "-DANDROID_ABI=${ANDROID_ABI}" "-DANDROID_PLATFORM=android-26" "-DCMAKE_BUILD_TYPE=Release" "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" "-DCMAKE_MAKE_PROGRAM=${CMAKE_MAKE_PROGRAM}" "-DBUILD_SHARED_LIBS=OFF" "-DGGML_NATIVE=OFF" "-DGGML_OPENMP=OFF" "-DGGML_VULKAN=OFF" "-DGGML_CUDA=OFF" "-DGGML_METAL=OFF" "-DLLAMA_CURL=OFF" "-DLLAMA_BUILD_COMMON=OFF" "-DLLAMA_BUILD_TESTS=OFF" "-DLLAMA_BUILD_TOOLS=OFF" "-DLLAMA_BUILD_EXAMPLES=OFF" "-DLLAMA_BUILD_SERVER=OFF"
 BUILD_COMMAND "${CMAKE_COMMAND}" --build <BINARY_DIR> --target llama --parallel 2
 INSTALL_COMMAND ""
 BUILD_BYPRODUCTS ${ONDA_LLAMA_LIBS})
add_library(onda_ai SHARED ai_jni.cpp)
add_dependencies(onda_ai onda_ai_core)
target_include_directories(onda_ai PRIVATE "${onda_llama_source_SOURCE_DIR}/include" "${onda_llama_source_SOURCE_DIR}/ggml/include")
target_compile_options(onda_ai PRIVATE -O3 -fvisibility=hidden)
target_link_options(onda_ai PRIVATE "-Wl,-z,max-page-size=16384" "-Wl,--exclude-libs,ALL" "-Wl,-Bsymbolic")
target_link_libraries(onda_ai "-Wl,--start-group" ${ONDA_LLAMA_LIBS} "-Wl,--end-group" log m atomic dl)

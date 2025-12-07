cmake_minimum_required(VERSION 3.15)
project(wwfx_wasm)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Emscripten toolchain
if(EMSCRIPTEN)
    set(CMAKE_EXECUTABLE_SUFFIX ".js")
    
    # Compiler flags for WASM
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O3 -s WASM=1 -s ALLOW_MEMORY_GROWTH=1")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s EXPORTED_RUNTIME_METHODS=['ccall','cwrap','UTF8ToString','stringToUTF8']")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s EXPORTED_FUNCTIONS=['_malloc','_free']")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s MODULARIZE=1 -s EXPORT_NAME='createWasmModule'")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -s USE_PTHREADS=0")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --bind")
    
    # Enable SIMD if available
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -msimd128")
endif()

# Source files
set(SOURCES
    src/filters.cpp
    src/image_processing.cpp
    src/wasm_bindings.cpp
)

# Header files
set(HEADERS
    include/filters.h
    include/image_processing.h
)

# Create library
add_library(wwfx_wasm STATIC ${SOURCES} ${HEADERS})

# Include directories
target_include_directories(wwfx_wasm PUBLIC include)

# For Emscripten, create a module
if(EMSCRIPTEN)
    add_executable(wwfx_module ${SOURCES})
    target_link_options(wwfx_module PRIVATE
        "SHELL:-s EXPORTED_RUNTIME_METHODS=['ccall','cwrap','UTF8ToString','stringToUTF8']"
        "SHELL:-s EXPORTED_FUNCTIONS=['_malloc','_free']"
        "SHELL:-s MODULARIZE=1"
        "SHELL:-s EXPORT_NAME='createWasmModule'"
        "SHELL:-s ALLOW_MEMORY_GROWTH=1"
        "SHELL:--bind"
    )
endif()


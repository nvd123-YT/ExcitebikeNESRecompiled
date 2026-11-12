cmake_minimum_required(VERSION 3.20)
project(ExcitebikeRecomp C CXX)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(NESRECOMP_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/nesrecomp" CACHE PATH
    "Path to the NESRecomp framework checkout")
set(NESRECOMP_RECOMP_UI "${CMAKE_CURRENT_SOURCE_DIR}/recomp-ui" CACHE STRING
    "Path to the shared recomp-ui checkout")
set(NESRECOMP_ROM "" CACHE FILEPATH
    "User-supplied Excitebike ROM used for local native code generation")

if(NOT EXISTS "${NESRECOMP_ROOT}/runner/cyc/project.cmake")
    message(FATAL_ERROR
        "NESRecomp submodule is missing. Run: git submodule update --init --recursive")
endif()
if(NOT EXISTS "${NESRECOMP_RECOMP_UI}/recomp_ui.cmake")
    message(FATAL_ERROR
        "recomp-ui submodule is missing. Run: git submodule update --init --recursive")
endif()
if(NOT EXISTS "${NESRECOMP_ROM}")
    message(FATAL_ERROR
        "A local Excitebike ROM is required. Configure with -DNESRECOMP_ROM=/absolute/path/to/Excitebike.nes. ROMs are not distributed.")
endif()
if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/game.toml")
    message(FATAL_ERROR "game.toml is missing.")
endif()

# Include at file scope: this enables the C++ language needed by recomp-ui.
include("${NESRECOMP_ROOT}/runner/cyc/project.cmake")

nesrecomp_add_cycle_game(ExcitebikeRecomp
    ROM "${NESRECOMP_ROM}"
    GAME_CONFIG "${CMAKE_CURRENT_SOURCE_DIR}/game.toml"
)

# Fail closed: a source-only project must not silently build without the
# graphical SDL2 host or the pre-boot/in-game recomp-ui integration.
get_target_property(_excitebike_sdl ExcitebikeRecomp NESRECOMP_CYC_SDL)
if(NOT _excitebike_sdl)
    message(FATAL_ERROR
        "SDL2 was not found. Install SDL2 development files and set CMAKE_PREFIX_PATH or SDL2_DIR.")
endif()
if(NOT NESRECOMP_CYC_RECOMP_UI_ROOT)
    message(FATAL_ERROR
        "The checked-out recomp-ui revision is missing required NES cycle-host integration features.")
endif()

message(STATUS "Excitebike: SDL2 desktop runner enabled")
message(STATUS "Excitebike: recomp-ui enabled from ${NESRECOMP_CYC_RECOMP_UI_ROOT}")
message(STATUS "Excitebike: ROM-derived native code will remain in the local build directory")

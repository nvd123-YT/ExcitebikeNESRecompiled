# ExcitebikeNESRecompiled

A local-build static recompilation project for **Excitebike (NES)** using [NESRecomp](https://github.com/mstan/nesrecomp) and its shared [recomp-ui](https://github.com/RetroPortingToolKit/recomp-ui) launcher.

> **Bring your own ROM.** This repository does not contain the Excitebike ROM, ROM-derived generated C files, or a prebuilt game executable. You must supply a compatible ROM that you are legally entitled to use. Native game code is generated locally during CMake configuration and remains in your local build directory.

## What recomp-ui does (and does not do)

The shared launcher provides a pre-boot ROM picker, controller/input settings, display/audio settings, and the NESRecomp in-game menu. It lets you browse to your local ROM and remembers the selection.

The picker is **not** a generic ROM-to-native-code converter. This title must first be recompiled locally from the ROM you supply. At launch, the runner verifies that the selected ROM matches the cartridge and PRG data used for that local build. Selecting a different revision is rejected; reconfigure and rebuild with that revision only if it is supported by this project.

## Requirements

- Git (with submodule support)
- CMake 3.20+
- Python 3.11+
- A C11/C++17 toolchain
- Ninja (recommended; Visual Studio generator is also supported)
- SDL 2.0.17+ development package and OpenGL development files
- A compatible Excitebike `.nes` ROM, supplied locally

On macOS, SDL2 can be installed through Homebrew or a user-local CMake installation. On Linux, install your distribution's SDL2 and OpenGL development packages. On Windows, use an SDL2 CMake package (for example, vcpkg).

## Setup

Clone with submodules:

```bash
git clone --recurse-submodules https://github.com/nvd123-YT/ExcitebikeNESRecompiled.git
cd ExcitebikeNESRecompiled
```

Or initialize dependencies after cloning:

```bash
git submodule update --init --recursive
```

The submodules are pinned to specific upstream commits in this repository.

## Build

### macOS / Linux

```bash
cmake -S . -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DNESRECOMP_ROM="/absolute/path/to/Excitebike.nes"
cmake --build build --parallel 4
```

If SDL2 is installed in a custom prefix, add `-DCMAKE_PREFIX_PATH="/path/to/SDL2"` to the configure command. For example, the user-local install used during development is `$HOME/Tools/SDL2`.

Run the executable with the **same ROM** used during configuration:

```bash
./build/ExcitebikeRecomp "/absolute/path/to/Excitebike.nes"
```

### Windows (Visual Studio 2022)

```powershell
cmake -S . -B build -G "Visual Studio 17 2022" -A x64 `
  -DNESRECOMP_ROM="C:/Games/Excitebike.nes" `
  -DCMAKE_TOOLCHAIN_FILE="C:/path/to/vcpkg/scripts/buildsystems/vcpkg.cmake"
cmake --build build --config Release --parallel 4
```

Run `build/Release/ExcitebikeRecomp.exe` with the same ROM path. Ensure vcpkg has installed `sdl2:x64-windows`.

## Development status

- Native cycle-backend generation and headless execution tested locally.
- SDL2 desktop runner tested on Apple Silicon macOS.
- recomp-ui integration is included as a pinned dependency; the cross-platform CI smoke test builds against a synthetic NROM test cartridge, never the Excitebike game.
- Windows and Linux game behavior still requires independent testing with a compatible ROM.

## GitHub Actions and releases

Every successful push to `main` runs build/integration smoke tests on macOS ARM64, Windows x64, and Linux x64. After all three pass, the workflow creates a **new, uniquely tagged source release** for that push. Existing releases and their assets are never replaced.

Because this is the source-only distribution mode, automated releases contain project source/configuration only—not playable Excitebike binaries. CI uses a synthetic test cartridge and does not build or upload Excitebike-derived code. To play the game, build locally with your own ROM as described above.

## Project contents

- `CMakeLists.txt` — NESRecomp cycle-runtime and recomp-ui integration.
- `game.toml` — Excitebike recompilation settings.
- `nesrecomp/` — pinned NESRecomp framework submodule.
- `recomp-ui/` — pinned shared launcher/in-game UI submodule.
- `.github/workflows/source-release.yml` — three-platform integration smoke tests and unique source releases.

No ROMs, generated game code, saves, local configuration, or build products belong in this repository.

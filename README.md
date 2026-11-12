# ExcitebikeNESRecompiled

A local-build static recompilation project for **Excitebike (NES)** using [NESRecomp](https://github.com/mstan/nesrecomp), the shared [recomp-ui](https://github.com/RetroPortingToolKit/recomp-ui) launcher, and a pinned SDL2 source dependency.

> **Bring your own ROM.** This repository and its source releases do not contain the Excitebike ROM, ROM-derived generated C source, or a playable game executable. Supply a compatible ROM that you are legally entitled to use. Native game code is generated locally during CMake configuration and stays in your local build directory.

## What is included

The repository pins the complete source trees for NESRecomp, recomp-ui, and SDL2 as Git submodules. The setup scripts also download portable, checksum-verified CMake and a managed Python 3.12 runtime into the local, ignored `.tools/` directory.

The build links SDL2 statically from the pinned source. You do not need to separately install Homebrew SDL2, vcpkg SDL2, or a system SDL2 SDK.

**A native platform compiler and SDK are still required.** These are platform-specific and cannot sensibly be bundled into a portable source archive:

- macOS: Xcode Command Line Tools (`xcode-select --install`).
- Windows: Visual Studio 2022 with the *Desktop development with C++* workload.
- Linux: GCC or Clang, Make, OpenGL development files, and the native window-system development headers/libraries.

On Debian/Ubuntu, the common Linux build prerequisites are:

```bash
sudo apt-get update
sudo apt-get install -y build-essential pkg-config libgl-dev libx11-dev \
  libxext-dev libxrandr-dev libxcursor-dev libxinerama-dev libxi-dev \
  libxfixes-dev libxss-dev libasound2-dev libpulse-dev libwayland-dev \
  libxkbcommon-dev libdbus-1-dev libudev-dev
```

## Quick start

Clone the project with all pinned dependencies:

```bash
git clone --recurse-submodules https://github.com/nvd123-YT/ExcitebikeNESRecompiled.git
cd ExcitebikeNESRecompiled
```

The setup script initializes missing submodules, downloads portable CMake and Python into `.tools/`, verifies the downloaded tool archives, and checks the local compiler prerequisite.

### macOS / Linux

Run the following, using the ROM path on your own computer:

```bash
bash tools/build.sh "$HOME/Downloads/Excitebike (Japan, USA).nes"
```

The script builds the project and launches Excitebike. No Homebrew or sudo is needed on macOS; Xcode Command Line Tools must already be installed. Linux still needs the native compiler and system graphics/audio development headers listed above.

To set up without immediately building the game:

```bash
bash setup.sh
```

### Windows

Install Visual Studio 2022 with the *Desktop development with C++* workload, then open PowerShell in the project directory:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build.ps1 "C:\Games\Excitebike.nes"
```

Or initialize dependencies without starting a game build:

```bat
setup.bat
```

CMake and Python are downloaded locally by the setup script. SDL2 is compiled from the pinned submodule as part of the normal CMake build.

## What recomp-ui provides

The launcher offers a pre-boot game/ROM picker, controller and keyboard configuration, display/audio settings, and an in-game runtime menu. The user selects a local ROM in the launcher.

The ROM picker is **not** a generic ROM-to-native-code converter. This title must first be recompiled locally from the ROM supplied to CMake. At launch, NESRecomp verifies that the selected ROM matches the cartridge and PRG data used for that local build. A different ROM revision is rejected rather than silently running mismatched native code.

## Manual CMake build

After running `setup.sh` or `setup.bat`, the portable CMake and managed Python paths are recorded under `.tools/`.

macOS / Linux:

```bash
CMAKE="$(cat .tools/cmake-path.txt)"
PYTHON="$(cat .tools/python-path.txt)"
export PATH="$(dirname "$PYTHON"):$PATH"
"$CMAKE" -S . -B build -DCMAKE_BUILD_TYPE=Release \
  -DNESRECOMP_ROM="/absolute/path/to/Excitebike.nes"
"$CMAKE" --build build --parallel 4
./build/ExcitebikeRecomp "/absolute/path/to/Excitebike.nes"
```

Windows uses the Visual Studio generator detected by CMake:

```powershell
$CMake = Get-Content .tools/cmake-path.txt -Raw
$Python = Get-Content .tools/python-path.txt -Raw
$env:PATH = "$(Split-Path $Python);$env:PATH"
& $CMake -S . -B build -DNESRECOMP_ROM="C:/Games/Excitebike.nes"
& $CMake --build build --config Release --parallel 4
```

## Development and validation

- Native cycle-backend generation and headless execution were tested locally.
- The SDL2 desktop runner was tested on Apple Silicon macOS.
- The public CI smoke test uses a tiny synthetic NROM test cartridge, never Excitebike game data.
- CI builds the graphical runner and recomp-ui integration on macOS ARM64, Windows x64, and Linux x64.
- Windows and Linux gameplay with an actual Excitebike ROM still requires independent user testing.

## GitHub releases

Every successful push to `main` runs all three platform validation jobs. After all pass, GitHub Actions publishes a new, uniquely tagged **source-only** release for that push. It never moves an old tag or replaces an existing release, so earlier release pages and their download counters remain intact.

Each source release contains the project files and pinned dependency source trees, plus the portable build bootstrap scripts. It does not contain ROMs, game-derived generated code, or playable game binaries. The CI build uses only the synthetic smoke-test ROM. Users build the game locally with their own ROM.

## Repository contents

- `CMakeLists.txt` — NESRecomp, SDL2 and recomp-ui integration.
- `game.toml` — Excitebike recompilation settings.
- `nesrecomp/` — pinned NESRecomp source.
- `recomp-ui/` — pinned launcher and runtime menu source.
- `SDL2/` — pinned SDL2 source, linked statically.
- `tools/bootstrap.*` — portable CMake/Python setup.
- `tools/build.*` — one-command local builds.
- `.github/workflows/source-release.yml` — three-platform validation and unique source releases.

No ROMs, generated game code, local saves/configuration, bootstrapped tool binaries, or build products belong in the public repository.

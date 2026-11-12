# Excitebike Recompiled Builder

A cross-platform **local-build launcher** for Excitebike (NES), based on [NESRecomp](https://github.com/mstan/nesrecomp), [recomp-ui](https://github.com/RetroPortingToolKit/recomp-ui), and a pinned SDL2 source dependency.

> **Bring your own ROM.** The downloadable applications do not contain an Excitebike ROM, ROM-derived generated C source, or a prebuilt playable game. Open the platform launcher, select a compatible `.nes` ROM that you are legally entitled to use, and it will generate and compile the native game locally.

## Separate platform downloads

Every successful push to `main` runs the three platform builds. After all three succeed, GitHub creates a **new release** containing three separate assets:

- **macOS ARM64:** `ExcitebikeRecomp-macOS-ARM64.dmg` — contains `ExcitebikeRecomp.app`.
- **Windows x64:** `ExcitebikeRecomp-Windows-x64.exe`.
- **Linux x64:** `ExcitebikeRecomp-Linux-x64.AppImage`.

The release does not combine these downloads into one source ZIP. Previous releases are never replaced or deleted; each new successful push receives a unique tag and a new release page.

## What each launcher includes

Each platform package contains the launcher UI and its local-build resources:

- A bundled Python runtime for the launcher.
- Portable CMake.
- A managed Python runtime for build-time tooling.
- Pinned NESRecomp, recomp-ui, and SDL2 source trees.
- The Excitebike CMake integration and game configuration.
- SDL2 is built statically as part of the local game build.

The launcher extracts these resources into the user's application data directory, clears macOS Gatekeeper quarantine only from the bundled, checksum-verified CMake/Python tool folders, asks for a local ROM, runs CMake, compiles the native game, and starts it. The build directory and game saves stay on the user's computer and are not removed when the launcher closes.

## Operating-system requirements

A platform compiler and SDK are still required. These are tightly integrated with each operating system and are not safely distributable as ordinary application resources:

- **macOS:** Apple Silicon Mac and Xcode Command Line Tools (`xcode-select --install`).
- **Windows:** Windows x64 and Visual Studio 2022 with the *Desktop development with C++* workload.
- **Linux:** x86_64, GCC or Clang, Make, OpenGL development files, and the desktop window/audio development headers for the distribution.

The launcher reports build errors in its output window. CMake and Python do not need to be installed separately.

## Using a release

1. Download the asset matching your operating system.
2. Open the DMG and move `ExcitebikeRecomp.app` to Applications on macOS. On Windows, run the EXE. On Linux, make the AppImage executable and open it.
3. Select your own compatible Excitebike `.nes` ROM in the launcher.
4. Choose **Build Excitebike & Play**. The first local build compiles the pinned runtime and generated game code and can take several minutes.

On macOS, the app is not Developer ID notarized. If Gatekeeper blocks it, use Finder's Open context-menu action and review the macOS security prompt.

On Linux, the AppImage uses the x86_64 Type 2 format. If FUSE is unavailable, extract the AppImage with its `--appimage-extract` option and launch `AppRun` from the extracted directory.

## Reproducible source build

Developers can clone the source and all pinned dependencies:

```bash
git clone --recurse-submodules https://github.com/nvd123-YT/ExcitebikeNESRecompiled.git
cd ExcitebikeNESRecompiled
```

macOS / Linux:

```bash
bash setup.sh
bash tools/build.sh "/absolute/path/to/Excitebike.nes"
```

Windows PowerShell:

```powershell
.\setup.bat
powershell -ExecutionPolicy Bypass -File .\tools\build.ps1 "C:\Games\Excitebike.nes"
```

## CI and release safety

The public workflow builds the graphical runner and launcher on macOS ARM64, Windows x64, and Linux x64. It uses a synthetic NROM test cartridge only; it never uses a copyrighted Excitebike ROM or packages ROM-derived output. The three downloadable launcher packages contain source dependencies and portable build tools, but no game data.

Release publishing runs only after all three platform jobs and package checks pass. Each release has a unique tag of the form `build-RUN-ATTEMPT-COMMIT`, preserving older release pages and their download counters.

## Repository contents

- `launcher.py` — cross-platform ROM picker and local build UI.
- `CMakeLists.txt` and `game.toml` — native recompilation project.
- `nesrecomp/`, `recomp-ui/`, `SDL2/` — pinned dependency submodules.
- `tools/package_builder.py` — creates the ROM-free resources embedded in each launcher.
- `.github/workflows/source-release.yml` — three-platform build and unique release workflow.

No ROMs, generated game code, local saves, or compiled playable game are committed or published.

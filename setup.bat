@echo off
setlocal
cd /d "%~dp0"

where git >nul 2>nul
if errorlevel 1 (
  echo ERROR: Git is required.
  exit /b 1
)

echo Initializing pinned NESRecomp and recomp-ui submodules...
git submodule update --init --recursive
if errorlevel 1 exit /b 1

if not exist "nesrecomp\runner\cyc\project.cmake" (
  echo ERROR: NESRecomp submodule is incomplete.
  exit /b 1
)
if not exist "recomp-ui\recomp_ui.cmake" (
  echo ERROR: recomp-ui submodule is incomplete.
  exit /b 1
)

echo Dependencies ready.
echo Next: cmake -S . -B build -G "Visual Studio 17 2022" -A x64 -DNESRECOMP_ROM="C:/path/to/Excitebike.nes"
exit /b 0

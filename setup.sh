#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: Git is required." >&2
  exit 1
fi

echo "Initializing pinned NESRecomp and recomp-ui submodules..."
git submodule update --init --recursive

for required in \
  "nesrecomp/runner/cyc/project.cmake" \
  "recomp-ui/recomp_ui.cmake" \
  "recomp-ui/src/recomp_runtime_ui.h"; do
  if [ ! -f "$required" ]; then
    echo "ERROR: required dependency file missing: $required" >&2
    exit 1
  fi
done

echo "Dependencies ready."
echo "Next: cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DNESRECOMP_ROM="/path/to/Excitebike.nes""

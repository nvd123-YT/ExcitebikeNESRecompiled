#!/usr/bin/env python3
"""Package a source-only release, including pinned dependency source trees.

The archive deliberately excludes ROMs, ROM-derived generated source, local
build output, saves, caches and VCS metadata. CI's synthetic ROM is created in
the runner's temporary directory and is never part of this package.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_ROOT = "ExcitebikeNESRecompiled"
ROOT_FILES = (
    ".gitmodules",
    ".gitignore",
    "README.md",
    "CMakeLists.txt",
    "game.toml",
    "setup.sh",
    "setup.bat",
    "tests/create_smoke_rom.py",
)
DEPENDENCIES = ("nesrecomp", "recomp-ui")
SKIP_DIRS = {
    ".git", ".github-cache", "__pycache__", ".pytest_cache", ".mypy_cache",
    ".venv", "venv", "node_modules", "CMakeFiles", "cmake-build-debug",
    "cmake-build-release", "build", "build-debug", "build-release",
}
SKIP_SUFFIXES = {
    ".nes", ".unf", ".unif", ".fds", ".qd", ".rom", ".sav", ".cycstate", ".ips",
}


def git_revision(path: Path) -> str:
    return subprocess.check_output(
        ["git", "-C", str(path), "rev-parse", "HEAD"], text=True
    ).strip()


def dependency_files(root: Path):
    for directory, dirs, files in __import__("os").walk(root):
        dirs[:] = sorted(d for d in dirs if d not in SKIP_DIRS)
        base = Path(directory)
        for name in sorted(files):
            path = base / name
            if name == ".git" or path.is_symlink():
                continue
            if path.suffix.lower() in SKIP_SUFFIXES:
                continue
            if not path.is_file():
                continue
            yield path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    for name in ROOT_FILES:
        if not (ROOT / name).is_file():
            raise SystemExit(f"Required source file is missing: {name}")
    for name in DEPENDENCIES:
        if not (ROOT / name / "CMakeLists.txt").is_file() and name == "nesrecomp":
            raise SystemExit(f"NESRecomp checkout is missing: {name}")
        if not (ROOT / name / "recomp_ui.cmake").is_file() and name == "recomp-ui":
            raise SystemExit(f"recomp-ui checkout is missing: {name}")

    revisions = []
    for name in DEPENDENCIES:
        revisions.append(f"{name}: {git_revision(ROOT / name)}")

    args.output.parent.mkdir(parents=True, exist_ok=True)
    entries: list[tuple[Path, str]] = []
    for name in ROOT_FILES:
        source = ROOT / name
        entries.append((source, f"{ARCHIVE_ROOT}/{name}"))
    for name in DEPENDENCIES:
        for source in dependency_files(ROOT / name):
            relative = source.relative_to(ROOT)
            entries.append((source, f"{ARCHIVE_ROOT}/{relative.as_posix()}"))

    metadata = (
        "ExcitebikeNESRecompiled source release\n"
        "This package contains source code and build configuration only.\n"
        "No Excitebike ROM, game-derived generated C code, game binary, save, "
        "or local build output is included.\n\n"
        "Pinned dependency revisions:\n"
        + "\n".join(revisions)
        + "\n"
    )

    with zipfile.ZipFile(args.output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for source, archive_name in entries:
            archive.write(source, archive_name)
        archive.writestr(f"{ARCHIVE_ROOT}/SOURCE-DEPENDENCIES.txt", metadata)

    with zipfile.ZipFile(args.output) as archive:
        names = archive.namelist()
        forbidden = [n for n in names if Path(n).suffix.lower() in SKIP_SUFFIXES]
        if forbidden:
            args.output.unlink(missing_ok=True)
            raise SystemExit(f"Refusing to publish archive containing ROM/save-like files: {forbidden[:5]}")

    print(f"Created source-only release: {args.output}")
    print(f"Included {len(entries)} files; pinned dependencies: {', '.join(revisions)}")
    print(f"Archive size: {args.output.stat().st_size} bytes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

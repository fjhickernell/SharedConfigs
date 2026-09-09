#!/usr/bin/env python3
"""Build an fh-exam source and export a PDF named for its compiled answer mode.

The plain BASENAME.pdf serves the current editor preview. Only successful builds
replace SOURCE_NO_Answers.pdf or SOURCE_Answers.pdf beside the source.
"""

from __future__ import annotations

import argparse
import fcntl
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


MODE_PREFIX = "FH-EXAM-BUILD-MODE:"
PRETEX = (
    r"\AddToHook{begindocument/end}{"
    r"\ifshowanswers\typeout{FH-EXAM-BUILD-MODE:answers}"
    r"\else\typeout{FH-EXAM-BUILD-MODE:student}\fi}"
)


def publish(pdf: Path, destination: Path) -> None:
    """Replace the exported PDF atomically, after the build succeeds."""
    descriptor, temporary = tempfile.mkstemp(
        prefix=f".{destination.stem}-", suffix=".tmp", dir=destination.parent
    )
    os.close(descriptor)
    temporary_path = Path(temporary)
    try:
        shutil.copy2(pdf, temporary_path)
        os.replace(temporary_path, destination)
    finally:
        temporary_path.unlink(missing_ok=True)


def build(source: Path, outdir: Path) -> Path:
    source = source.expanduser().resolve()
    outdir = outdir.expanduser().resolve()
    if not source.is_file() or source.suffix.lower() != ".tex":
        raise ValueError(f"Expected an existing .tex source: {source}")

    executable = shutil.which("latexmk")
    if executable is None:
        mac_latexmk = Path("/Library/TeX/texbin/latexmk")
        if mac_latexmk.is_file():
            executable = str(mac_latexmk)
        else:
            raise RuntimeError("latexmk is not available; install or enable MacTeX.")
    environment = os.environ.copy()
    environment["PATH"] = str(Path(executable).parent) + os.pathsep + environment.get("PATH", "")

    outdir.mkdir(parents=True, exist_ok=True)
    # Serialize builds of this source so an automatic build cannot export
    # another build's preview while it is being rewritten.
    with (outdir / f"{source.stem}.build.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        command = [
            # -gt ensures the mode hook runs even when an earlier ordinary
            # latexmk build left an otherwise up-to-date cache without it.
            executable, "-pdf", "-gt", "-synctex=1", "-interaction=nonstopmode",
            "-halt-on-error", "-file-line-error",
            f"-outdir={outdir}", f"-jobname={source.stem}",
            f"-usepretex={PRETEX}", str(source),
        ]
        result = subprocess.run(
            command, cwd=source.parent, env=environment, stdin=subprocess.DEVNULL
        )
        if result.returncode:
            raise RuntimeError(
                f"latexmk failed with status {result.returncode}; exported PDFs were not changed."
            )

        log = (outdir / f"{source.stem}.log").read_text(errors="replace")
        modes = re.findall(r"^" + re.escape(MODE_PREFIX) + r"(answers|student)\s*$", log, re.M)
        if len(modes) != 1:
            raise RuntimeError(
                "Cannot determine a unique compiled answer mode; exported PDFs were not changed."
            )
        preview = outdir / f"{source.stem}.pdf"
        if not preview.is_file():
            raise RuntimeError("The build did not produce a PDF; exported PDFs were not changed.")
        suffix = "_Answers" if modes[0] == "answers" else "_NO_Answers"
        destination = source.with_name(source.stem + suffix + ".pdf")
        publish(preview, destination)
        return destination


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--outdir", type=Path, help="Editor preview/build directory (default: SOURCE_DIR)")
    args = parser.parse_args()
    source = args.source.expanduser().resolve()
    outdir = args.outdir or source.parent
    try:
        destination = build(source, outdir)
    except (OSError, RuntimeError, ValueError) as error:
        print(f"fh-exam-build: {error}", file=sys.stderr)
        return 1
    print(f"fh-exam-build: Saved {destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Rendering regression checks for fh-exam, using generic public examples.

Default usage:
    python3 tests/test_fh_exam.py

Each fixture is compiled twice in its own temporary directory. The old and new
package directories are supplied via TEXINPUTS, without changing an installed
TeX tree. Artifacts stay in the reported temporary directory for inspection.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


HERE = Path(__file__).resolve().parent
OLD_STYLE = None
NEW_STYLE = HERE.parent
ARTIFACTS = Path(tempfile.mkdtemp(prefix="fh-exam-regression-"))
RASTER_CHECK = True


def document(settings: str = "", body: str | None = None) -> str:
    if body is None:
        body = r"""
\begin{problems}
  \problem{0}{A generic arithmetic exercise.}
  \begin{subproblems}
    \subproblem{14}{Evaluate a sum and justify the result.}
    \begin{Answer}ANSWER TOKEN\end{Answer}
    \subproblem{6}{Give a second example.}
  \end{subproblems}
\end{problems}
"""
    return r"""\documentclass[11pt,letterpaper]{article}
\usepackage{fh-exam}
\renewcommand{\SubjectCode}{MATH 101}
\renewcommand{\SubjectTitle}{Example Course}
\renewcommand{\Instructor}{Example Instructor}
\renewcommand{\TestName}{Assessment 1}
\renewcommand{\TestDate}{September 10, 2026}
""" + settings + r"""
\begin{document}
\makeexamheader
""" + body + r"""
\end{document}
"""


def run(command: list[str], *, cwd: Path, env: dict[str, str] | None = None) -> str:
    result = subprocess.run(
        command, cwd=cwd, env=env, text=True,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=60,
    )
    if result.returncode:
        raise AssertionError(
            f"Command failed ({result.returncode}) in {cwd}: {command!r}\n"
            f"{result.stdout[-16000:]}"
        )
    return result.stdout


class Render:
    def __init__(self, label: str, source: str, style_dir: Path):
        self.directory = ARTIFACTS / label
        self.directory.mkdir()
        (self.directory / "example.tex").write_text(source, encoding="utf-8")
        env = os.environ.copy()
        # The trailing path separator preserves TeX's normal package search.
        env["TEXINPUTS"] = str(style_dir.resolve()) + os.pathsep
        command = [
            "pdflatex", "-interaction=nonstopmode", "-halt-on-error",
            "-file-line-error", "example.tex",
        ]
        for pass_number in (1, 2):
            output = run(command, cwd=self.directory, env=env)
            (self.directory / f"pass-{pass_number}.txt").write_text(output)
        self.pdf = self.directory / "example.pdf"
        self.text = run(
            ["pdftotext", "-layout", str(self.pdf), "-"], cwd=self.directory,
        )
        (self.directory / "example.txt").write_text(self.text)
        self.normalized = " ".join(self.text.split())
        self.totals = (self.directory / "example.fhxtot").read_text()

    def raster_pages(self) -> list[bytes]:
        run(
            ["pdftoppm", "-r", "72", str(self.pdf), "page"],
            cwd=self.directory,
        )
        return [page.read_bytes() for page in sorted(self.directory.glob("page-*.ppm"))]


class ExamStyleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        for tool in ("pdflatex", "pdftotext"):
            if shutil.which(tool) is None:
                raise RuntimeError(f"Required executable is unavailable: {tool}")
        for directory in (NEW_STYLE, *([OLD_STYLE] if OLD_STYLE else [])):
            if not (directory / "fh-exam.sty").is_file():
                raise RuntimeError(f"Missing staged package: {directory / 'fh-exam.sty'}")

    def new(self, label: str, settings: str = "", body: str | None = None) -> Render:
        return Render(label, document(settings, body), NEW_STYLE)

    def assert_counts(self, rendered: Render, questions: int, points: int):
        self.assertIn(r"\gdef\fhxNumFromFile{" + str(questions) + "}", rendered.totals)
        self.assertIn(r"\gdef\fhxTotalFromFile{" + str(points) + "}", rendered.totals)

    def test_legacy_default_and_takehome_are_unchanged(self):
        if OLD_STYLE is None:
            self.skipTest("Supply --old-style to compare with a previous package")
        body = r"""
\begin{problems}
  \problem{0}{First example.}
  \begin{subproblems}
    \subproblem{3}{First part.}
    \subproblem{7}{Second part.}
  \end{subproblems}
  \problem{5}{Second example.}
\end{problems}
"""
        for mode, settings in (("default", ""), ("takehome", r"\examstyle{takehome}")):
            with self.subTest(mode=mode):
                source = document(settings, body)
                old = Render(f"legacy-{mode}-old", source, OLD_STYLE)
                new = Render(f"legacy-{mode}-new", source, NEW_STYLE)
                self.assertEqual(old.text, new.text, f"Legacy {mode} extracted text changed")
                self.assertEqual(old.totals, new.totals)
                if RASTER_CHECK and shutil.which("pdftoppm"):
                    self.assertEqual(
                        old.raster_pages(), new.raster_pages(),
                        f"Legacy {mode} rendered pixels changed",
                    )

    def test_quiz_one_question_subpart_totals_and_single_score(self):
        rendered = self.new("quiz-single", r"""
\examstyle{quiz}
\renewcommand{\examtimeallowed}{15 minutes}
\setexamgradesummarymode{single}
\setexamgradesummaryscorewidth{6em}
""")
        text = rendered.normalized.lower()
        self.assertRegex(text, r"\bone question\b")
        self.assertNotIn("question(s)", text)
        self.assertIn("20 points", text)
        self.assertIn("15 minutes", text)
        self.assertRegex(rendered.normalized, r"\bScore\b")
        self.assertNotRegex(rendered.normalized, r"\bQ\b")
        self.assertNotRegex(rendered.normalized, r"\bTotal\b")
        self.assertNotIn("ANSWER TOKEN", rendered.normalized)
        self.assert_counts(rendered, questions=1, points=20)

    def test_quiz_multiple_questions_keeps_default_table(self):
        rendered = self.new("quiz-multiple", r"\examstyle{quiz}", r"""
\begin{problems}
  \problem{12}{First example.}
  \problem{8}{Second example.}
\end{problems}
""")
        text = rendered.normalized.lower()
        self.assertRegex(text, r"\btwo questions\b")
        self.assertNotIn("question(s)", text)
        self.assertIn("20 points", text)
        for heading in ("Q", "Score", "Total"):
            self.assertRegex(rendered.normalized, r"\b" + heading + r"\b")
        self.assert_counts(rendered, questions=2, points=20)

    def test_answer_toggle(self):
        rendered = self.new("quiz-answers", r"\examstyle{quiz}\showanswerstrue")
        self.assertIn("ANSWER TOKEN", rendered.normalized)
        self.assert_counts(rendered, questions=1, points=20)

    def test_quiz_custom_instruction_pieces_and_one_point(self):
        rendered = self.new("quiz-custom-pieces", r"""
\examstyle{quiz}
\renewcommand{\examtimeallowed}{17 minutes}
\renewcommand{\examnotesheets}{5}
\renewcommand{\examnotesdesc}{CUSTOM NOTE AID}
\renewcommand{\examdevices}{CUSTOM DEVICE RULE}
\renewcommand{\quizaccommodations}{CUSTOM ACCOMMODATIONS}
\renewcommand{\quizworkinstructions}{CUSTOM WORK RULE}
\renewcommand{\quizanswerinstructions}{CUSTOM ANSWER RULE}
""", r"""
\begin{problems}
  \problem{1}{A one-point example.}
\end{problems}
""")
        self.assertRegex(rendered.normalized.lower(), r"\bone question\b")
        # The first sentence should use singular "point". Legacy \points{1}
        # still prints "1 points" by design, so inspect the instruction only.
        self.assertRegex(rendered.normalized.lower(), r"worth\s+1 point\.")
        for expected in (
            "17 minutes", "5 CUSTOM NOTE AID", "CUSTOM DEVICE RULE",
            "CUSTOM ACCOMMODATIONS", "CUSTOM WORK RULE", "CUSTOM ANSWER RULE",
        ):
            self.assertIn(expected, rendered.normalized)
        self.assert_counts(rendered, questions=1, points=1)

    def test_invalid_score_mode_is_a_package_error(self):
        with self.assertRaisesRegex(AssertionError, r"Package fh-exam Error"):
            self.new("invalid-score-mode", r"\setexamgradesummarymode{invalid}")

    def test_explicit_full_instructions_before_or_after_quiz_preset(self):
        preset = r"\examstyle{quiz}"
        custom = r"\setexamfullinstructions{CUSTOM FULL INSTRUCTIONS}"
        for order, settings in (("before", custom + preset), ("after", preset + custom)):
            with self.subTest(order=order):
                rendered = self.new(f"custom-full-{order}", settings)
                self.assertIn("CUSTOM FULL INSTRUCTIONS", rendered.normalized)
                self.assertNotIn("This quiz", rendered.normalized)

    def test_explicit_first_instruction_before_or_after_quiz_preset(self):
        preset = r"\examstyle{quiz}"
        custom = r"\setexamfirstinstruction{CUSTOM FIRST INSTRUCTION}"
        for order, settings in (("before", custom + preset), ("after", preset + custom)):
            with self.subTest(order=order):
                rendered = self.new(f"custom-first-{order}", settings)
                self.assertIn("CUSTOM FIRST INSTRUCTION", rendered.normalized)
                self.assertNotIn("This quiz has", rendered.normalized)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--old-style", type=Path, default=OLD_STYLE)
    parser.add_argument("--new-style", type=Path, default=NEW_STYLE)
    parser.add_argument("--no-raster", action="store_true")
    arguments, unittest_arguments = parser.parse_known_args()
    OLD_STYLE, NEW_STYLE = arguments.old_style, arguments.new_style
    RASTER_CHECK = not arguments.no_raster
    print(f"Regression artifacts: {ARTIFACTS}", flush=True)
    unittest.main(argv=[__file__, *unittest_arguments], verbosity=2)

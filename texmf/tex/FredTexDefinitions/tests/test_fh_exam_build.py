#!/usr/bin/env python3
"""End-to-end tests for fh-exam-build.py with disposable generic documents.

Run with no arguments to test the installed fh-exam-build.py (or a sibling
helper when staged outside SharedConfigs), or pass its path with --builder. No course files or shared configuration are modified.
"""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


TEST_FILE = Path(__file__).resolve()
# Installed at SharedConfigs/texmf/tex/FredTexDefinitions/tests/test_*.py:
# parents[0] is tests; parents[4] is the SharedConfigs root.
if TEST_FILE.parent.name == "tests" and TEST_FILE.parents[1].name == "FredTexDefinitions":
    BUILDER = TEST_FILE.parents[4] / "bin" / "fh-exam-build.py"
else:
    BUILDER = TEST_FILE.with_name("fh-exam-build.py")
ARTIFACTS = Path(tempfile.mkdtemp(prefix="fh-exam build regression ")).resolve()


def fixture(mode: str = "false", extra_preamble: str = "") -> str:
    return r"""\documentclass{article}
\usepackage{fh-exam}
\showanswers""" + mode + r"""
% This commented alternative must not select answers: \showanswerstrue
""" + extra_preamble + r"""
\begin{document}
Question count: \examnumproblemsref. Point count: \examtotalpointsref.
\begin{problems}
  \problem{0}{A generic example.}
  \begin{subproblems}
    \subproblem{14}{First part.}
    \begin{Answer}VISIBLE ANSWER TOKEN\end{Answer}
    \subproblem{6}{Second part.}
  \end{subproblems}
\end{problems}
\end{document}
"""


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pdf_text(path: Path) -> str:
    result = subprocess.run(
        ["pdftotext", str(path), "-"], text=True,
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=30,
    )
    if result.returncode:
        raise AssertionError(result.stdout)
    return " ".join(result.stdout.split())


class ExamBuildTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not BUILDER.is_file():
            raise RuntimeError(f"Build script is missing: {BUILDER}")
        for tool in ("latexmk", "pdftotext"):
            if shutil.which(tool) is None:
                raise RuntimeError(f"Required executable is unavailable: {tool}")

    def setUp(self):
        self.directory = ARTIFACTS / self._testMethodName
        self.directory.mkdir()
        # Both the enclosing directory and the source name contain spaces.
        self.source = self.directory / "Example Quiz.tex"
        self.student = self.directory / "Example Quiz_NO_Answers.pdf"
        self.answers = self.directory / "Example Quiz_Answers.pdf"
        self.default_outdir = self.directory
        self.calls = 0

    def build(self, *, outdir: Path | None = None, expect_success: bool = True):
        self.calls += 1
        command = [sys.executable, str(BUILDER), str(self.source)]
        if outdir is not None:
            command += ["--outdir", str(outdir)]
        result = subprocess.run(
            command, cwd=self.directory, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90,
        )
        (self.directory / f"build-{self.calls}.txt").write_text(result.stdout)
        if expect_success:
            self.assertEqual(result.returncode, 0, result.stdout[-14000:])
        else:
            self.assertNotEqual(result.returncode, 0, result.stdout)
        return result

    def assert_document(self, exported: Path, *, answers: bool, outdir: Path | None = None):
        outdir = self.default_outdir if outdir is None else outdir
        preview = outdir / "Example Quiz.pdf"
        self.assertTrue(exported.is_file(), f"Missing export: {exported}")
        self.assertTrue(preview.is_file(), f"Missing stable preview: {preview}")
        text = pdf_text(exported)
        self.assertIn("Question count: 1. Point count: 20.", text)
        if answers:
            self.assertIn("VISIBLE ANSWER TOKEN", text)
        else:
            self.assertNotIn("VISIBLE ANSWER TOKEN", text)
        self.assertEqual(digest(exported), digest(preview))
        count_text = (outdir / "Example Quiz.fhxtot").read_text()
        self.assertIn(r"\gdef\fhxNumFromFile{1}", count_text)
        self.assertIn(r"\gdef\fhxTotalFromFile{20}", count_text)

    def test_false_true_false_preserves_other_export(self):
        original = fixture()
        self.source.write_text(original)
        self.build()
        self.assert_document(self.student, answers=False)
        self.assertFalse(self.answers.exists())
        self.assertEqual(self.source.read_text(), original)
        student_hash = digest(self.student)

        answer_source = fixture("true")
        self.source.write_text(answer_source)
        self.build()
        self.assert_document(self.answers, answers=True)
        self.assertEqual(digest(self.student), student_hash)
        self.assertEqual(self.source.read_text(), answer_source)
        answer_hash = digest(self.answers)

        self.source.write_text(original)
        self.build()
        self.assert_document(self.student, answers=False)
        self.assertEqual(digest(self.answers), answer_hash)
        self.assertEqual(self.source.read_text(), original)

    def test_delayed_answer_toggle_uses_actual_tex_state(self):
        original = fixture("false", r"\AtBeginDocument{\showanswerstrue}")
        self.source.write_text(original)
        self.build()
        self.assert_document(self.answers, answers=True)
        self.assertFalse(self.student.exists())
        self.assertEqual(self.source.read_text(), original)

    def test_custom_output_directory(self):
        outdir = self.directory / "custom build output"
        original = fixture()
        self.source.write_text(original)
        self.build(outdir=outdir)
        self.assert_document(self.student, answers=False, outdir=outdir)
        self.assertFalse((self.directory / "Example Quiz.pdf").exists())
        self.assertFalse((self.directory / ".build").exists())
        self.assertEqual(self.source.read_text(), original)

    def test_existing_plain_latexmk_cache_is_rebuilt_with_mode_marker(self):
        original = fixture()
        self.source.write_text(original)
        result = subprocess.run(
            ["latexmk", "-pdf", "-synctex=1", "-interaction=nonstopmode",
             "-halt-on-error", "-file-line-error", str(self.source)],
            cwd=self.directory, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=90,
        )
        (self.directory / "plain-latexmk-build.txt").write_text(result.stdout)
        self.assertEqual(result.returncode, 0, result.stdout[-10000:])
        old_log = (self.directory / "Example Quiz.log").read_text()
        self.assertNotIn("FH-EXAM-BUILD-MODE:", old_log)
        self.assertTrue((self.directory / "Example Quiz.pdf").is_file())
        self.assertFalse(self.student.exists())

        self.build()
        self.assert_document(self.student, answers=False)
        new_log = (self.directory / "Example Quiz.log").read_text()
        self.assertIn("FH-EXAM-BUILD-MODE:student", new_log)
        self.assertEqual(self.source.read_text(), original)

    def test_compile_failure_preserves_both_exports(self):
        self.source.write_text(fixture())
        self.build()
        self.source.write_text(fixture("true"))
        self.build()
        before = {path: digest(path) for path in (self.student, self.answers)}

        broken = fixture("true").replace(
            r"\end{problems}", r"\UndefinedCommandForFailureTest" + "\n" + r"\end{problems}",
        )
        self.source.write_text(broken)
        self.build(expect_success=False)
        self.assertEqual({path: digest(path) for path in before}, before)
        self.assertEqual(self.source.read_text(), broken)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--builder", type=Path, default=BUILDER)
    arguments, unittest_arguments = parser.parse_known_args()
    BUILDER = arguments.builder.resolve()
    print(f"Build regression artifacts: {ARTIFACTS}", flush=True)
    unittest.main(argv=[__file__, *unittest_arguments], verbosity=2)

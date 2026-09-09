# fh-exam

`fh-exam.sty` provides headers, instructions, scoring boxes, problems and
subproblems, point totals, and switchable answers for paper assessments.
Version **3.23 (2026/09/09)** adds optional quiz instructions and a single
score box. The package's version history is at the top of `fh-exam.sty`.

## A quiz

```latex
\documentclass[11pt,letterpaper]{article}
\usepackage{fh-exam}

\examstyle{quiz}
\setexamgradesummarymode{single}
\setexamgradesummaryscorewidth{60pt}

\renewcommand{\SubjectCode}{MATH 101}
\renewcommand{\SubjectTitle}{Example Course}
\renewcommand{\Instructor}{Example Instructor}
\renewcommand{\TestName}{Quiz 1}
\renewcommand{\TestDate}{September 10, 2026}
\renewcommand{\examtimeallowed}{15 minutes}
\renewcommand{\examnotesheets}{4}
\renewcommand{\quizaccommodations}{Approved testing accommodations apply.}

\showanswersfalse  % Change to \showanswerstrue for the answer key.
\showcommentsfalse

\begin{document}
\makeexamheader
\begin{problems}
  \problem{20}{Write the question here.}
  \begin{Answer}
    Write the solution here.
  \end{Answer}
\end{problems}
\end{document}
```

Set the actual course policies and duration explicitly. Quiz mode does not
change the existing defaults of 75 minutes and four note sheets. Course
metadata, assessment dates, permitted materials, questions, and answers belong
in the private assessment source or a private course setup file.

Compile at least twice after changing questions or points. The `.fhxtot` and
`.aux` files supply the question count, header total, and subproblem totals on
the next pass. For a problem whose points come from its subparts, use
`\problem{0}{...}` followed by `\subproblem{points}{...}` entries; do not also
assign those points to the parent problem.

## Score display

- `\setexamgradesummarymode{single}` prints a **Score** heading and one blank
  box. It has no question-number column or separate Total row.
- `\setexamgradesummarymode{table}` restores the default **Q / Score** table
  with one row per problem and a Total row.
- `\showexamgradesummaryfalse` hides the score display.

Mode selection is explicit, independent of the question count and quiz mode.
Existing documents continue to use the table, including one-question exams.
The optional count in `\examgradesummary[8]` controls rows in table mode and is
ignored in single mode.

Both modes use the existing `\setexamgradesummaryscorewidth{...}`,
`\setexamgradesummaryrowheight{...}`, and
`\setexamgradesummarylayout{instruction width}{box width}` controls. The
question-column width applies only to the table. Width and height setters
evaluate dimensions where they are called; an absolute width such as `60pt`
is useful when preserving an existing layout.

## Quiz instructions

`\examstyle{quiz}` selects compact classroom instructions. The first sentence
uses the recorded count and total, including **one question**, **two questions**,
and singular **point** when appropriate. It uses the existing
`\examtimeallowed`, `\examnotesheets`, `\examnotesdesc`, and `\examdevices`
settings. Quiz mode supplies concise device wording and note-sheet wording;
explicit redefinitions of those settings take precedence.

The additional quiz-specific text can be changed with `\renewcommand`:

| Command | Default |
| --- | --- |
| `\quizaccommodations` | Empty; optional text after the duration. |
| `\quizworkinstructions` | Individual work, no communication or shared materials, questions directed to the instructor. |
| `\quizanswerinstructions` | Show and justify work, simplify fractions, and retain exact expressions. |

Use `\setexamfirstinstruction{...}` to replace only the first instruction.
Use `\setexamfullinstructions{...}` to replace the entire instruction block.
In quiz mode, these explicit setters win whether they occur before or after
`\examstyle{quiz}` in the preamble. Use the full-instruction setter rather
than directly redefining `\examfullinstructions`. Select the mode before
`\begin{document}`; its instruction preset is installed at document startup.

The existing honor statement, header, answer/comment defaults, regular-exam
instructions, and take-home output are preserved. Legacy take-home mode still
installs its own full instructions at document startup; the new quiz override
precedence does not alter that existing behavior.

## Migrating an existing quiz

Replace a local redefinition of `\examgradesummary` with the score-mode setter
and any required width setting. Replace a copied full instruction block with
`\examstyle{quiz}` and the relevant text settings. Retain the original course
policies, metadata, question source, and `Answer` environments. Render both
student and answer versions and compare them with the approved PDFs.

## Filenames selected by the answer switch

The companion `SharedConfigs/bin/fh-exam-build.py` command builds an assessment
and exports a named PDF according to the answer flag actually evaluated by
LaTeX after the preamble:

- `\showanswersfalse` exports `BASENAME_NO_Answers.pdf`.
- `\showanswerstrue` exports `BASENAME_Answers.pdf`.

For example:

```sh
python3 ~/Documents/SharedConfigs/bin/fh-exam-build.py '/path/to/Quiz1.tex'
```

The helper keeps `BASENAME.pdf` as the current render and editor preview, with
auxiliary files beside the source. Set LaTeX Workshop's output directory to
`%DIR%` and use the helper in the build recipe. The normal Build button then
updates both the current PDF and the selected suffixed PDF, while **View
LaTeX PDF file** continues to show the current render. The configured MATH 332
private folder has this recipe installed. The plain PDF may contain answers;
use the explicit `_NO_Answers` file for students.

Only the selected export is replaced, atomically, after a successful build.
The other PDF remains from its last successful build. Rebuild both modes after
content changes when both versions are needed. The helper requires an
`fh-exam` source, Python 3.9 or later on macOS/Linux, and `latexmk`; it respects
LaTeX's actual switch rather than searching the source for matching text.
Plain `pdflatex` and `latexmk` commands retain their ordinary naming.

The companion tests can be run from the `FredTexDefinitions` directory:

```sh
python3 tests/test_fh_exam_build.py
```

## Validation

The generic fixtures in `tests/test_fh_exam.py` contain no private assessment
content. They check quiz wording and counts, subpart totals, scoring modes,
instruction overrides, and answer visibility. They require Python 3.10 or
later, `pdflatex`, and Poppler's `pdftotext`; `pdftoppm` additionally enables
pixel comparisons when a previous package is supplied.

From this directory:

```sh
python3 tests/test_fh_exam.py
```

To also compare regular and take-home rendering with a prior version, supply
a directory containing the earlier file under the name `fh-exam.sty`:

```sh
python3 tests/test_fh_exam.py --old-style /path/to/previous-package
```

Build artifacts are kept in the temporary directory reported by the test run.

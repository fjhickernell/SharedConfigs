Parent: [[Lessons Learned#5. Teaching / Course Infrastructure]]

Title: Quarto website + RevealJS slides in one repo (with submodules)

Context
- Course repo uses a Quarto website (rendered to `docs/` for GitHub Pages)
- RevealJS slides live under `slides/`
- Shared slide/website assets live in the `HickernellClassLib` submodule

Key rules (hard-won)

1. Each slide deck must explicitly include:
   format: revealjs
   Otherwise Quarto renders one long HTML page with no slide styling.

2. Shared slide configuration lives in HickernellClassLib
   - File: classlib/quarto/slides/hickernell-slides.yml
   - Paths inside this file must be relative to the slides/ directory
     (e.g. ../classlib/classlib/...)

3. Avoid symlinks
   - Quarto + symlinks + GitHub Pages is brittle
   - Use real files only

4. Shared images belong in one canonical location
   HickernellClassLib/classlib/quarto/assets/images/
   Slides and website both reference this location.

5. GitHub Pages only serves files in docs/
   - Local quarto preview can read submodule files directly
   - GitHub Pages cannot
   - Therefore shared CSS, JS, and images from submodules must be copied into docs/ at render time

Solution: unified render script

Create one script in the course repo:
bin/render-site.sh

Responsibilities:
- remove docs/
- run quarto render
- copy required shared assets from classlib/ into docs/
- fail if any required asset is missing

Publishing workflow

./bin/render-site.sh
git add docs
git commit -m "Re-render site"
git push

Outcome
- Slides render correctly both locally and on GitHub Pages
- CSS, LaTeX macros, and background images work everywhere
- Setup scales cleanly to future courses (e.g. MATH 563)

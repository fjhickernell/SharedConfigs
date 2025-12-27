# Class Repos, Submodules, Quarto, and Publishing

Parent: [[Lessons Learned#2. Teaching, Class Repos & Course Development]]

## Canonical Workflow (MathJax 3 + RevealJS + GitHub Pages)

**This document defines the one true workflow** for working with:

- class repositories
- shared submodules (HickernellClassLib, QMCSoftware)
- Quarto websites and RevealJS slides
- MathJax 3 (SVG output)
- GitHub Pages publishing

**Goals**

- Consistency across machines
- No hidden Git states
- Automation that does exactly what is expected
- Stable math, stable slides, zero semester surprises

---

## 1. Repository Roles (Mental Model)

### 1.1 Standalone (Canonical) Repos

These are the **authoritative clones** that automation scripts are allowed to push.

```
~/SoftwareRepositories/HickernellClassLib   (branch: main)
~/SoftwareRepositories/QMCSoftware          (branch: develop)
```

**Rule**

> Shared code must ultimately be committed and pushed **from these repos**.

This includes:

- CSS / SCSS
- Quarto YAML
- MathJax macros
- JavaScript helpers
- shared images
- shared notebooks

---

### 1.2 Class Repos (Superprojects)

Examples:

```
MATH476Spring2026
MATH565Fall2025
```

Each class repo contains **submodules**:

```
classlib     → HickernellClassLib
qmcsoftware  → QMCSoftware
```

A class repo **does not contain shared code**.\
It only contains **pointers to specific commits** of shared repos.

---

### 1.3 Submodule Clones (Embedded)

Paths like:

```
MATH476Spring2026/classlib
MATH476Spring2026/qmcsoftware
```

These are *real clones*, but **not canonical**.

They exist for:

- browsing
- reading
- local preview

They are **not where publishing decisions are made**.

---

## 2. Scripts and Their Responsibilities

This workflow relies on **three distinct scripts** with non-overlapping responsibilities:

- `sync-class.sh` — bring a machine up to date
- `update-submodules.sh` — align a class repo’s submodule pointers
- `checkpoint-publish.sh` — publish already-correct state

The scripts form a strict pipeline: `sync-class.sh` (machine sync) → `update-submodules.sh` (pointer alignment) → `checkpoint-publish.sh` (commit + push).  Keeping these roles distinct is essential for predictability.

### 2.1 `sync-class.sh`

**Purpose**\
Bring a Mac fully up to date.

**What it does**

- pulls standalone repos
- pulls class repos
- updates submodules to allowed commits

**What it does NOT do**

- does not commit
- does not push

**Use when**

- sitting down at another Mac
- starting work for the day
- weekly maintenance

---

### 2.2 `update-submodules.sh`

**Location**  
Each class repo contains its own copy:

```
classlib/bin/update-submodules.sh
```
(or symlinked into `bin/` depending on the repo layout)

**Purpose**  
Synchronize a class repo’s submodules to the intended upstream state.

**What it does**

- fetches latest commits from submodule remotes
- updates `classlib` to the current `main` of HickernellClassLib
- updates `qmcsoftware` to the current `develop` of QMCSoftware
- leaves the class repo in a *dirty but inspectable* state

**What it does NOT do**

- does not commit submodule pointers
- does not push anything
- does not invent or modify shared code

**Use when**

- you know shared repos have moved forward
- before previewing or rendering locally
- before committing pointer updates by hand

A dirty class repo after running this script indicates pending pointer updates, not uncommitted shared code.

---

### 2.3 `checkpoint-publish.sh`

**Purpose**\
Publish everything that is already correct.

**What it does**

- pushes standalone repos
- updates submodule pointers in class repos
- commits those pointers
- pushes class repos

**What it does NOT do**

- does not invent commits
- does not scan submodule clones for unpublished work

---

## 3. Canonical Rules (Read Twice)

### Rule 1 — Shared code lives in standalone repos

If you change anything under:

```
classlib/
qmcsoftware/
```

Those changes must eventually be:

- committed **and**
- pushed

from:

```
~/SoftwareRepositories/HickernellClassLib
~/SoftwareRepositories/QMCSoftware
```

---

### Rule 2 — Editing location ≠ committing location

You **may edit** shared files anywhere, but:

> **Commits for shared code happen only in the standalone repo.**

---

### Rule 3 — Class repos only commit pointers

Class repos should only commit:

- course content
- updated submodule pointers

They **never own shared code**.

---

### Rule 4 — `Update-submodules.sh` moves pointers, nothing else

- `update-submodules.sh` is the only supported way to advance submodule pointers in a class repo.
- It may leave the repo dirty. That is intentional.
- Pointers are committed only by `checkpoint-publish.sh`.

---

## 4. Standard Git Workflows

### Scenario 1 — Edit course files only

```
edit files in class repo
git commit
checkpoint-publish.sh
```

---

### Scenario 2 — Edit shared styles, MathJax, or templates

```
edit files anywhere

cd ~/SoftwareRepositories/HickernellClassLib
git pull
git status
git add -A
git commit -m "Describe shared change"
git push
```
If shared repos have advanced since the last sync:
- run `update-submodules.sh` in the class repo
- inspect submodule changes

```
checkpoint-publish.sh --all
```

---

### Scenario 3 — New Mac / weekly maintenance

```
sync-class.sh
```

---

## 5. Quarto + RevealJS (Website + Slides in One Repo)

### 5.1 Structure

```
slides/
  intro-01.qmd
  _metadata.yml
  _metadata-dev.yml   (optional, gitignored)

docs/
```

---

### 5.2 Hard Rules

1. Every slide deck must include:

```yaml
format: revealjs
```

2. Shared slide configuration lives in HickernellClassLib:

```
classlib/quarto/slides/hickernell-slides.yml
```

3. Paths inside shared YAML are relative to `slides/`.

4. Avoid symlinks.

5. GitHub Pages only serves files under `docs/`.

---

## 6. MathJax 3 — Stable, Predictable, SVG‑Only

### 6.1 Why MathJax 3 + SVG

- deterministic layout
- no font-loading race conditions
- no text reflow
- consistent spacing across browsers
- fixes RevealJS overlay issues

---

### 6.2 Canonical Configuration

```yaml
format:
  revealjs:
    html-math-method:
      method: mathjax
      url: https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg-full.js
```

**Rules**

- Always use SVG output
- Never mix MathJax 2 and 3
- Never rely on auto-typesetting

---

## 7. RevealJS Fragments — Reliable Usage

### Preferred pattern

```markdown
::: {.fragment}
Content
:::
```

or indexed fragments:

```html
<div class="fragment" data-fragment-index="1">
```

Any slide with **math + fragments** requires the shared MathJax re-typesetting hook.

---

## 8. Asset Handling

### Canonical locations

```
HickernellClassLib/classlib/quarto/
  slides/
  website/
  assets/images/
  js/
```

---

## 9. Unified Render Script (Required)

Each class repo must have:

```
bin/render-site.sh
```

Responsibilities:

- remove `docs/`
- run `quarto render`
- copy required assets into `docs/`
- fail loudly if anything is missing

---

## 10. Publishing Workflow

```
./bin/render-site.sh
git add docs
git commit -m "Re-render site"
git push
```

---

## 11. One‑Sentence Summary

> Edit anywhere, commit shared code only in standalone repos, use `update-submodules.sh` to advance pointers, use MathJax 3 with SVG and controlled startup, let scripts manage commits, and always materialize assets into docs/ before publishing.

---

**Last updated:** 2025‑12‑26


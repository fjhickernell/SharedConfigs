# Class Repos, Submodules, Quarto, and Publishing (Revised Canonical Workflow)

Parent: [[Lessons Learned#2. Teaching, Class Repos & Course Development]]

## Canonical Workflow (Quarto + RevealJS + MathJax 3 + GitHub Pages)

**This document defines the one true workflow** for working with:

- class repositories
- shared submodules (HickernellClassLib, QMCSoftware)
- Quarto websites and RevealJS slides
- MathJax 3 (SVG output)
- GitHub Pages publishing

This workflow reflects **lessons learned in practice**, not theoretical Git usage.

---

## Goals

- Consistency across machines
- No hidden Git states
- No accidental submodule commits
- Clear separation of editing, committing, and publishing
- Zero semester surprises

---

## 1. Repository Roles (Mental Model)

### 1.1 Standalone (Canonical) Repos — Source of Truth

These are the only repositories allowed to create and push shared commits.

~/SoftwareRepositories/HickernellClassLib   (branch: main)  
~/SoftwareRepositories/QMCSoftware          (branch: develop)

Any shared code that will be reused across courses must be committed and pushed from these repos.

This includes Python modules, CSS/SCSS, Quarto YAML, MathJax macros, JavaScript helpers, shared images, and shared notebooks.

---

### 1.2 Class Repos (Superprojects)

Examples: MATH476Spring2026, MATH563Spring2026, MATH565Fall2025

Each class repo contains submodules:

classlib     → HickernellClassLib  
qmcsoftware  → QMCSoftware

A class repo owns course-specific content, pins specific commits of shared repos, and publishes rendered output.  
A class repo does not own shared code.

---

### 1.3 Submodule Working Trees (Embedded Clones)

Paths like:

MATH476Spring2026/classlib  
MATH476Spring2026/qmcsoftware

These are real Git working trees, but they are non-authoritative.

They exist for reading, browsing, local preview, and temporary editing convenience.  
They are never the final commit location.

---

## 2. The Three Fundamental Operations (Key Lesson)

There are three distinct operations that must never be conflated:

1. Editing shared code  
2. Advancing submodule pointers  
3. Synchronizing machines  

Each operation has exactly one supported mechanism.

---

## 3. Scripts and Their Responsibilities

### 3.1 `sync-class.sh` — Machine Synchronization

Purpose: bring a Mac into a clean, known-good state.

What it does:
- pulls standalone repos
- pulls class repos
- enforces that class repos match their pinned submodule SHAs

What it does not do:
- does not advance submodule pointers
- does not commit
- does not push

Use when switching Macs, starting work for the day, weekly maintenance, or recovering from confusion.

---

### 3.2 `publish-classlib-here.sh` — Publishing Shared Code

Purpose: commit and push shared code from the correct place.

Requirements:
- must be run from a class repo
- submodule must be on its branch (not detached)
- changes must already be correct

What it does:
- commits shared code in the standalone repo
- pushes it upstream
- leaves class repos untouched

What it does not do:
- does not advance submodule pointers
- does not scan for uncommitted work elsewhere
- does not guess intent

---

### 3.3 `sync-class.sh --push` — Advance Submodule Pointers

Purpose: advance class repos to the latest approved shared commits.

What it does:
- fast-forwards classlib → main
- fast-forwards qmcsoftware → develop
- commits updated submodule pointers
- pushes class repos

What it does not do:
- does not edit shared code
- does not create new shared commits

This is the only supported way to advance pointers.

---

## 4. Canonical Rules (Non-Negotiable)

Rule 1: Shared code commits happen only in standalone repos.

Rule 2: Editing location does not determine commit location.

Rule 3: Class repos commit only course files and submodule pointer updates.

Rule 4: Submodule pointers advance only via sync-class.sh --push.

---

## 5. Standard Workflows

Scenario 1 — Edit course-only content  
Edit files in class repo → git commit → git push

Scenario 2 — Edit shared Python / CSS / Quarto assets  
Edit files anywhere → publish-classlib-here.sh "Describe change" → sync-class.sh --push

Scenario 3 — New Mac / cleanup  
sync-class.sh

---

## 6. Quarto + RevealJS

Slides live under slides/.  
Shared slide configuration lives in HickernellClassLib/classlib/quarto/slides/.  
GitHub Pages serves only docs/.

---

## 7. MathJax 3 — SVG Only

Always use MathJax 3 with SVG output. Never mix MathJax versions.

---

## 8. Assets

Canonical locations in HickernellClassLib:

classlib/quarto/slides  
classlib/quarto/website  
classlib/quarto/assets/images  
classlib/quarto/js

Assets must be materialized into docs/ before publishing.

---

## 9. Rendering

Each class repo must provide bin/render-site.sh.

Responsibilities:
- remove docs/
- run quarto render
- copy required assets
- fail loudly if incomplete

---

## 10. Publishing

./bin/render-site.sh  
git add docs  
git commit -m "Re-render site"  
git push

---

## 11. One-Sentence Summary

Edit anywhere, commit shared code only in standalone repos, publish shared changes explicitly, advance submodule pointers intentionally, sync machines defensively, and never let a class repo pretend it owns shared code.

---

Last updated: 2025-12-31

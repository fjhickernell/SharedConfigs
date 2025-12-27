# Class Repos, Submodules, and Publishing — Canonical Workflow

This document defines the **one true workflow** for working with class repos,
shared submodules, and publishing changes across multiple Macs.

The goal is:
- consistency across machines,
- no hidden Git states,
- automation that does what I expect,
- and zero surprises during the semester.

---

## Repository Roles (Mental Model)

### 1. Standalone (Canonical) Repos
These are the **authoritative clones** that automation scripts manage and push:

- ~/SoftwareRepositories/HickernellClassLib (branch: main)
- ~/SoftwareRepositories/QMCSoftware (branch: develop)

**Rule:**  
Shared code must ultimately be **committed and pushed from these repos**.

---

### 2. Class Repos (Superprojects)
Examples:
- MATH476Spring2026
- MATH565Fall2025

Each class repo contains **submodules**:
- classlib → HickernellClassLib
- qmcsoftware → QMCSoftware

A class repo does **not** contain the shared code itself — only a **pointer**
to a specific commit of each submodule.

---

### 3. Submodule Clones (Embedded)
Paths like:
- MATH476Spring2026/classlib and qmcsoftware
- MATH565Fall2025/classlib and qmcsoftware

These are **additional clones** of the same repo.

They exist for convenience but are **not canonical** for publishing.

---

## Scripts and Their Responsibilities

### sync-class.sh
**Purpose:**  
Bring a Mac fully up to date.

**What it does:**
- pulls latest standalone repos
- pulls class repos
- updates submodules to latest allowed commits

**What it does NOT do:**
- does not commit anything
- does not push anything

Use this when:
- sitting down at another Mac
- starting work for the day

---

### checkpoint-publish.sh
**Purpose:**  
Publish everything that is already correct.

**What it does:**
- pushes standalone repos (canonical clones)
- updates and commits submodule pointers in class repos
- pushes class repos

**What it does NOT do:**
- does not invent commits
- does not scan submodule clones for unpublished commits

---

## The Canonical Rules (Read This Twice)

### Rule 1 — Shared code lives in standalone repos
If you change anything under classlib/ or qmcsoftware/,
those changes must eventually be:

committed AND pushed

from:
- ~/SoftwareRepositories/HickernellClassLib
- ~/SoftwareRepositories/QMCSoftware

This is what checkpoint-publish.sh knows how to push.

---

### Rule 2 — Editing location ≠ committing location
It is **allowed** to edit shared files inside a class repo
(e.g., using VS Code in MATH476Spring2026/classlib).

However:

Edits anywhere → commits only in the standalone repo.

If you commit only inside a submodule clone:
- the standalone clone does not see the commit
- checkpoint-publish.sh will NOT push it
- confusion ensues

---

### Rule 3 — Class repos only commit pointers
Class repos should only ever commit:
- course content changes
- updated submodule pointers

They never own shared code.

---

## Standard Workflows

### Scenario 1 — Edit course files only
(e.g., slides, pages, notebooks)

1. Edit files in the class repo
2. Commit in the class repo (VS Code / GitKraken / CLI)
3. Run:
   checkpoint-publish.sh

---

### Scenario 2 — Edit shared styles / code (classlib)
(e.g., SCSS, slide templates, macros)

1. Edit files anywhere (VS Code is fine)
2. Switch to the standalone repo:
   cd ~/SoftwareRepositories/HickernellClassLib
   git pull
   git status
3. Commit and push:
   git add -A
   git commit -m "Describe shared change"
   git push
4. Update class repos and publish:
   checkpoint-publish.sh --all

This updates:
- GitHub shared repo
- submodule pointers in all class repos
- class repos on GitHub

---

### Scenario 3 — New Mac / weekly maintenance

1. Run:
   sync-class.sh
2. Fix anything that breaks (preferred over pinning old commits)

---

## What NOT to Do

- Do not rely on committing inside classrepo/classlib
- Do not assume checkpoint-publish.sh will find unpublished commits
- Do not manually edit submodule pointers unless debugging

---

## One-Sentence Summary

Edit anywhere, commit shared code only in standalone repos, and let
checkpoint-publish.sh handle pointer updates and pushing.

---

_Last updated: 2025-12-21_

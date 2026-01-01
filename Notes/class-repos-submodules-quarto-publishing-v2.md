# Class Repos, Submodules, Quarto, and Publishing (Revised Canonical Workflow)

Parent: [[Lessons Learned#2. Teaching, Class Repos & Course Development]]

## Canonical Workflow (Quarto + RevealJS + MathJax 3 + GitHub Pages)

This document defines the one true workflow for working with:
- class repositories (superprojects)
- shared submodules (HickernellClassLib, QMCSoftware)
- Quarto websites and RevealJS slides
- MathJax 3 (SVG output)
- GitHub Pages publishing

---

## Goals

- Consistency across machines
- No hidden Git states
- No accidental submodule commits
- Clear separation of editing, committing, and publishing
- Stable preview locally and stable publish via CI

---

## 1. Repository Roles (Mental Model)

### 1.1 Standalone (Canonical) Repos — Source of Truth

Only these repos are allowed to create and push shared commits:

```
~/SoftwareRepositories/HickernellClassLib   (branch: main)
~/SoftwareRepositories/QMCSoftware          (branch: develop)
```

Shared infrastructure (Python, Quarto assets, templates, shared notebooks, images, CSS/SCSS, JS) must ultimately be committed and pushed from these repos.

---

### 1.2 Class Repos (Superprojects)

Examples:

```
MATH476Spring2026
MATH563Spring2026
MATH565Fall2025
SIAMUQ26
```

Each class repo contains submodules:

```
classlib     → HickernellClassLib
qmcsoftware  → QMCSoftware
```

Class repos own course content and submodule pointers. They do not own shared code.

---

### 1.3 Submodule Working Trees (Embedded Clones)

Examples:

```
MATH476Spring2026/classlib
MATH476Spring2026/qmcsoftware
```

These are real working trees, but they are not the authoritative place to publish shared commits.

They are, however, often the most convenient place to edit shared files during Quarto preview.

---

## 2. The Three Fundamental Operations

1. Synchronize machines (make local clones match what is already pinned and published)
2. Publish shared changes (create/push commits in standalone repos)
3. Advance submodule pointers (move class repos to newer shared commits)

Each operation has one supported mechanism.

---

## 3. Scripts and Their Responsibilities

### 3.1 sync-class.sh — Machine Synchronization

- Pulls standalone repos and class repos
- Resets submodules to the pinned SHAs

Does not: advance pointers, commit, push.

---

### 3.2 publish-classlib-here.sh — Publish Shared Changes (Correct Commit Location)

Commits and pushes shared changes from the standalone repos (even if you edited inside a class repo submodule working tree).

Does not: advance pointers.

---

### 3.3 sync-class.sh --push — Advance Submodule Pointers (Progress)

Fast-forwards submodules to:
- classlib → main
- qmcsoftware → develop

Then commits and pushes the updated submodule pointers in the class repo.

Does not: create shared commits.

---

### 3.4 update-submodules.sh (Deprecated / Removed)

You may remember an older script named `update-submodules.sh` (sometimes living under `classlib/bin/` in a class repo) whose job was to advance submodule pointers without committing them.

That script is no longer part of the canonical workflow.

- The canonical copy was removed from class repos; the authoritative copy lives in SharedConfigs historically, but the workflow has moved on.
- Its functionality is now covered by:
  - `sync-class.sh` for “match pinned SHAs”
  - `sync-class.sh --push` for “advance to latest and commit pointers”

Rule:
- Do not use `update-submodules.sh` going forward.
- If you find an old copy in an older repo, treat it as legacy and prefer `sync-class.sh --push`.

---

## 4. Canonical Rules (Non-Negotiable)

- Shared code commits happen only in standalone repos.
- Class repos commit only course content and pointer updates.
- Pointer advancement is explicit via `sync-class.sh --push`.

---

## 5. Standard Workflows (Detailed)

### 5.1 Sit down at a Mac (latest and greatest baseline)

Default:

```
sync-class.sh
```

If something looks wrong in a specific repo:

```
git status --short
```

Preferred pinning check one-liner:

```
git -C classlib rev-parse HEAD && git -C ~/SoftwareRepositories/HickernellClassLib rev-parse origin/main
```

---

### 5.2 Editing only course files (class repo owned)

Edit course pages, schedule, local notebooks, policies, etc.

```
git add -A
git commit -m "Describe course change"
git push
```

If it affects published output:

```
./bin/render-site.sh
git add docs
git commit -m "Re-render site"
git push
```

---

### 5.3 Editing shared infrastructure (Python, Quarto assets, templates, shared notebooks)

This is the work reused across multiple class/talk repos.

#### A. What belongs shared vs local

Edit as shared if it is any of:
- general-purpose Python code imported by notebooks/pages
- shared Quarto YAML, CSS/SCSS, JS helpers
- shared images/logos used across sites/slides
- shared notebooks intended to be reused or imported
- anything under `classlib/quarto/...` intended to be consistent across courses

Keep local if it is any of:
- course-specific policies, grading, office hours, semester schedule
- course-specific problem sets, solutions, exams
- course-specific notebooks that you will not reuse
- course-specific one-off web pages

#### B. Critical distinction: where you EDIT vs where you COMMIT

There are two supported editing modes for shared code. They differ only in preview convenience.
In both modes, the final commit must be in the standalone repo.

##### Mode 1 — Preview-first (edit in class repo, commit via standalone)

Use this when Quarto preview ergonomics matter.

1) Edit shared files inside the class repo submodule working tree.

2) Preview locally in the class repo.

3) Publish the shared change (commit + push occurs in the standalone repo):

```
publish-classlib-here.sh "Describe shared change"
```

4) Advance pointers so this repo picks up the new shared commit:

```
sync-class.sh --push
```

5) If publishing web output, re-render and push:

```
./bin/render-site.sh
git add docs
git commit -m "Re-render site"
git push
```

##### Mode 2 — Library-first (edit and commit directly in standalone)

Use this when preview is secondary.

1) Edit and commit in the standalone repo:

```
cd ~/SoftwareRepositories/HickernellClassLib
git pull
git add -A
git commit -m "Describe shared change"
git push
```

2) In the class repo where you want to preview/use the change, advance pointers:

```
sync-class.sh --push
```

3) Preview/render in the class repo.

#### C. Checkpoint vs done (how broadly changes propagate)

- If only the current repo should pick up the change now: run `sync-class.sh --push` there.
- If multiple repos should pick it up: run `sync-class.sh --push` in each repo.
- If some repos should remain pinned (freeze): do not use `--push` there until you intentionally advance them.

---

## 6. Rendering and Publishing (why render-site.sh exists even with GitHub Actions)

GitHub Actions runs commands but does not understand your asset conventions.
render-site.sh defines the transformation from repo+submodules (dev layout) to a self-contained docs/ tree (publish layout).

Publishing:

```
./bin/render-site.sh
git add docs
git commit -m "Re-render site"
git push
```

---

## 7. One-Sentence Summary

> Sync for sanity, edit shared code wherever preview is easiest, commit shared code only from standalone repos, advance pointers explicitly, and publish only fully-materialized docs/ output.

---

Last updated: 2025-12-31

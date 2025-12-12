See also [[Mac Setup Status]] and [[Lessons Learned]].

This document serves as the high-level project tracker for all ongoing technical work across Macs, SharedConfigs, class repositories, LaTeX packages, teaching materials, and home tech.

Use this file for:
- tracking active projects  
- marking projects On Hold, Done, or Abandoned  
- linking to detailed notes elsewhere in the vault or in Git repos  

---

## LaTeX Packages

### fh-exam.sty (Active)
- Current baseline: **v3.18 (2025-12-04)**
- Handles geometry internally; no external geometry package in exams.
- New take-home exam style, updated instruction blocks, sidecar `.fhxtot`.
- Maintain backward compatibility with v3.18.
- When updating: synchronize version number, date, changelog.

### iitletterProf.cls (On Hold)
- Baseline: v2.2
- Integrated biblatex (authoryear) support.
- Stable accent and link colors.
- Bio placement logic refined.

---

## Course Development

### MATH 476 (Spring 2026) — Active
- Quarto-based course website.
- Increase default font sizes to match MATH565Fall2025.
- Add scatter plot icon in navbar.
- Move stable YAML/CSS into HickernellClassLib after finalizing layout.
- Build initial content incrementally.

### MATH 563 (Spring 2026) — Upcoming (depends on 476)
- Mirror the MATH 476 Quarto structure.
- Share as much CSS/SCSS/YAML as possible via ClassLib.

### MATH 565 (Fall 2026) — On Hold
- Maintain improvements document in the course repo.
- Build Kernels class in QMCPy for use next year.
- Improve Quarto slides, migrate Keynote concepts.
- Revisit MCMC packages next fall: emcee, PyMC (NUTS), and custom Metropolis.

---

## Python Ecosystem & QMCPy

### QMCPy Environment (Active)
- Upgrade schedule: **Dec 15, May 15, Aug 1**.
- Use `sync-qmcpy-env.sh` (editable install + develop branch).
- Compare `requirements-qmcpy-fred*.txt` with pyproject optional deps.
- Notebook header standardization (Colab cells).

### Submodule Workflows
- Always track QMCSoftware on the **develop** branch.
- Use update-submodules.sh for consistent syncing.
- Never modify submodules directly unless pushing upstream.

---

## SharedConfigs (Active)

- Maintain stable directories (bin, MacApps, settings, texmf, etc.)
- starship.toml under `settings/terminal/`
- MarkEdit configuration standardized (preview-light.css + JS).
- Consider Obsidian as the unified interface for personal notes.

---

## Mac Setup & Multi-Mac Sync

- Obsidian vault stored in SharedConfigs for cross-Mac access.
- Regular-maintenance.sh: consolidate brew, mas, tlmgr updates.
- Warp agent behavior — check bottom bar for “Use agent”.

---

## Home Tech

- Wi-Fi troubleshooting rules:
  - Eero red → reboot Eeros.
  - Eero “No Internet” → reboot Xfinity gateway.
  - Xfinity: white = good, blinking green = problem.

---

## Travel & PQP Tracking

- Maintain PQP scenario logic for 2025.
- Current memory: **10,932 PQP**.
- Only scenarios A–D in use (discard scenario E).

---

## Personal Tracking

- Chinese family names (Traditional):
  - Fred — 葉扶德  
  - Elaine — 朱憶令  
  - John — 葉基恩  
  - Christine — 葉天寧  

---

## Meta

- This Master Tech Projects file remains the authoritative tracker.
- Lessons Learned contains policies, workflows, and patterns that support these projects.
---
status: current
last-reviewed: 2026-08-24
---

# Jekyll to Quarto Course Migration

## Current implementation

The migration pattern is implemented for MATH 565:

- `MATH565Fall2025` remains the read-only Jekyll course-material reference.
- `MATH565Fall2026` is the active Quarto course repository.
- The Quarto website and RevealJS slide framework are established.
- `classlib` points to the shared `HickernellAcademicLib` repository, while `qmcsoftware` supplies the course software dependency.
- GitHub Actions renders the website and slides separately, assembles them under `_site`, and publishes the result to `gh-pages`.
- The workflow initializes `gh-pages` automatically when that branch is absent.

The remaining selective conversion of course content is ordinary course-authoring work, not an unresolved infrastructure migration. The authoritative operational instructions are `AUTHOR_WORKFLOW.md` in `MATH565Fall2026` and [[GitTracked/Workflows/Class & Talk Workflow|Class & Talk Workflow]].

## Reusable migration strategy

For another Jekyll course, fork forward instead of converting the old repository in place:

1. Create a new Quarto course repository.
2. Preserve the Jekyll repository as a read-only reference.
3. Re-author current material selectively in Quarto.
4. Keep course-specific structure and content in the course repository.
5. Put genuinely reusable styling, metadata, macros, pages, and presentation infrastructure in `HickernellAcademicLib`.

This avoids mixing site generators, layouts, and build logic.

## Content triage

Classify legacy content as:

1. **Re-author in Quarto** — syllabus, schedule, policies, assignments, tests, and notebook indexes that remain current.
2. **Link temporarily** — useful explanations or resources that do not yet justify conversion.
3. **Retire** — outdated announcements, obsolete policies, and layout-specific pages.

Do not require complete one-to-one parity before the new course site becomes useful.

## Current publishing model

Use the course repository's own setup and publishing instructions. For the MATH 565 implementation:

1. Clone with submodules:
   ```bash
   git clone --recurse-submodules https://github.com/fjhickernell/MATH565Fall2026.git
   ```
2. Install the documented Python and R dependencies.
3. Render the root website and the `slides` subproject independently.
4. Stage the rendered slides under `_site/slides`.
5. Push source changes to `main`; GitHub Actions publishes the assembled site to `gh-pages`.

Do not use the former manual `quarto publish gh-pages` initialization step for this repository; the current workflow creates the branch when needed.

## Confirmed lessons

- Jekyll to Quarto is a conceptual migration, not a mechanical conversion.
- Separating course content, computation, and shared infrastructure makes later courses easier to maintain.
- A working course framework can be published first and content converted incrementally.
- The prior course remains valuable as a reference without remaining part of the active publishing system.

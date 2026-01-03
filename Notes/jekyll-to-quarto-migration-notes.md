## Jekyll → Quarto Course Repo Migration (Notes)
**Context.**  
MATH565Fall2025 was built as a Jekyll site. For Fall 2026, the plan is to migrate the course website to **Quarto**, aligning it with MATH 476 and MATH 563 and the shared HickernellClassLib workflow.

This is not a mechanical “convert in place” operation. It requires a deliberate migration strategy.

### Recommended Strategy: Fork Forward

- Create a **new repository**: `MATH565Fall2026`
- Do **not** retrofit Quarto into the existing Jekyll repo
- Treat the Jekyll repo as an archival reference
- Re-author content selectively in Quarto

This avoids mixing site generators, layouts, and build logic.

### Content Triage Before Migrating

Classify existing Jekyll content into:
1. **Re-author in Quarto**
   - syllabus, schedule, policies  
   - homework / test pages  
   - notebooks index
2. **Link temporarily**
   - legacy explanations or resources not worth immediate porting
3. **Retire**
   - outdated announcements or layout-specific pages

Do *not* aim for 100% parity on day one.

### Shared Infrastructure Decisions

- Quarto theme, CSS, macros, and shared pages belong in **HickernellClassLib**
- Course-specific structure remains in `MATH565Fall2026`
- Reuse the established:
  - submodule layout (`classlib`, `qmcsoftware`)
  - GitHub Actions publish workflow
  - `gh-pages` branch publishing model

### Publishing & Initialization Checklist (Critical)

When creating the new Quarto repo:

1. Clone with submodules:
   ```bash
   git clone --recurse-submodules <repo-url>
   ```
2. Verify submodule remotes and branches immediately
3. Run locally **once**:
   ```bash
   quarto render
   quarto publish gh-pages --no-browser
   ```
   to initialize the `gh-pages` branch
4. Only then rely on GitHub Actions

Skipping step 3 causes CI failures complaining that `gh-pages` does not exist.

### Anticipated Lessons (to confirm during migration)

- Jekyll → Quarto is a **conceptual migration**, not a mechanical one
- Quarto enforces clearer separation of:
  - content
  - computation
  - shared infrastructure
- Early alignment with the MATH 476 / 563 workflow reduces semester friction

---
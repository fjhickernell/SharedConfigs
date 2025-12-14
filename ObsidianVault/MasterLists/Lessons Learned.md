# Lessons Learned

This document collects workflow insights, best practices, and cross-project behaviors that have proven useful across your Mac ecosystem, SharedConfigs, class repos, QMC software work, and general technical workflow.

---

## 1. System & Mac Workflow

### SharedConfigs is the “single source of truth” for personal configuration
- SharedConfigs lives in iCloud for cross-Mac sync.
- Git commits act as snapshots, not the primary syncing mechanism.
- Do **not** store Git repos inside SharedConfigs; store _configs_, not _projects_.
- Keep scripts in SharedConfigs/bin and symlink or call them from ~/bin.

### Using Git safely with SharedConfigs
- sharedconfigs-save.sh should pull changes _before_ commit only to integrate iCloud changes.
- iCloud is faster and authoritative for updates; Git is archival.

### Password prompts behavior
- sudo -v at script start suppresses repeated mas prompts.
- Homebrew _still_ requires password for privileged casks.
- tlmgr **always** asks for its password — no avoiding that.

### Warp Terminal
- Warp’s AI agent panel must be **enabled** to restore full suggestions.
- Settings sync across Macs may lag until an update triggers the new UI.
- Starship prompt is independent of Warp’s AI agent.

### MarkEdit
- Preferred setup:
  - Editor theme = dark
  - Preview = light with preview-light.css
  - Custom markedit-preview.js
  - Unified settings.json in SharedConfigs/settings/

---

## 2. Teaching, Class Repos & Course Development

### Submodules workflow (classlib + qmcsoftware)
- Always track QMCSoftware using the **develop** branch.
- Use update-submodules.sh in each course repo for consistent pulls.
- Avoid manual edits inside submodules — always change upstream.

### Quarto workflow
- Incrementally refine course sites and slide templates inside each repo.
- After stabilizing styles (CSS / SCSS / YAML / macros), move them into HickernellClassLib/classlib/quarto/.
- Some themes used in the past required compiling .scss → .css.
- Later: apply the same theme stack to MATH 563 after MATH 476 is established.

### Slides & HTML notebooks
- Add IDs if you want hyperlinks between slides or back-links from HTML.
- Animated plots should be GIF or embedded video formats for portability.

### Student installation workflow
- Test using a clean Test User account on macOS.
- Add reminder: verify this process every December 15 (low priority).

---

## 3. QMC Software, Python Environments & Scripts

### QMCPy environment maintenance
- Upgrade cadence: **Dec 15**, **May 15**, **Aug 1**.
- Use sync-qmcpy-env.sh to fetch develop branch and reinstall in editable mode.
- Maintain additional requirements files (requirements-qmcpy-fred*.txt), but periodically reconcile them with QMCPy’s pyproject.toml.

### Notebook best practices
- Use nbstripout checks (bin/check-nbstripout.sh).
- Always keep a “clean-output” version for distributing to students.

### Keister, Asian Option, GD/Rosenbrock demos
- Keep stable versions in HickernellClassLib.
- Push experimental versions to course repos only.

---

## 4. LaTeX, Exams, and Documents

### fh-exam.sty baseline (v3.18, 2025-12-04)
- Handles geometry internally — don’t load geometry in exam docs.
- Quartiles & SD only (no IQR).
- Stem-and-leaf uses extbar separator.
- Adds mathtools as required package.
- Take-home exam mode: \examstyle{takehome}.
- Updated instruction blocks, AI disclaimers, sidecar .fhxtot totals.
- When updating: always sync **version number + date + changelog**.

### iitletterProf.cls
- v2.2 baseline (2025-10-29).
- Uses accent iitred, fixed hyperref colors, refined autobio behavior, integrated biblatex (authoryear).

### Common mistake
- Always include \iitsetup{...} in letters — you often forget this.

---

## 5. Build, Rendering & Publishing Pipelines

This section collects lessons about build systems, rendering workflows, and deployment constraints (especially GitHub Pages).

### Cleaning and inspecting build artifacts
- Safest workflow:
  - quarto render
  - inspect output
  - confirm generated .html files are intentional

### GitHub Pages constraints
- GitHub Pages only serves files under docs/.
- Local quarto preview can read submodule files directly.
- GitHub Pages **cannot** — submodule assets must be materialized into docs/.

### Quarto websites and slides
- [[Lessons-Learned-Quarto-RevealJS|Quarto + RevealJS (website + slides)]]

---

## 6. Git & Submodules (General Lessons)

### Case-insensitive filesystem issues
- macOS uses a case-insensitive filesystem.
- Git may require enabling **reftable** backend if remotes contain case-only-differing references.

### Submodule pointer updates
- Commit and push submodule pointer updates from the top-level repo.
- Never modify submodule contents directly unless you intend to push upstream.

---

## 7. Cross-Mac Setup Knowledge

### Keyboard mapping issues (external Windows keyboard)

Fix requires:
1. Quit Karabiner
2. Delete keyboard preferences (com.apple.keyboardservicesd.plist, etc.)
3. defaults delete -g com.apple.keyboard.modifiermapping
4. Restart cfprefsd, keyboardservicesd
5. Sign out or reboot
6. Plug keyboard back in → run Keyboard Setup Assistant → ANSI → remap Option/Command

### Wi-Fi troubleshooting (Hickmansion vs Hacienda)
- Eero app shows “No Internet” → reboot Xfinity gateway.
- Devices can’t connect to Hacienda Wi-Fi → reboot Eeros.
- Gateway lights: solid white = healthy; blinking green = connection issue.
- Eero lights: white = healthy; red = lost Internet; blue blinking = setup.

---

## 8. Travel, PQP, Credit Cards & Finance

### United PQPs
- Weekly posting pattern for MileagePlus Club card; United site is sufficiently current.
- Track scenarios A–D (0, 600, 1000, 1200 purchased PQPs).
- Scenarios E+ discarded.
- Current PQP memory: **10,932 PQP**.
- United PQP Tracker: https://docs.google.com/spreadsheets/d/1X8bhsqqMSya4roLsFoEThirm1YEE94ct/edit?gid=1347819413#gid=1347819413

### Chase Sapphire rules
- 48-month rule from last Sapphire welcome bonus applies.
- Authorized user status does **not** reset the timer.

---

## 9. Personal Notes & Miscellaneous

### Chinese names (Traditional)
- Fred — 葉扶德
- Elaine — 朱憶令
- John — 葉基恩
- Christine — 葉天寧

### Warp agent UI
- Bottom bar contains:
  - Use agent toggle
  - Slash commands
  - Voice input
  - Attach context
  - Attach image

These disappear if agent mode is disabled.

---

## 🟦 END OF FILE

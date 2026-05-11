# fh-exam.sty Baseline (v3.18 — 2025-12-04)

This note documents the stable baseline for fh-exam.sty and must remain consistent with the actual package.

## Version
- **v3.18 (2025/12/04)**

## Key Behaviors
- Package handles `geometry` internally (default margin = 1 inch).
- Users should **not** load the geometry package in exam documents.
- Quartiles and SD only; **no IQR**.
- Stem-and-leaf uses the `extbar` separator (not math `|`).
- Uses `extbackslash` and `\ProvidesExplPackage`.
- Requires `mathtools`.

## New Features in v3.18
- Take-home exam mode: `\examstyle{takehome}`.
- Updated instruction blocks, including AI-allowed and no-human-help wording.
- Sidecar `.fhxtot` total output.
- Refactored spacing and instruction systems.

## Updating the Package
When modifying fh-exam.sty:
1. Update the version number.
2. Update the date.
3. Update the changelog in the file.
4. Avoid breaking backward compatibility with v3.18.

## Related Notes
- [[MasterLists/Master Tech Projects|Master Tech Projects]]
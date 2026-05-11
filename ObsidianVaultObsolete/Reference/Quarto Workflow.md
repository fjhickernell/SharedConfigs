# Quarto Workflow

This note summarizes the core workflow for developing Quarto-based course websites and slides.

---

## General Workflow

1. Experiment with YAML, CSS, and SCSS locally inside each course repo.
2. Once a theme stabilizes, move reusable components into HickernellClassLib under:
   classlib/quarto/
3. Validate theme and layout using test notebooks and example pages.
4. Build course content incrementally while refining structure.

---

## Slide Development

- Add slide IDs to allow hyperlinks between slides and from HTML pages.
- Animated plots (especially timing demos) should be GIF or MP4 for browser compatibility.
- Store custom Quarto macros in HickernellClassLib for portability.
- Keep experimental slide templates in the course repo until stable.

---

## Course Roadmap

### MATH 476 (Spring 2026)
- Increase default font sizes to match or approach MATH565Fall2025.
- Add scatter-plot icon to navbar.
- After stabilizing design, migrate shared theme components into HickernellClassLib.

### MATH 563 (Spring 2026)
- Mirror the structure built for MATH 476.
- Apply the same shared SCSS/CSS/YAML layouts from ClassLib.

### MATH 565 (Fall 2026)
- Maintain improvements document in the MATH565Fall2025 repo.
- Revisit slide templates, kernels class, and MCMC package options.

---

## Notes

- Historically, some Quarto themes required SCSS → CSS compilation.
- When reorganizing Quarto files, consider upstream compatibility with HickernellClassLib.
- Build each course structure one component at a time to keep transitions clean.

---

## Related

- [[Software/classlib|HickernellClassLib]]
- [[MasterLists/Master Tech Projects]]
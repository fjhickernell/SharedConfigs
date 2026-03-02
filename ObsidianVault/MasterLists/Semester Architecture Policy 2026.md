*(Fred Edition --- 2026 Draft)*

## Foundation

As a follower of Christ, my work in teaching, research, and infrastructure development is ultimately an act of service to Him. I seek to approach my academic responsibilities with “work produced by faith, labor prompted by love, and endurance inspired by hope in our Lord Jesus Christ” (1 Thessalonians 1:3), and to “work heartily, as for the Lord and not for men” (Colossians 3:23). This policy exists not merely to optimize systems, but to steward time, attention, and technical skill in a way that honors Christ and serves my students and academic community faithfully and well.

## Context

After serving in academic administration from late 2018 through the end
of 2024, I returned to full-time teaching and research with a strong
desire to:

-   Update myself with modern AI tools
-   Modernize teaching infrastructure
-   Strengthen research workflows
-   Provide students exposure to current technologies

This has created productive momentum --- but also tension:

> When should I push forward with infrastructure improvements, and when
> should I wait?

This document formalizes a decision policy to reduce that tension.

------------------------------------------------------------------------

# Operating Modes

## 🟢 Mode 1 --- Delivery & Stability (Default During Active Teaching)

This is the **default during the semester**.

### Allowed

-   Bug fixes
-   Friction reduction
-   Automating repetitive tasks
-   Backward-compatible refinements
-   Clarifying documentation
-   Small, contained improvements

### Not Allowed

-   Core workflow redesign
-   Structural repo changes
-   Submodule architecture changes
-   Foundational tool switching
-   Cross-repo metadata restructuring
-   Refactoring purely for elegance

### Rule

> If the change touches multiple repositories structurally, defer.

------------------------------------------------------------------------

## 🟡 Mode 2 --- Local Experiments (Sandboxed Exploration)

This satisfies the need to stay modern and sharp.

### Allowed

-   AI experimentation
-   New Quarto features
-   Alternate rendering approaches
-   New workflow prototypes
-   Emerging research tools

### Constraints

-   Must live in `experimental` or equivalent
-   Must not alter canonical pipelines
-   Must not modify shared infrastructure
-   Must be safely discardable

This preserves intellectual growth without destabilizing production
systems.

------------------------------------------------------------------------

## 🔵 Mode 3 --- Architecture Season (Scheduled)

This is intentional structural evolution.

### Allowed

-   Workflow redesign
-   Metadata consolidation
-   Environment strategy changes
-   Major TeX Live upgrades
-   Cross-machine synchronization resets
-   Introducing new shared conventions

### Timing

-   Early summer
-   Winter break
-   Never mid-semester

Architecture season is scheduled, not reactive.

------------------------------------------------------------------------

# Decision Framework

When considering a change, ask:

### 1. Does this reduce long-term entropy?

If yes → candidate for integration.

### 2. Does this expand surface area across repos?

If yes → defer unless in Architecture Season.

### 3. Does this require a new mental model?

If yes → avoid mid-semester.

### 4. Is this fixing pain or chasing elegance?

Pain → act.
Elegance → backlog

------------------------------------------------------------------------

# Reframing the Tension

The feeling of "another steep climb" arises because:

-   Infrastructure maturity increases consequence of change.
-   Improvements become more architectural than visible.
-   Stability raises the bar for modification.

This is not regression.
It is ecosystem maturity.

------------------------------------------------------------------------

# Important Perspective

Current infrastructure includes:

-   Reproducible conda environments
-   Modular Quarto architecture
-   Automated exam table generation
-   Git submodule discipline
-   Multi-machine configuration control
-   AI-assisted workflows

This is not behind.

This is advanced.

------------------------------------------------------------------------

# Core Guiding Principle

During the semester:

> I may adopt new tools.
> I may not restructure the ecosystem because of them

Students benefit more from:

-   Stability
-   Clarity
-   Polished materials
-   Thoughtful integration

Than from rapid platform churn.

------------------------------------------------------------------------

# Identity Clarification

This tension is not about technical capability.
It is about transitioning from:

-   Administrator → Builder
-   Builder → Ecosystem Maintainer

Infrastructure has no summit.
It has plateaus.

The goal is not constant ascent.
The goal is controlled evolution.

------------------------------------------------------------------------

# Closing Policy

During semester: - Optimize delivery.
- Contain experimentation.
- Defer architecture.

During breaks: - Revisit structure.
- Consolidate improvements.
- Modernize deliberately.

Stability is not stagnation.
It is leverage.

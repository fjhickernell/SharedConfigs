# Class / ClassLib / Tests Workflow (Terse)

## Step 1 --- Arrive

Run: arrive

------------------------------------------------------------------------

## Step 2 --- Edit (Prototype Mode: fast, local)

-   Edit in:
    -   Course repo (e.g., MATH476Spring2026)
    -   HickernellClassLib
    -   HickernellTestsArchive
-   Render slides/notebooks locally (e.g., quarto-slides-live).
-   No push required to see local effects.
-   Python helpers in classlib are visible immediately via the qmcpy
    environment.

------------------------------------------------------------------------

## Step 2a --- Promote ClassLib Changes

If you changed HickernellClassLib:

1.  Commit + push in HickernellClassLib.
2.  From a clean course repo, run: publish-classlib-here.sh (or simply:
    depart)

------------------------------------------------------------------------

## Step 2b --- Promote Tests Archive Changes

If you changed HickernellTestsArchive:

1.  Commit + push in assets/tests/archive.
2.  Run: depart

------------------------------------------------------------------------

## Step 2c --- Promote Course-Only Changes

If you changed only a course repo:

1.  Commit + push (VS Code / GitKraken).
2.  Run: depart

------------------------------------------------------------------------

## Step 3 --- Other Machines

On other machines: arrive

------------------------------------------------------------------------

## Rule

Prototype locally. Promote intentionally.

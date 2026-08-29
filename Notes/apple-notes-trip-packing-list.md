# Apple Notes Trip Packing Lists

## Purpose

Create each new trip packing list from the most recent comparable trip note,
preserving Apple Notes headings, indentation, and native checklists while
resetting checked items to unchecked.

The user will make trip-specific edits after the starter note is created.

## Current convention

- Packing lists are Apple Notes whose titles include the trip dates and
  destination or occasion.
- The August 2026 starter note is in the Apple Notes `Hubby&Hunny` folder:
  `Grace and Tae’s Wedding, Boston, August 29–31, 2026`.
- That note was modeled on `2026 June 17–23 San Diego Wedding`.

## Recommended future workflow

1. In Apple Notes, locate the most recent relevant trip packing list. Resolve
   "most recent" from the note titles and dates rather than from conversation
   memory.
2. Select the source note in the Notes interface.
3. Use **File → Duplicate Note**. This is essential: native duplication
   preserves checklist state, headings, indentation, and other Notes-only
   formatting.
4. Rename the duplicate to the new trip's name, destination, and dates.
5. Put the insertion point in any checklist item, then use
   **Format → More → Uncheck All**. Verify the entire note, not only the
   visible portion, has no checked circles.
6. Confirm that the duplicate is in the intended folder, normally the same
   folder as the source.
7. Verify the visible title and the first few sections before handing the note
   back for trip-specific manual edits.

## Automation prerequisites

- Codex must be enabled in **System Settings → Privacy & Security →
  Accessibility** so it can use Notes menu commands.
- Apple Notes must be signed in and synchronized with iCloud.
- If browser access is needed for visual verification, iCloud Notes must be
  signed in separately in that browser.

## Important Apple Notes limitations

- Do not recreate the note by reading and writing the AppleScript `body`
  property. AppleScript exposes a simplified HTML rendering that omits native
  checklist metadata. Writing that HTML back produces ordinary lists rather
  than real checklists.
- Do not copy and paste the entire note through iCloud Notes in a browser.
  In the August 2026 attempt, browser copy/paste flattened headings, removed
  checklist formatting, and joined text together.
- AppleScript's `duplicate` command does not work for Notes, even though the
  Notes application has a **Duplicate Note** menu item. Use the menu through
  accessibility automation.
- Setting a note's AppleScript `name` property can identify or temporarily
  rename a duplicate, but the visible title is derived from the first line of
  the note. Verify the title in the Notes interface after synchronization.
- Avoid direct edits to `NoteStore.sqlite` or its protobuf data. That approach
  requires Full Disk Access and risks corrupting the live Notes database.

## Recovery and cleanup

If an attempted duplicate loses formatting, do not repair it piecemeal.
Duplicate the untouched source again with **File → Duplicate Note**, verify the
replacement, and move the malformed attempt to Recently Deleted only with the
user's approval.

After cleanup, verify that exactly one active note has the intended trip title;
copies in Recently Deleted do not count as active notes.

## Suggested request for a future trip

> Create a new Apple Notes packing list for [trip name, destination, and dates]
> by duplicating the most recent relevant trip packing list. Preserve the native
> formatting and checklists, reset every checklist item to unchecked, and leave
> the new note ready for my manual edits. Follow
> `Notes/apple-notes-trip-packing-list.md`.


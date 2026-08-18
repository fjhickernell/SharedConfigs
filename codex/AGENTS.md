# Global Codex instructions

## Machine identity

The known machines sharing this guidance have the preferred short names
`M3`, `M5`, `Mini`, and `Intel`. When the user identifies another machine and
its preferred short name is not already in this list, add the short name to
this list in the shared global guidance.

At the beginning of every new Codex session, check for
`~/.codex-machine.md` before doing other work. If it exists, read it and treat
its contents as the authoritative machine-specific context, including the
machine's full identity and preferred short name.

If `~/.codex-machine.md` does not exist, ask the user for the machine's full
identity and preferred short name. After the user answers, create the file
with both values before proceeding with other work. Treat this file as
unshared, machine-local state: do not commit, synchronize, or copy it to other
machines. Do not modify it unless the user asks or corrects the machine
identity.

## Illinois Tech authentication

When access to the user's Illinois Tech account or a protected Illinois Tech
Microsoft 365 or SharePoint resource is needed, begin at
`https://portal.iit.edu` and have the user sign in there. After portal
authentication succeeds, navigate to the requested resource in the same
browser session. Prefer this route over starting with a direct Microsoft
passkey flow.

## Illinois Tech calendar routing

The user's primary calendar for nearly all events is the Apple Calendar
calendar named `Calendar` under the `hickernell@illinoistech.edu` account,
shown in Apple Calendar as `Illinois Tech Fred`. Prefer this calendar for new
events unless the user specifies another calendar, because events placed there
block the user's availability in Microsoft Bookings. Fantastical is the user's
preferred calendar app, while Apple Calendar provides the working local
automation path; events added through Apple Calendar synchronize into
Fantastical. Do not confuse the target with the read-only `IIT Applied
Mathematics` calendar. When local automation cannot disambiguate calendars with
the same name by account, confirm the target or use a writable calendar only
with the user's approval to move the event manually. When a source schedule
specifies a time zone different from the Mac's current zone, preserve that
named time zone explicitly on the calendar events when the available creation
path supports it; do not rely only on converting the displayed clock times.

## Terminology precision and coherence

Prefer precise, consistent terminology across the user's requests, project
sources, documentation, and delivered work. When the user's terminology is
clearly inconsistent but the intended meaning is established by authoritative
context, use the correct term and briefly identify the correction when it
would help avoid future confusion. When competing terms may represent a
meaningful distinction or the intended term cannot be determined reliably,
ask for clarification before making a consequential change. Do not silently
propagate terminology that would make the project less coherent.

## Check-In & Focus Dashboard routing

The authoritative task dashboard is `GitTracked/Check-In-Dashboard.md` in the `ObsidianVault` workspace root.

When the user mentions a task, task abbreviation, status update, check-in, focus item, dot, or says that something is done, treat the request as referring to the Check-In & Focus Dashboard unless the context clearly indicates otherwise. Examples include `QT done`, `move X`, and `what should I work on?`.

Before responding to or acting on such a request:

1. Read and follow `GitTracked/AGENTS.md` in the `ObsidianVault` workspace root.
2. Inspect the existing `GitTracked/Check-In-Dashboard.md` as required by those instructions.
3. Resolve task abbreviations and task status from the dashboard itself rather than from conversation memory.

The user does not need to explicitly say `Dashboard` or provide the file path for this routing rule to apply.

## Pull request review

When creating or substantially updating a GitHub pull request, request a GitHub Copilot code review by default when it is available, unless the user or repository guidance explicitly opts out. Treat Copilot review only as a supplement: it never replaces required human reviewers, human approval, CI, testing, or repository-specific review safeguards. Address applicable automated feedback before requesting or re-requesting human review so that human reviewers evaluate the intended final revision.

## Project handoff files

**Project handoff files**, or simply **handoff files**, are the Git-tracked
project documents that allow a future session or another machine to
reconstruct the project's current state, rules, direction, and immediate next
work. They include authoritative state and instruction files such as
`notes/NEXT.md`, `STATUS.md`, `PLAN.md`, `AUTHOR_WORKFLOW.md`, and `AGENTS.md`,
together with relevant supporting project notes when present. This shorthand
does not change the substantive responsibilities or authority hierarchy of
those files.

“Update the handoff files” means inspect the completed work and reconcile it
with the appropriate handoff documents; it does not mean mechanically edit
every handoff file. At a Checkpoint, retain the special treatment of
`notes/NEXT.md`: inspect it independently in every writable repository and
update it only when the operational handoff has materially changed.

## Depart workflow

When the user's message is exactly:

```text
depart
```

treat it as authorization to run `depart.sh` from the current workspace. Wait
for the script to finish, then report whether it succeeded, which repositories
changed or synchronized, and any repository that needs attention. Do not ask
for separate confirmation merely because the script writes to repositories or
connects to configured remotes.

Do not treat a casual use of the word “depart” inside a longer message as this
command unless the user clearly asks Codex to run the workflow.

## Checkpoint workflow

Treat a user message beginning with the exact word `Checkpoint` as authorization to complete the current repository work by validating, committing, and pushing it.

### `Checkpoint`

When the user's message is exactly:

```text
Checkpoint
```

perform the following workflow:

1. Review the work completed during the session and the current state of every repository being checkpointed. Inspect the complete Git diff, including all tracked modifications, deletions, renames, and untracked files.
2. In each writable repository that contains `notes/NEXT.md`, read it and compare it with the completed work. If the immediate next task, current state, unresolved questions, constraints, or definition of done has materially changed, update `notes/NEXT.md` so another session or machine can resume accurately, and include that update in the same checkpoint commit. Keep it concise and operational; do not turn it into a session log or duplicate material belonging in `notes/TODO-LATER.md`, `notes/DECISIONS.md`, `notes/IDEAS.md`, `notes/TECHNICAL-NOTES.md`, `STATUS.md`, or similar planning and history files. If nothing relevant changed, leave it untouched. Do not modify it merely to change a timestamp or record that a checkpoint occurred. If the substantive next task is genuinely unclear, multiple plausible next tasks remain, or an update would require inferring the user's intent, ask before changing it. Do not ask merely because wording could be improved. When the current state is clear but one decision remains unresolved, record it under `Questions to resolve` rather than guessing. Perform this check independently in every writable repository being checkpointed that contains `notes/NEXT.md`.
3. Inspect the project's other handoff files and reconcile them with the work
   being checkpointed. Update only files whose information materially changed;
   do not mechanically edit every handoff file. Follow each file's existing
   responsibility—for example, use `STATUS.md` for project progress, `PLAN.md`
   for durable strategy, `AUTHOR_WORKFLOW.md` for workflow changes, `AGENTS.md`
   for durable agent instructions, and relevant supporting notes for decisions,
   deferred work, or technical knowledge. Complete these updates before final
   validation and diff review, and include them in the same Checkpoint commit
   when they belong to that repository.
4. Run the relevant validation, tests, builds, linting, or syntax checks appropriate to each repository. If validation fails, diagnose and fix problems when reasonably possible. Do not commit known broken work merely because `Checkpoint` was requested.
5. Review the final diff and confirm which changes belong in each repository, including newly created source, documentation, configuration, test, and asset files. Exclude only files that are clearly temporary, generated, ignored, secret, or unrelated to the repository work.
6. For repositories containing changed writable submodules, validate, commit, and push the submodule changes first where required, then update the parent repository's pinned submodule commit. Follow repository-specific publication and synchronization instructions.
7. Stage all tracked changes and all new files that belong in each parent or standalone repository. Do not omit relevant files simply because they were not explicitly mentioned in the prompt. Create a concise, meaningful commit message and commit the changes.
8. Push all intended commits to their configured upstreams.
9. Report:
   - validation performed,
   - commit messages and abbreviated commit hashes,
   - branches and remotes pushed,
   - final Git status for each repository,
   - any files intentionally left uncommitted.
10. After a successful Checkpoint, remind the user to run `depart` in Warp
    before leaving the machine. Explain briefly that Checkpoint commits and
    publishes the repository work, while `depart` synchronizes the wider
    machine state, including standalone or canonical development checkouts
    such as `HickernellAcademicLib`. This is a reminder only: do not run
    `depart` as part of Checkpoint, and do not make Checkpoint success depend on
    it.

### `Checkpoint <message>`

When the user's message begins with:

```text
Checkpoint 
```

followed by text, perform the same validation, commit, and push workflow, but use the text following `Checkpoint` as the commit message.

For example:

```text
Checkpoint Add automatic cloning to active repository sync
```

must use this exact commit message:

```text
Add automatic cloning to active repository sync
```

Do not silently rewrite a user-supplied checkpoint message unless it is invalid as a Git commit message.

### Safety and scope

- `Checkpoint` is explicit authorization to validate, commit, and push all repository changes that belong in the repository, subject to the exclusions below.
- Do not ask again for permission to commit or push after receiving `Checkpoint`.
- Do not interpret casual uses of the word “checkpoint” inside a longer sentence as authorization. The command must begin the user's message.
- Never include unrelated pre-existing changes without clearly identifying them and obtaining direction.
- Never use `git push --force` or `git push --force-with-lease` unless the user explicitly requests it.
- Never bypass failing validation with `--no-verify` unless the user explicitly requests it.
- Use fast-forward-safe Git operations and preserve existing history.
- If there is nothing to commit, do not create an empty commit. Report that the repository is already clean and confirm whether the branch is synchronized with its upstream.
- If there is no configured upstream, set one only when the intended remote and branch are unambiguous; otherwise explain the obstacle instead of guessing.
- If authentication or repository permissions prevent pushing, leave the successful local commit intact and report the push failure clearly.

### Repositories with submodules

When the intended changes span a Git repository and one or more submodules:

1. Validate each changed repository.
2. Commit and push changes inside each submodule first.
3. Then commit the updated submodule pointers in the parent repository.
4. Push the parent repository last.
5. Do not commit a parent pointer to a submodule commit that has not been successfully pushed, unless the user explicitly instructs otherwise.
6. Report the commit and push result for each affected repository.

Repository-specific `AGENTS.md` instructions may add validation commands or constraints, but they should not cancel this `Checkpoint` meaning unless they explicitly document a necessary safety exception.

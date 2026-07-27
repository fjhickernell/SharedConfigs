# Global Codex instructions

## Checkpoint workflow

Treat a user message beginning with the exact word `Checkpoint` as authorization to complete the current repository work by validating, committing, and pushing it.

### `Checkpoint`

When the user's message is exactly:

```text
Checkpoint
```

perform the following workflow:

1. Review the current work and the Git diff, including all tracked modifications, deletions, renames, and untracked files.
2. Confirm which changes belong in the repository, including newly created source, documentation, configuration, test, and asset files, and exclude only files that are clearly temporary, generated, ignored, secret, or unrelated to the repository work.
3. Run the relevant validation, tests, builds, linting, or syntax checks appropriate to the repository.
4. If validation fails, diagnose and fix problems when reasonably possible. Do not commit known broken work merely because `Checkpoint` was requested.
5. Stage all tracked changes and all new files that belong in the repository. Do not omit relevant files simply because they were not explicitly mentioned in the prompt.
6. Create a concise, meaningful commit message based on the completed work.
7. Commit the changes.
8. Push the current branch to its configured upstream.
9. Report:
   - validation performed,
   - commit message,
   - abbreviated commit hash,
   - branch and remote pushed,
   - final Git status.

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

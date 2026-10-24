# Scripts

Small, deterministic helpers for running the lifecycle in `docs/lifecycle.md`.
They use the `gh` CLI and POSIX shell only, so they run from Claude Code's
Bash tool on Windows (Git Bash), macOS, and Linux.

## stage.sh

Move an issue between lifecycle stages. Keeps exactly one `stage:*` label on
the issue and posts a comment for every transition.

```sh
scripts/stage.sh 5                       # print current stage, or "none"
scripts/stage.sh 5 plan                  # refine → plan, comment "Stage: refine → plan"
scripts/stage.sh 5 build "Plan posted."  # same, with a note under the first line
scripts/stage.sh 5 close "Merged in #6." # remove stage label, comment, close
```

Valid stages: `refine plan build test evidence assess review merge`, plus
`close`. Anything else exits with status 2 and changes nothing. Returning to an
earlier stage is allowed; put the reason in the note.

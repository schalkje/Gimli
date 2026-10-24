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
scripts/stage.sh 5 close "Merged in #6." # comment, remove stage label, close
```

Valid stages: `refine plan build test evidence assess review merge`, plus
`close`. Anything else exits with status 2 and changes nothing. Returning to an
earlier stage is allowed; put the reason in the note. Words after the stage are
joined into the note, so quoting is optional.

Behaviour worth knowing:

- The comment is posted before the label changes, so a failure part way leaves
  a documented but unmoved issue rather than a moved but undocumented one.
- Moving to the stage the issue is already in prints `already at <stage>` and
  changes nothing.
- `close` on an issue GitHub already closed still posts the comment and removes
  the label. Moving a closed issue to a stage reopens it.
- A `stage:*` label that is not one of the nine stages aborts the script; fix
  the label by hand first.

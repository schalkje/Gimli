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

## risk.sh

Set the risk tier on an issue or a pull request; both take the same number
argument. Keeps exactly one `risk:*` label and posts a comment for every
change. Same argument handling as `stage.sh`.

```sh
scripts/risk.sh 5                         # print current tier, or "none"
scripts/risk.sh 5 medium                  # none → medium, comment "Risk: none → medium"
scripts/risk.sh 5 high "Touches auth."    # same, with a note under the first line
```

Valid tiers: `low medium high critical`, from `docs/risk-assessment.md`.
Anything else exits with status 2 and changes nothing. Words after the tier
are joined into the note, so quoting is optional.

Behaviour worth knowing:

- The comment is posted before the label changes, for the same reason as in
  `stage.sh`.
- Setting the tier the issue already has prints `already risk:<tier>` and
  changes nothing.
- Every other `risk:*` label is removed, so an issue that somehow carries two
  risk labels ends with exactly one. The target label is never passed to
  `--remove-label`: `gh` applies removals last, and removing and adding the
  same label would leave the issue with none.
- A `risk:*` label that is not one of the four tiers aborts the script before
  anything is posted; fix the label by hand first.
- Closed issues are not reopened; a tier can be recorded on a closed issue.

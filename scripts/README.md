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

## guard.sh

Decide whether a non-interactive skill run may post a comment under a
heading, so that a run repeated by a schedule or a retry against an untouched
issue does not post the same comment again. This is the duplicate guard in
`.claude/skills/_shared/preamble.md`, section 4.

```sh
scripts/guard.sh 5 "## Plan: draft"   # exit 0 post, 1 skip; prints one reason line
```

The rule looks only at the most recent comment on the issue:

1. No comments: post.
2. Its first line, with trailing whitespace and carriage return removed, is
   not exactly the heading: post.
3. It is headed by the heading but was edited after it was posted
   (`includesCreatedEdit`), meaning someone answered in place: post.
4. The issue body last changed (`lastEditedAt`, or `createdAt` if the body was
   never edited) after that comment was posted: post.
5. Otherwise: skip. Equal timestamps count as not after, so the guard errs
   towards not posting a duplicate.

Timestamps are compared as ISO 8601 UTC strings inside `gh`'s `--jq`, so no
platform `date` parsing is involved.

| Exit | Meaning | stdout |
|---|---|---|
| 0 | Post | `post: <reason>` |
| 1 | Do not post | `skip: <comment url> posted <time>; body last changed <time>, not after it` |
| 2 | Usage error: not exactly two arguments, a non-numeric issue, or an empty heading. `gh` is not called. | usage or error on stderr |
| 3 | `gh` failed, for example the issue does not exist | error on stderr |

A failure exits 3, never 0 or 1, so a caller cannot mistake it for a decision.

## lib.sh

Not a command. A library of helpers sourced by `stage.sh`, `risk.sh`, and
`guard.sh` with `. "$(dirname "$0")/lib.sh"`, so it is found next to the
calling script whatever the working directory. It holds only what at least two
of them use: usage printing from the caller's header comment, the issue-number
check, argument and note parsing, the membership and canonical-label checks,
and single `gh` calls to post a comment or edit labels. Rules that belong to
one script, such as posting the comment before changing labels or `risk.sh`
never removing its target label, stay in that script.

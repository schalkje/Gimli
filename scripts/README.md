# Scripts

Part of the [Gimli documentation](../README.md#documentation).

Small, deterministic helpers for running the lifecycle in `docs/lifecycle.md`.
They use the `gh` CLI and POSIX shell only, so they run from Claude Code's
Bash tool on Windows (Git Bash), macOS, and Linux.

## stage.sh

Move an issue between lifecycle stages. Keeps exactly one `stage:*` label on
a work item, none on a parent issue, and posts a comment for every transition.

```sh
scripts/stage.sh 5                       # print current stage, or "none"
scripts/stage.sh 5 plan                  # refine → plan, comment "Stage: refine → plan"
scripts/stage.sh 5 build "Plan posted."  # same, with a note under the first line
scripts/stage.sh 5 close "Merged in #6." # comment, remove stage label, close
scripts/stage.sh 46 parent "Roadmap."    # comment, remove stage label, keep open
```

Valid stages: `refine plan build test evidence assess review merge`, plus
`close` and `parent`. Anything else exits with status 2 and changes nothing.
`parent` marks a [parent issue](../docs/lifecycle.md#parent-issues): it posts
`Stage: <old> → parent` and removes the stage label without closing or
reopening; on an issue without a stage label it prints `no stage label` and
changes nothing. Returning to an
earlier stage is allowed; put the reason in the note. Words after the stage are
joined into the note, so quoting is optional.

Behaviour worth knowing:

- The comment is posted before the label changes, so a failure part way leaves
  a documented but unmoved issue rather than a moved but undocumented one.
- Moving to the stage the issue is already in prints `already at <stage>` and
  changes nothing.
- `close` on an issue GitHub already closed still posts the comment and removes
  the label. Moving a closed issue to a stage reopens it.
- A `stage:*` label that is not one of the eight stages aborts the script; fix
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
| 3 | `gh` failed, for example the issue does not exist, or `lib.sh` is not next to the script | error on stderr |

A failure exits 3, never 0 or 1, so a caller cannot mistake it for a decision.
The number may be an issue or a pull request. The heading is trimmed of
trailing whitespace like the comment's first line, and must be one line.

## route.sh

Print the agent, model and effort for a task of a change folder, from its
Kind and Complexity in `tasks.md`. `/build` runs it for each task it hands to
an agent. Reads nothing and calls no `gh`.

```sh
scripts/route.sh implement high   # gimli-implement opus high
scripts/route.sh docs low         # gimli-docs haiku low
```

The output is one line, `<agent> <model> <effort>`. The table it implements,
and what each `docs` complexity level means, are in the
[task routing spec](../docs/specs/task-routing/spec.md#requirement-route-1-route-a-task-by-kind-and-complexity).
An unknown kind or complexity, or a number of arguments other than two,
exits with status 2 and prints nothing on standard output; the message goes
to standard error.

Changing the table means changing the spec and this script together; the
test below fails until they agree.

## trace.sh

Report, for every scenario of every capability spec, whether it is tested,
evidenced, marked not yet, failing or uncovered. It is run at the
[Test stage](../docs/lifecycle.md#5-test). Calls no `gh`.

```sh
scripts/trace.sh                        # docs/specs and scripts/tests
scripts/trace.sh <specs> <tests>        # other directories
```

It reads `<specs>/*/spec.md`, except `_template`, and runs every
`<tests>/*_test.sh` with `sh`, so a full run takes a minute or two on
Windows. The output is one line per scenario, `<ID> <status> <source>`:

| Status | Meaning | Source |
|---|---|---|
| `tested` | A test file exits 0 and prints `ok <ID>:` | the test file name |
| `evidence` | The scenario's `**Verified by:**` line holds a Markdown link | the text |
| `not-yet` | Its Verified by line starts `not yet`, in any case | the reason |
| `failing` | A test prints a `FAIL <ID>:` line, or its file exits non-zero | the file |
| `uncovered` | None of the above, including Verified by text that is neither | `-` |

Standard error names each test file that exits non-zero, with the last
five lines of its standard error, each code block left open, each
`#### Scenario` line that is not a well-formed heading, and each scenario
ID used by more than one heading, with file and line; headings inside
fenced code blocks are skipped.

The Verified by format is in the [spec format](../docs/specs/README.md).

| Exit | Meaning |
|---|---|
| 0 | No scenario is uncovered or failing, every test file exited 0, and every scenario heading is well formed with its own ID |
| 1 | A scenario is uncovered or failing, a test file exited non-zero, or a scenario heading is malformed or reuses an ID |
| 2 | Usage error: not zero or two arguments, or a path that is not a folder |

The rules are the [traceability spec](../docs/specs/traceability/spec.md);
why they are so is [ADR 0005](../docs/adr/0005-traceability.md).

## Tests

Tests live in `scripts/tests/`, one POSIX shell file per script, and run
without network or `gh`:

```sh
sh scripts/tests/route_test.sh
sh scripts/tests/trace_test.sh
```

Each prints one line per check and a summary, and exits non-zero if any
check fails. `route_test.sh` reads the routing table from the task routing
spec and checks `route.sh` against every cell, then the invalid-input
scenarios. `trace_test.sh` checks `trace.sh` against the traceability spec.
Running the tests in CI is later work.

**Naming convention.** A test proves a scenario by printing
`ok <ID>: <description>` for a passing check and `FAIL <ID>: ...` for a
failing one, each starting in column 1; one or more spaces after `ok` or
`FAIL` are allowed. It exits non-zero when any check fails. `trace.sh` runs every
`scripts/tests/*_test.sh`, so tests are POSIX shell, fast and offline.

## protect-main.sh

Apply the repository settings and the `protect-main` ruleset that make `main`
accept changes only through a squash-merged pull request. What they enforce,
the exact calls, and how to undo them are in `docs/repository-settings.md`.

```sh
scripts/protect-main.sh                   # the repository of the current directory
scripts/protect-main.sh schalkje/Gimli    # a named repository
```

Behaviour worth knowing:

- It changes live repository settings, not files. Run it only when the owner
  asks; `CLAUDE.md` says Claude does not change the ruleset otherwise.
- The merge settings are patched first, then the ruleset is created or
  updated. A failure part way can leave the settings changed and the ruleset
  not; running the script again completes it.
- The ruleset is found by name among the repository's own rulesets. None:
  `POST` creates it. One: `PUT` replaces it in place, so a second run leaves
  one ruleset with the same id. More than one: exit 1 before touching the
  ruleset, naming the ids.
- It prints the resulting merge settings and ruleset, so its output is
  evidence of what was applied.

| Exit | Meaning |
|---|---|
| 0 | Settings and ruleset applied and printed |
| 1 | More than one ruleset named `protect-main`, with the ids on stderr; delete the extras by hand. Or a `gh` call failed, with its error on stderr |
| 2 | Usage error: more than one argument, or not `<owner>/<repo>`. `gh` is not called |

## lib.sh

Not a command. A library of helpers sourced by `stage.sh`, `risk.sh`,
`guard.sh`, `protect-main.sh`, `route.sh` and `trace.sh` with `. "$(dirname "$0")/lib.sh"`, so it is
found next to the calling script whatever the working directory. It holds only what at least two
of them use: usage printing from the caller's header comment, the issue-number
check, argument and note parsing, the membership and canonical-label checks,
and single `gh` calls to post a comment or edit labels. Rules that belong to
one script, such as posting the comment before changing labels or `risk.sh`
never removing its target label, stay in that script.

# Shared skill preamble

Every lifecycle stage skill starts by following this file. The skill that
cites it supplies three things: the **expected stage** label, the **writes**
a non-interactive run may make (for most skills, a list of comment headings),
and the rest of its own procedure.
Everything here is about the lifecycle contract (`docs/lifecycle.md`, the
`stage:*` labels, `scripts/stage.sh`, `scripts/risk.sh`); nothing here is
specific to one repository.

## 1. Arguments

- The issue number is the **first word** of the skill's arguments with any
  leading `#` removed. Ignore everything after it.
- If that is not a plain number, say so and stop.
- Never pass the raw arguments to a command; pass only the parsed number.

## 2. Session mode

Decide now, before reading anything, whether this session is:

- **interactive**: you can use `AskUserQuestion`, or the user can reply; or
- **non-interactive**: a `claude -p` run, a hook, a scheduled run, or any
  session with no way to ask and wait for an answer.

In a non-interactive session a run makes only the writes its skill declares
for that mode, and nothing else. Anything the skill does not declare,
including editing the issue body, posting a confirmed artifact, changing a
label, moving the stage, or pushing, is forbidden in that mode. When unsure
which mode applies, treat the session as non-interactive.

Temporary files, such as a comment body to pass with `--body-file`, go in the
session's scratchpad directory when one is given, otherwise in the system
temporary directory. Never write them inside the repository.

## 3. Stage check

Read the issue:

```sh
gh issue view <n> --json title,body,state,labels,comments
```

- The stage is the `stage:*` label in the output. If it is not the expected
  stage, or the issue is closed, say which condition failed and stop. Only
  continue if the user explicitly tells you to.
- Read every comment before acting. `Stage:` transition comments from
  `scripts/stage.sh` and `Risk:` comments from `scripts/risk.sh` carry the
  notes that explain how the issue got here. Comments headed by one of the
  skill's own headings are earlier runs of the skill; the skill says what to
  do with each kind.

## 4. Duplicate guard

A non-interactive run is often repeated, by a schedule or a retry, against an
issue nobody has touched. Before posting a comment under heading `H`:

```sh
scripts/guard.sh <n> "<H>"
```

- **Exit 0:** post.
- **Exit 1:** nothing has changed since the skill last spoke. Post nothing,
  and quote the script's `skip:` line in your report; it names the existing
  comment and the timestamps compared.
- **Any other status:** post nothing and report the error.

The guard is by heading and timestamp, not by content: a regenerated comment
rarely matches the previous one word for word, so comparing text would not
stop the duplicate. Any newer comment, a body edit, or an edit to the guarded
comment re-arms the skill. A title or label change alone does not. The exact
rule is in `scripts/README.md`, section `guard.sh`.

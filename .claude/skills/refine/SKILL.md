---
name: refine
description: Run the Refine stage of the Gimli lifecycle on a GitHub issue. Reads the issue, reports gaps against the work item template, asks the user about them in small batches, drafts the refined body, and only after confirmation writes it back and moves the issue to the Plan stage.
argument-hint: <issue-number>
disable-model-invocation: true
---

# /refine $ARGUMENTS

You are running the **Refine** stage of `docs/lifecycle.md`. Refine is a
conversation, not a rewrite: the goal is to leave the issue sufficiently
defined for Plan, with the user's decisions recorded, not yours.

The section list comes from `.github/ISSUE_TEMPLATE/work-item.yml` and the
exit criteria from the Refine stage in `docs/lifecycle.md`. Read both before
you start; do not work from memory of them.

## 0. Determine the issue number and the session mode

- The issue number is the **first word** of `$ARGUMENTS` with any leading `#`
  removed. Ignore everything after it. If that is not a plain number, say so
  and stop. Never pass `$ARGUMENTS` itself to a command.
- Decide now whether this session is **interactive** (you can use
  `AskUserQuestion` or the user can reply) or **non-interactive** (a
  `claude -p` run, or no way to ask). In a non-interactive session you will
  stop at the end of step 2 and never write the body or move the stage.

## 1. Read the issue and check its stage

```sh
gh issue view <n> --json title,body,state,labels,comments
```

- The stage is the `stage:*` label in the output. If it is not `stage:refine`,
  or the issue is closed, say so and stop. Only continue if the user
  explicitly tells you to.
- Read every comment: earlier refinement or discussion may already answer
  questions you would otherwise ask. A comment headed `## Refine: proposals`
  is a previous non-interactive run; start from it.

## 2. Gap report, before any question

Compare the body against the template sections, in template order. For each
section say one of: **complete**, **weak** (present but not meeting the Refine
exit criteria), or **missing**. Judge against the exit criteria:

- acceptance criteria are specific and testable, numbered `AC1`, `AC2`, ...;
- expected test evidence names what will prove each criterion;
- scope states what is in and what is out;
- a preliminary risk tier is proposed with a reason. `Unknown` is the form
  default, not a tier; only Low, Medium, High, or Critical count.

Show the gap report to the user as a short table. Then:

- **Every section complete:** say so and propose moving to Plan. In an
  interactive session, on the user's agreement, skip straight to the
  `scripts/stage.sh` call in step 6 and leave the body untouched.
- **Non-interactive session:** post the gap report and your proposed answers
  to every gap as one comment headed `## Refine: proposals`, then stop. Do
  not edit the body or move the stage.
- Otherwise continue.

## 3. Ground yourself in the codebase

Before asking anything, look at the parts of the repository the issue touches
so your questions and proposed answers are concrete. Use `Grep`, `Glob`, and
`Read`. Note affected files and existing patterns for the Technical
considerations section. Keep this short; you are refining, not planning.

## 4. Ask about gaps, in batches

- At most four questions per batch. Start with the gaps that change the shape
  of the work (goal, scope, acceptance criteria), then the rest.
- Every question carries a proposed answer the user can accept by saying so.
  Prefer `AskUserQuestion` with the proposal as the first, recommended option.
- When a question could be answered by reading the code or an existing doc,
  answer it yourself and present it as a proposal instead.
- If the issue is too large for one pull request, say so and propose a split:
  what stays in this issue and what becomes new issues. Only after the user
  agrees, create each new issue with the template's title prefix and a body
  that carries every template heading, with a link back to the parent:

  ```sh
  gh issue create --title "[Work item]: <title>" --label stage:refine --body-file <path>
  ```

## 5. Draft, then confirm

Write the full refined body using the headings you read from the template, as
`### <Label>` in template order, with the Scope section's **In scope** and
**Out of scope** lists and acceptance criteria as `- [ ] AC<n>: ...` lines,
one per criterion.

Keep the user's wording where it was good; tighten where it was vague. Keep
any content that sits outside the template sections. Show the complete draft
and ask for confirmation. **Do not write to the issue until the user
confirms.** If they ask for changes, revise and show again.

## 6. Write back and move the stage

Once confirmed, save the body to a file in your scratchpad and apply it:

```sh
gh issue edit <n> --body-file <path-to-draft>
scripts/stage.sh <n> plan "Refine complete: <one line on what changed>."
```

The note should say what the conversation decided, for example which scope
items were cut or which criteria were added, so the Plan stage can see it
without diffing the body. If the body was already complete and left
untouched, say so in the note.

## 7. Report

Tell the user: the issue link, the stage it is now at, the decisions recorded,
and any new issues created by a split. Suggest `/plan <n>` as the next step if
that skill exists.

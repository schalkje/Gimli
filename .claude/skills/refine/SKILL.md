---
name: refine
description: Run the Refine stage of the Gimli lifecycle on a GitHub issue. Reads the issue, reports gaps against the work item template, asks the user about them in small batches, drafts the refined body, and only after confirmation writes it back and moves the issue to the Plan stage.
argument-hint: <issue-number>
disable-model-invocation: true
---

# /refine $ARGUMENTS

You are running the **Refine** stage of `docs/lifecycle.md` on issue `$ARGUMENTS`.
Refine is a conversation, not a rewrite: the goal is to leave the issue
sufficiently defined for Plan, with the user's decisions recorded, not yours.

The section list comes from `.github/ISSUE_TEMPLATE/work-item.yml` and the
exit criteria from the Refine stage in `docs/lifecycle.md`. Read both before
you start; do not work from memory of them.

## 1. Read the issue and check its stage

```sh
scripts/stage.sh $ARGUMENTS
gh issue view $ARGUMENTS --json title,body,state,labels,comments
```

- If the stage is not `refine`, or the issue is closed, say so and stop. Only
  continue if the user explicitly tells you to.
- Read every comment: earlier refinement or discussion may already answer
  questions you would otherwise ask.

## 2. Gap report, before any question

Compare the body against the template sections, in template order. For each
section say one of: **complete**, **weak** (present but not meeting the Refine
exit criteria), or **missing**. Judge against the exit criteria:

- acceptance criteria are specific and testable, numbered `AC1`, `AC2`, ...;
- expected test evidence names what will prove each criterion;
- scope states what is in and what is out;
- a preliminary risk tier is proposed with a reason.

Show the gap report to the user as a short table. If every section is
complete, say so, skip to step 5, and propose moving to Plan.

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
  what stays in this issue and what becomes new issues. Only create the new
  issues (with `gh issue create --label stage:refine` and a link back) after
  the user agrees.

**Non-interactive sessions:** if you cannot ask (no `AskUserQuestion`, or a
`claude -p` run), post the gap report and your proposed answers as a comment
on the issue, prefixed `## Refine: proposals`, and stop. Do not edit the body
or move the stage.

## 5. Draft, then confirm

Write the full refined body using the template headings in order:

```
### Goal
### Scope            (with **In scope** and **Out of scope** lists)
### Requirements
### Acceptance criteria   (- [ ] AC1: ... one per line)
### Technical considerations
### Expected test evidence
### Preliminary risk tier
```

Keep the user's wording where it was good; tighten where it was vague. Show
the complete draft and ask for confirmation. **Do not write to the issue until
the user confirms.** If they ask for changes, revise and show again.

## 6. Write back and move the stage

Once confirmed, save the body to a file in your scratchpad and apply it:

```sh
gh issue edit $ARGUMENTS --body-file <path-to-draft>
scripts/stage.sh $ARGUMENTS plan "Refine complete: <one line on what changed>."
```

The note should say what the conversation decided, for example which scope
items were cut or which criteria were added, so the Plan stage can see it
without diffing the body.

## 7. Report

Tell the user: the issue link, the stage it is now at, the decisions recorded,
and any new issues created by a split. Suggest `/plan $ARGUMENTS` as the next
step if that skill exists.

---
name: plan
description: Run the Plan stage of the Gimli lifecycle on a GitHub issue. Checks the issue is ready, inspects the codebase, drafts an implementation plan with a risk tier, and only after confirmation posts it on the issue, applies the risk label, and moves the issue to Build.
argument-hint: <issue-number>
disable-model-invocation: true
---

# /plan $ARGUMENTS

You are running the **Plan** stage of `docs/lifecycle.md`. The exit criteria
come from the Plan stage there and the risk scoring from
`docs/risk-assessment.md`. Read both before you start; do not work from memory
of them.

## 0. Determine the issue number and the session mode

- The issue number is the **first word** of `$ARGUMENTS` with any leading `#`
  removed. Ignore everything after it. If that is not a plain number, say so
  and stop. Never pass `$ARGUMENTS` itself to a command.
- Decide now whether this session is **interactive** (you can use
  `AskUserQuestion` or the user can reply) or **non-interactive** (a
  `claude -p` run, or no way to ask). In a non-interactive session you will
  post a draft and stop; you will never post a `## Plan` comment, change a
  label, or move the stage.

## 1. Read the issue and check its stage

```sh
gh issue view <n> --json title,body,state,labels,comments
```

- The stage is the `stage:*` label in the output. If it is not `stage:plan`,
  or the issue is closed, say so and stop. Only continue if the user
  explicitly tells you to.
- Read every comment. A comment headed `## Plan: draft` is a previous
  non-interactive run; start from it. A `## Refine: proposals` comment or the
  `Stage: refine → plan` note may carry decisions the body summarises.

## 2. Check the Refine exit criteria

Before planning, confirm the body is plannable:

- the `### Acceptance criteria` section has one or more `AC<n>:` lines;
- each criterion is specific enough that you can name a test or check that
  would prove it;
- scope states what is in and what is out;
- expected test evidence is named.

If any of these fail, do **not** draft a plan. Name each failing criterion
and what is missing. In an interactive session, offer to return the issue to
Refine; only on the user's agreement run:

```sh
scripts/stage.sh <n> refine "Returned from Plan: <what was missing>."
```

In a non-interactive session, post the failing criteria as a comment headed
`## Plan: not ready` and stop.

## 3. Inspect the codebase

Look at the parts of the repository the issue touches: the files that will
change, the patterns already in place that the change should follow, and the
tests or checks that exist. Bounded: enough to name files and tests, not to
implement. Use `Grep`, `Glob`, and `Read`.

## 4. Draft the plan

Use exactly this structure; the plan comment on issue #7 is the worked
example.

```
## Plan

### Steps
Numbered, concrete, in build order. Say where to branch from.

### Files affected
One bullet per file or area, marked (new) where applicable.

### Tests
| Criterion | Proof |
One row per AC<n> in the issue body, in order. Proof is a named test,
check, or evidence item.

### Risk assessment
| Dimension | Finding | Floor |
One row per dimension in docs/risk-assessment.md, then the test coverage
adjustment, then:
**Tier: `risk:<tier>`.** One or two sentences of justification. State
whether human acknowledgement is required before Build.
```

Decide design questions in the draft rather than asking batches of
questions; one confirmation round is the expectation. If a decision is
genuinely the user's, make a recommendation in the draft and mark it.

## 5. Confirm, or post the draft and stop

- **Interactive:** show the complete draft and ask for confirmation. Do not
  post it, change a label, or move the stage until the user confirms. If they
  ask for changes, revise and show again. The user may also override the
  tier; record the override and its reason in the justification.
- **Non-interactive:** save the draft to a file in your scratchpad, post it
  with `gh issue comment <n> --body-file <path>` under the heading
  `## Plan: draft` instead of `## Plan`, and stop.

## 6. Apply

Once confirmed, save the final plan to a file in your scratchpad and apply it
in this order:

```sh
gh issue comment <n> --body-file <path-to-plan>
gh issue edit <n> --remove-label "<any existing risk:* label>" --add-label "risk:<tier>"
```

Omit `--remove-label` if the issue has no risk label. Then, by tier:

- **low or medium:** `scripts/stage.sh <n> build "Plan posted, risk:<tier>."`
- **high or critical:** leave the issue at `stage:plan` and tell the user that
  a human must acknowledge the plan on the issue, with a comment or reaction,
  before Build starts. Moving to Build after that is done by hand with
  `scripts/stage.sh <n> build "Plan acknowledged by <who>."`.

## 7. Report

Tell the user: the issue link, the plan comment link, the tier, the stage the
issue is now at, and whether anything is waiting on a human. Suggest
`/build <n>` as the next step if that skill exists.

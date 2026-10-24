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
  `claude -p` run, or no way to ask). In a non-interactive session the only
  thing you may write is a single comment headed `## Plan: draft` or
  `## Plan: not ready`; you never post a `## Plan` comment, change a label,
  or move the stage.

## 1. Read the issue and check its stage

```sh
gh issue view <n> --json title,body,state,labels,comments
```

- The stage is the `stage:*` label in the output. If it is not `stage:plan`,
  or the issue is closed, say so and stop. Only continue if the user
  explicitly tells you to.
- Read every comment and classify the most recent ones from this skill:
  - `## Plan: draft` from a previous non-interactive run: start from it.
  - `## Plan: not ready`: the issue was already found unplannable; check
    whether the body has changed since, and if not, skip to step 2's
    not-ready handling without posting a duplicate.
  - `## Plan` (a confirmed plan) with the issue still at `stage:plan`: this is
    either a high or critical plan waiting for acknowledgement, or an issue
    returned to Plan from a later stage. Look for a human comment or reaction
    after the plan. If the plan was acknowledged, tell the user and, in an
    interactive session, offer to run the Build transition from step 6
    instead of re-planning. If the issue was returned with a reason, start
    from the existing plan and produce a superseding one; say in its first
    line which comment it supersedes.
- The `Stage: refine → plan` note and any `## Refine: proposals` comment may
  carry decisions the body summarises.

## 2. Check the Refine exit criteria

Before planning, confirm the body is plannable:

- the `### Acceptance criteria` section has one or more `AC<n>:` lines;
- each criterion is specific enough that you can name a test or check that
  would prove it;
- scope states what is in and what is out;
- expected test evidence is named;
- a preliminary risk tier is proposed: Low, Medium, High, or Critical.
  `Unknown` is the form default, not a tier.

If any of these fail, do **not** draft a plan. Name each failing criterion
and what is missing. In an interactive session, offer to return the issue to
Refine; only on the user's agreement run:

```sh
scripts/stage.sh <n> refine "Returned from Plan: <what was missing>."
```

In a non-interactive session, post the failing criteria as a comment headed
`## Plan: not ready` and stop, unless the latest comment is already an
identical `## Plan: not ready` from this skill, in which case post nothing
and say so.

## 3. Inspect the codebase

Look at the parts of the repository the issue touches: the files that will
change, the patterns already in place that the change should follow, and the
tests or checks that exist. Bounded: enough to name files and tests, not to
implement. Use `Grep`, `Glob`, and `Read`.

## 4. Draft the plan

Use exactly this structure.

```
## Plan

### Steps
Numbered, concrete, in build order. Say where to branch from.

### Files affected
One bullet per file or area, marked (new) where applicable.

### Tests
| Criterion | Proof |
Exactly one row per AC<n> in the issue body, in order; never group
criteria. Proof is a named test, check, or evidence item.

### Risk assessment
| Dimension | Finding | Floor |
One row per dimension in docs/risk-assessment.md, then the test coverage
adjustment, then:
**Tier: `risk:<tier>`.** One or two sentences of justification. State the
preliminary tier from the issue body and whether this confirms or changes
it, and whether human acknowledgement is required before Build.
```

Tier rules:

- Score the dimensions yourself; do not copy the preliminary tier.
- If your tier is **lower** than the preliminary tier, say so plainly. The
  preliminary tier was set by a person during Refine, and
  `docs/risk-assessment.md` says lowering a human-set tier needs that
  person's agreement: in an interactive session ask the confirming user
  whether they agree and record the answer; in a non-interactive session
  keep the preliminary tier in the draft and flag the proposed lower tier.
- If your tier is **higher**, use yours and explain what raised it.

Decide design questions in the draft rather than asking batches of
questions; one confirmation round is the expectation. If a decision is
genuinely the user's, make a recommendation in the draft and mark it.

## 5. Confirm, or post the draft and stop

- **Interactive:** show the complete draft and ask for confirmation. Do not
  post it, change a label, or move the stage until the user confirms. If they
  ask for changes, revise and show again. The user may override the tier;
  record the override and its reason in the justification.
- **Non-interactive:** save the draft to a file in your scratchpad and post
  it with `gh issue comment <n> --body-file <path>` under the heading
  `## Plan: draft` instead of `## Plan`, then stop. If the latest comment is
  already a `## Plan: draft` from this skill with the same content, post
  nothing and say so.

## 6. Apply

Once confirmed, save the final plan to a file in your scratchpad and apply it
in this order:

1. `gh issue comment <n> --body-file <path-to-plan>`
2. Set the risk label so that exactly one `risk:*` label remains:
   - if the issue already carries `risk:<tier>`, change nothing;
   - if it carries a different `risk:*` label, run
     `gh issue edit <n> --remove-label "risk:<old>" --add-label "risk:<tier>"`;
   - if it carries none, run `gh issue edit <n> --add-label "risk:<tier>"`.
   Never pass the same label to both `--remove-label` and `--add-label`;
   `gh` applies the removal last and the issue ends with no risk label.
3. By tier:
   - **low or medium:** `scripts/stage.sh <n> build "Plan posted, risk:<tier>."`
   - **high or critical:** leave the issue at `stage:plan` and tell the user
     that a human must acknowledge the plan on the issue, with a comment or
     reaction, before Build starts. Moving to Build after that is done by hand
     with `scripts/stage.sh <n> build "Plan acknowledged by <who>."`.

## 7. Report

Tell the user: the issue link, the plan comment link, the tier and whether it
changed from the preliminary one, the stage the issue is now at, and whether
anything is waiting on a human. Suggest `/build <n>` as the next step if that
skill exists.

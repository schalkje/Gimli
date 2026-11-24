---
name: plan
description: Run the Plan stage of the Gimli lifecycle on a GitHub issue. Checks the issue is ready, inspects the codebase, drafts an implementation plan with a risk tier (for a large change, as a change folder), and only after confirmation posts it on the issue (for a change folder, after committing the folder and opening the draft pull request), applies the risk label, and moves the issue to Build.
argument-hint: <issue-number>
disable-model-invocation: true
---

# /plan $ARGUMENTS

You are running the **Plan** stage of `docs/lifecycle.md`. The exit criteria
come from the Plan stage there and the risk scoring from
`docs/risk-assessment.md`. Read both before you start; do not work from memory
of them.

## 0. Preamble

Read `../_shared/preamble.md`, relative to this skill's base directory, and
follow it with:

- expected stage: `stage:plan`;
- comment headings a non-interactive run may post: `## Plan: draft` and
  `## Plan: not ready`. A non-interactive run never posts a `## Plan`
  comment.

Classify the most recent comments from this skill:

- `## Plan: draft` from a previous non-interactive run: start from it.
- `## Plan: not ready`: the issue was already found unplannable. The
  preamble's duplicate guard decides in step 1 whether to say so again.
- `## Plan` (a confirmed plan) with the issue still at `stage:plan`: this is
  either a high or critical plan waiting for acknowledgement, or an issue
  returned to Plan from a later stage. Look for a human comment or reaction
  after the plan. Comments headed `Stage:` or `Risk:` are helper output, not
  acknowledgement, even though they carry a person's login; the `Risk:`
  comment from step 5 always follows the plan. If the plan was acknowledged,
  tell the user and, in an
  interactive session, offer to run the Build transition from step 5
  instead of re-planning. If the issue was returned with a reason, start
  from the existing plan and produce a superseding one. Keep the heading
  exactly `## Plan` and say on the line after it which comment it
  supersedes, so `/build` still recognises the plan.

The `Stage: refine → plan` note and any `## Refine: proposals` comment may
carry decisions the body summarises.

## 1. Check the Refine exit criteria

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

In a non-interactive session, apply the preamble's duplicate guard for the
heading `## Plan: not ready`; if it allows posting, post the failing criteria
as a comment under that heading. Either way, stop.

## 2. Inspect the codebase

Look at the parts of the repository the issue touches: the files that will
change, the patterns already in place that the change should follow, and the
tests or checks that exist. Bounded: enough to name files and tests, not to
implement. Use `Grep`, `Glob`, and `Read`.

## 2a. Choose the form of the plan

Read "When a change gets a folder" in `docs/changes/README.md` and decide:

- **Comment plan:** none of the criteria hold. The plan is one comment, in the
  structure of step 3.
- **Change folder:** a criterion holds. Say which in the draft. The plan is a
  change folder plus a shorter comment, as step 3 describes.

For a change folder, find where it lives before drafting anything:

- **An open pull request for the issue:** look it up as `/build` does, with
  `gh pr list --state open --search "Closes #<n> in:body"` and the same check
  that `Closes #<n>` is followed by a non-digit or the end of the line. Its
  head branch is the change branch; never open a second branch or pull
  request for the issue.
- **Otherwise:** derive the branch name per the Conventions in `CLAUDE.md`.
  If that branch exists locally or on `origin`, a previous run got this far
  and it is the change branch. Otherwise the branch is created in step 5
  from `origin/main`.

If the change branch already holds `docs/changes/<n>-<slug>/`, read it
without checking the branch out (`git fetch origin` and
`git show <branch>:<path>`, or `origin/<branch>`) and start the draft from it:
keep every task's ID and status, give new tasks new IDs, and mark a task
whose work the new plan drops `deferred` with the reason in its text, never
deleting it. Otherwise start from the templates in
`docs/changes/_template/`, following the formats in
`docs/changes/README.md`.

Write the draft folder in your scratchpad, not in the repository: Plan does
not switch branches or write repository files before the user confirms.
A non-interactive run never creates a branch or writes files in the
repository: its `## Plan: draft` comment carries the draft folder files
inline instead.

## 3. Draft the plan

For a comment plan, use exactly this structure.

```
## Plan

### Steps
Numbered, concrete, in build order. Say where to branch from.

### Files affected
One bullet per file or area, marked (new) where applicable.

**Documentation:** the documents this change updates under the
documentation rule in docs/lifecycle.md, each with what changes, or
`None, because <reason>`.

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

For a change folder, the folder holds the steps (`tasks.md`), the design and
the spec deltas, and its `design.md` "Where it lands" section is the
Documentation entry. The comment holds only what the folder does not, in
this structure:

```
## Plan

Change folder: docs/changes/<n>-<slug>/, linked twice: on the change branch,
for until merge, and on main, where the link keeps working once the branch
is deleted. The draft pull request #<pr>. Which folder criterion applies.

### Tests
As above.

### Risk assessment
As above.
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

Documentation entry (in the comment, or in `design.md` for a change folder):
read the "Documentation rule" section of
`docs/lifecycle.md` and name each document it covers whose described
behaviour this change alters, including the index and README map entries a
new document needs under "Where a new document goes" in
`docs/documentation-model.md`. When the change makes a decision that
`docs/adr/README.md` says needs an ADR, name the new ADR here too. `/build`
treats each named document as a step.
Write `None, because <reason>` only when no covered document describes what
the change alters; a bare `None` does not meet the Plan exit criteria.

Decide design questions in the draft rather than asking batches of
questions; one confirmation round is the expectation. If a decision is
genuinely the user's, make a recommendation in the draft and mark it.

## 4. Confirm, or post the draft and stop

- **Interactive:** show the complete draft, and for a change folder the
  draft folder's files from step 2a, and ask for confirmation. For a change
  folder, say which branch applying it commits to and pushes, and whether it
  opens a draft pull request or uses the existing one. Do not commit, push, post, change a label, or
  move the stage until the user confirms. If they
  ask for changes, revise and show again. The user may override the tier;
  record the override and its reason in the justification.
- **Non-interactive:** apply the preamble's duplicate guard for the heading
  `## Plan: draft`. If it allows posting, save the draft to a file in your
  scratchpad and post it with `gh issue comment <n> --body-file <path>` under
  the heading `## Plan: draft` instead of `## Plan`. Either way, stop.

## 5. Apply

Once confirmed, save the final plan to a file in your scratchpad and apply it
in this order. For a change folder, first bring the branch and pull request
up to date. Each step checks whether it is already done, so a rerun after a
failure repeats this list and skips what earlier runs completed:

1. Refuse to continue on a dirty working tree (`git status --porcelain` is
   not empty): say what is uncommitted and stop.
2. Check out the change branch from step 2a: `git fetch origin`, then
   `git checkout <branch>` and `git pull --ff-only` if it exists, otherwise
   `git checkout -b <branch> origin/main`. If the pull fails, the branch has
   diverged from the remote; stop and say so.
3. Copy the draft folder from the scratchpad to `docs/changes/<n>-<slug>/`,
   and add its row to the index in `docs/changes/README.md` if it is missing.
4. Commit only if `git status --porcelain` shows changes:
   `Add the change folder for #<n>`, or `Update the change folder for #<n>`
   when the folder existed, with `Refs #<n>` and this session's attribution
   lines in the body.
5. Push only if the branch has no upstream or is ahead of it
   (`git rev-list --count @{u}..HEAD` is not 0): `git push -u origin <branch>`.
6. Use the pull request from step 2a if there is one; otherwise look it up
   again as in step 2a, in case a previous run opened it, and if there is
   still none, open the draft pull request as `/build` does, from
   `.github/PULL_REQUEST_TEMPLATE.md` with the Summary written,
   `Closes #<n>`, and the attribution lines:
   `gh pr create --draft --base main --title "<issue title without the [Work item]: prefix>" --body-file <path>`.
7. Put the pull request number and the folder link in the comment.

If one of these fails, stop before posting anything and report which steps
completed; the next run repeats them and skips what is done. Then:

1. `gh issue comment <n> --body-file <path-to-plan>`
2. `scripts/risk.sh <n> <tier> "Plan posted."` It leaves exactly one
   `risk:*` label on the issue and is a no-op when the tier already matches.
3. By tier:
   - **low or medium:** `scripts/stage.sh <n> build "Plan posted, risk:<tier>."`
   - **high or critical:** leave the issue at `stage:plan` and tell the user
     that a human must acknowledge the plan on the issue, with a comment or
     reaction, before Build starts. Moving to Build after that is done by hand
     with `scripts/stage.sh <n> build "Plan acknowledged by <who>."`.

## 6. Report

Tell the user: the issue link, the plan comment link, for a change folder the
branch and draft pull request, the tier and whether it changed from the
preliminary one, the stage the issue is now at, and whether
anything is waiting on a human. Suggest `/build <n>` as the next step if that
skill exists.

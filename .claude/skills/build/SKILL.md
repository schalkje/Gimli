---
name: build
description: Run the Build stage of the Gimli lifecycle on a GitHub issue. Takes the confirmed plan on the issue (for a large change, the tasks in its change folder, each handed to the agent the routing table gives), implements it on a branch with step-sized commits, records deviations, and after confirmation pushes the branch, opens the draft pull request unless Plan already did, and moves the issue to Test. Runs unattended only for risk:low issues.
argument-hint: <issue-number>
disable-model-invocation: true
---

# /build $ARGUMENTS

You are running the **Build** stage of `docs/lifecycle.md`. Build turns the
confirmed plan into commits on a branch and a draft pull request. It does not
run the test suite, fill the pull request's evidence, or mark it ready: those
are later stages.

Read the Build stage of `docs/lifecycle.md` and the Conventions section of
`CLAUDE.md` before you start; do not work from memory of them.

## 0. Preamble

Read `../_shared/preamble.md`, relative to this skill's base directory, and
follow it with:

- expected stage: `stage:build`;
- writes a non-interactive run may make: **none, unless the issue carries
  `risk:low`**. For a `risk:low` issue a non-interactive run may push the
  branch, post one comment headed `## Build: deviation`, open the draft pull
  request, run `scripts/stage.sh <n> test`, and, if publishing fails part
  way, post one comment headed `## Build: incomplete`. Nothing else. The
  preamble's duplicate guard is for repeated runs that would say the same
  thing again; it does not apply to these two headings, which report what
  this run did.

In a non-interactive session on an issue whose risk label is anything other
than `risk:low`, or that has no `risk:*` label, say that Build for this tier
needs an interactive session and stop. Do this before touching git: no
branch, no comment, no label change.

## 1. Entry checks

- Find the plan: the most recent comment whose first line is exactly
  `## Plan`. Comments headed `## Plan: draft` or `## Plan: not ready` are not
  plans. A superseding plan keeps that heading and says on the line after it
  which comment it replaces; the most recent `## Plan` is authoritative.
- Read every existing `## Build: deviation` comment: what they record is
  already on the issue and is not posted again.
- If there is no `## Plan` comment, say so and stop. In an interactive
  session offer to return the issue to Plan; only on the user's agreement run:

  ```sh
  scripts/stage.sh <n> plan "Returned from Build: no confirmed plan."
  ```

- Read the most recent `Stage: … → build` comment. On a first build it is the
  Plan transition. On re-entry (for example `Stage: review → build`) its note
  is the reason the issue came back; treat it as part of the plan. When the
  issue went back to Plan from a later stage, the latest transition is
  `plan → build` again, and the reason is the note of that earlier
  `Stage: … → plan` comment, which the superseding plan answers.
- Note whether the issue has any `Stage: … → test` comment. Build's publish
  step makes one, so such a comment means Build has published before and
  this run is a re-entry, whatever the latest `→ build` transition says. A
  hand-made move to Test also counts; that errs towards re-entry, which only
  adds a read of the pull request's review comments.
- Refuse to start on a dirty working tree (`git status --porcelain` is not
  empty). Say what is uncommitted and stop.

## 2. Find or create the branch

Existing work for the issue is identified by an open pull request whose body
contains `Closes #<n>`:

```sh
gh pr list --state open --search "Closes #<n> in:body" --json number,headRefName,body
```

Confirm the match by checking the body for `Closes #<n>` followed by a
non-digit or the end of the line (the search also matches, for example,
`Closes #<n>0`, and so would a plain substring check).

- **A pull request exists and the issue has no `Stage: … → test`
  comment:** Plan opened it for a change folder, or an earlier Build run
  stopped before moving the stage. This is a first build on it, not a
  re-entry. Run `git fetch origin`, check out its head branch, and
  `git pull --ff-only`; if that fails, the local branch has diverged from the
  remote, so stop and say so rather than merging. Continue with step 3, from
  the tasks not yet `done`.
- **A pull request exists otherwise:** this is a re-entry. Run `git fetch origin`,
  check out its head branch, and `git pull --ff-only`; if that fails, the
  local branch has diverged from the remote, so stop and say so rather than
  merging. Read the pull request's review comments and threads with
  `gh pr view <pr> --comments` and `gh api repos/{owner}/{repo}/pulls/<pr>/comments`;
  together with the return note they say what to change. Never create a
  second branch or pull request for the issue.
- **No pull request:** first look for a branch that already carries
  commits for the issue, which means a previous run stopped before the pull
  request existed:

  ```sh
  git fetch origin
  git log --branches --remotes --not origin/main --grep="Refs #<n>\b" --format=%D
  ```

  If it names a branch, check it out (`git pull --ff-only` if it is on
  `origin`) and continue from its last commit. Otherwise derive the branch
  name `<type>/<short-description>` from the plan's first step if it names
  one, otherwise from the issue: `<type>` is `feature`, `fix`, `docs`, or
  `chore` by what the issue asks for; `<short-description>` is a few
  lowercase words from the title joined with hyphens. If that name already
  exists locally or on `origin`, check it out and continue instead of
  creating another. Otherwise:

  ```sh
  git fetch origin main
  git checkout -b <type>/<short-description> origin/main
  ```

  Branch from somewhere else only if the plan says so.

## 3. Implement

Follow the plan's Steps in order. When the plan links to a change folder,
its `tasks.md` holds the steps, in the format of `docs/changes/README.md`:
take the next task with status `todo` whose dependencies are all `done`,
lowest ID first; have its agent do it, as "Delegating a task of a change
folder" below describes; and set its status to `done` in the commit that
completes it. A task you cannot complete gets status `deferred` and an
entry in the deviation list. A task that depends on a `deferred` task is
deferred too, with its own deviation entry naming that dependency, so no task
is left `todo` when Build reaches the gate. A `spec` task applies its delta to the living
spec. The folder's `design.md` "Where it lands" section is the plan's
Documentation entry. On re-entry, tasks already `done` stay done unless the
return note or review asks for changes to them. A `deferred` task they ask
for goes back to `todo`, and so does every task deferred only because it
depends on that task; each is recorded as a reversed deferral in the
deviation list.

### Delegating a task of a change folder

Each task of a change folder is done by the agent the routing table gives,
as `docs/specs/task-routing/spec.md` (ROUTE-3) and `docs/architecture/agents.md`
describe. You stay the orchestrator: you choose the task, hand it over, check
the result and commit. One task at a time:

1. Check that the working tree is clean (`git status --porcelain` is
   empty). Each task ends in a commit, so it is; if it is not, stop and say
   what is uncommitted.
2. Run `scripts/route.sh <kind> <complexity>` with the task's Kind and
   Complexity. It prints `<agent> <model> <effort>`. A task without a Kind
   or Complexity, a `route.sh` error, or an agent file missing from
   `.claude/agents/` cannot be routed: defer it as in step 6, and continue
   with the next task.
3. Build the context packet: the task's section of `tasks.md`, its Owns list,
   the Decisions section of `design.md`, the spec or delta sections for the
   scenario IDs in its Covers field, and the Principles section of
   `docs/architecture/README.md`. Paste them into the prompt; do not tell the
   agent to read the whole folder.
4. Note `git rev-parse HEAD`, then call the Agent tool with
   `subagent_type` set to the agent, `model` set to the model, and `effort`
   set to the effort `route.sh` printed. This skill asks for that effort
   explicitly. Wait for the agent's report.
5. If HEAD moved, the agent committed despite its rules: run
   `git reset --soft <noted HEAD>` so its work is uncommitted again, and
   record a deviation; if it also pushed (`git rev-list --count
   origin/<branch>..<noted HEAD>` no longer matches what you pushed), stop
   and say so. Then list what changed with
   `git status --porcelain --untracked-files=all`.
   Every path must be in the task's Owns list. If one is not, revert the
   paths outside it yourself (`git restore --staged --worktree -- <path>`
   for a tracked file, delete an untracked one), then return the task to the
   agent once, with the Owns list and the paths you reverted. If the second
   attempt changes such a path again, revert it, or keep it when the task
   really needs it, and record either as a deviation; never commit it
   without one of the two.
6. Read the agent's report. If it says the task is not done, or the checks
   it ran failed, either fix it yourself, recorded as a deviation, and go on
   to step 7 with a `Fixed-by: build` line under the `Routed:` line, so the
   routing record does not count the task as the agent's success; or defer
   it: revert every change the agent made, set the task
   and every task that depends on it to `deferred` with a deviation entry
   each, and commit only that status change, so the next task starts from a
   clean tree.
7. Set the task's status in `tasks.md` and commit the agent's changes with
   it, as one commit. The message body has a line
   `Routed: <agent> <model> <effort>` with what `route.sh` printed, before
   `Refs #<n>`.

A change planned as a comment, without a change folder, is not routed: you
implement its Steps yourself, as before (ROUTE-4).

Add or update the tests or checks the
plan's Tests table names. Do not invent a test runner the repository lacks;
if the proof for a criterion is a manual check or a transcript, say so and
leave it for the Test stage.

The plan's **Documentation** entry is part of its Steps: update each
document it names, as the documentation rule in `docs/lifecycle.md`
describes. A named document left unchanged is a deferred step and goes in
the deviation list below with the reason. A document the change turns out to
alter that the plan did not name is updated too, and recorded as a deviation.
A new document gets the index and README map entries that "Where a new
document goes" in `docs/documentation-model.md` gives it.

A new ADR the plan names is written as `docs/adr/README.md` says: its
status, its number (the next one not used on `main`), and its entry in the
index there.

Commit in logical steps as you go: imperative mood, one logical change per
commit, ending with the attribution lines this session requires. Reference
the issue as `Refs #<n>` in the body, not `Closes`, so the pull request owns
the closing keyword.

Keep a running list of **deviations**: any step implemented differently from
the plan, with why, and any step **deferred**, with why. A step is never
dropped silently. Design choices the plan left open are not deviations; make
them and mention them in the pull request summary. On re-entry, implementing
a step that an earlier `## Build: deviation` comment deferred is itself a
deviation to record, so the issue says the deferral was reversed.

## 4. Gate

- **Interactive:** show the user, in this order, the commits this run will
  push (`git log --oneline origin/main..HEAD` on a first build without a
  pull request, `git log --oneline origin/<branch>..HEAD` on a first build on
  Plan's pull request,
  `git log --oneline origin/<branch>..HEAD` on re-entry or a resumed branch),
  `git diff --stat origin/main...HEAD` for the whole change, and the
  deviation list (or "none"). Ask whether to publish. Until they confirm nothing is
  pushed, posted, or relabelled. If they ask for changes, make them, commit,
  and show again.
- **Non-interactive, `risk:low`:** there is no gate; continue.

## 5. Publish

In this order, so that a failure part way never leaves a stage claim without
a pull request behind it:

1. `git push -u origin <branch>`.
2. Post the deviations and deferred steps of this run as one issue comment
   headed `## Build: deviation`, one entry per item with the plan step it
   concerns and the reason. Leave out anything an existing
   `## Build: deviation` comment already records, and post nothing when
   there is nothing new. Save the body to a file in your scratchpad and pass
   it with `--body-file`.
3. On a first build without a pull request, open the draft pull request:

   ```sh
   gh pr create --draft --base main --title "<issue title without the [Work item]: prefix>" --body-file <path>
   ```

   The body is `.github/PULL_REQUEST_TEMPLATE.md` with the Summary written
   and `Closes #` completed to `Closes #<n>`. Every other section stays
   exactly as the template has it; later stages fill them. Append the
   attribution lines this session requires for pull requests.

   On a first build on Plan's pull request, or on re-entry, push only. The
   existing pull request picks up the commits.
4. `scripts/stage.sh <n> test "Draft PR #<pr>."` On re-entry, say what the
   return note asked for, for example
   `"Review findings addressed on PR #<pr>."`.

If any command fails, for example because a `claude -p` run lacks permission
for `git push` or `gh pr create`, stop there and do not move the stage. Post
one issue comment headed `## Build: incomplete` saying exactly which of the
four steps completed, which failed, and the error, so the record is on the
issue and not only in a transcript; then report the same to the user. The
next run of this skill resumes from the existing branch and does not repeat
the completed steps.

## 6. Report

Tell the user: the branch, the pull request link, the deviation comments
posted, and the stage the issue is now at. The next stage is Test: run the
checks the plan names and record the output for the pull request body.

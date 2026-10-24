---
name: build
description: Run the Build stage of the Gimli lifecycle on a GitHub issue. Takes the confirmed plan on the issue, implements it on a branch with step-sized commits, records deviations, and after confirmation pushes the branch, opens the draft pull request, and moves the issue to Test. Runs unattended only for risk:low issues.
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
  is the reason the issue came back; treat it as part of the plan.
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

- **A pull request exists:** this is a re-entry. Run `git fetch origin`,
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

Follow the plan's Steps in order. Add or update the tests or checks the
plan's Tests table names. Do not invent a test runner the repository lacks;
if the proof for a criterion is a manual check or a transcript, say so and
leave it for the Test stage.

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
  push (`git log --oneline origin/main..HEAD` on a first build,
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
3. On a first build, open the draft pull request:

   ```sh
   gh pr create --draft --base main --title "<issue title without the [Work item]: prefix>" --body-file <path>
   ```

   The body is `.github/PULL_REQUEST_TEMPLATE.md` with the Summary written
   and `Closes #` completed to `Closes #<n>`. Every other section stays
   exactly as the template has it; later stages fill them. Append the
   attribution lines this session requires for pull requests.

   On re-entry, push only. The existing pull request picks up the commits.
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

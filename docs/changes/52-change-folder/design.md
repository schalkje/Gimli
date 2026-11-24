# Design: change folder and tasks format

Part of the [change folders](../README.md).

- **Issue:** #52, the proposal: goal, scope and acceptance criteria.
- **Plan:** the `## Plan` comment on #52, with the Tests table and the risk
  assessment.
- **Tasks:** [`tasks.md`](tasks.md).
- **Spec deltas:** [stage transitions](specs/stage-transitions/delta.md).

This is the first change folder. The skills that will write change folders
are part of this change, so Plan wrote this one by hand, following the format
it introduces.

## Approach

Large changes get a change folder in `docs/changes/<issue>-<slug>/`. It holds
three kinds of file, each owning one thing:

| File | Owns |
|---|---|
| `design.md` | How the change is built: the decisions and where they land. |
| `tasks.md` | The work, split into tasks with stream, dependencies, kind, complexity, owned files, covered scenarios and status. |
| `specs/<capability>/delta.md` | What changes in a capability spec: ADDED, MODIFIED, REMOVED requirements and scenarios, and the IDs this change retires. |

The issue body stays the proposal, and the `## Plan` comment keeps the Tests
table and the risk assessment, so nothing is written twice.

## Decisions

1. **When a change gets a folder.** Plan uses one when the change touches a
   capability spec, needs more than one stream, or has more than about five
   steps. Below that, the `## Plan` comment is the whole plan, as today.
2. **Plan writes the folder on the change branch.** Plan creates the branch,
   commits the folder, opens the draft pull request and then posts the
   `## Plan` comment linking to the folder. The design is reviewable before
   any code. Only an interactive run does this, after confirmation; a
   non-interactive run still posts `## Plan: draft` only.
3. **Build follows `tasks.md`.** Build takes the next `todo` task whose
   dependencies are `done`, implements it, and sets its status to `done` in
   the same commit. A deferred task gets status `deferred` and a deviation
   comment, and so does every task that depends on it. Running tasks in parallel is Track A step 5.
4. **First Build or re-entry.** With Plan opening the pull request, an open
   pull request no longer means re-entry. Build's publish step moves the
   issue to Test, so a `Stage: … → test` comment on the issue means Build
   has published before: that is a re-entry, even when the issue went back to
   Plan and the latest transition is `plan → build`. Without one, Build
   continues on the existing pull request as a first Build.
5. **Deltas and living specs.** Until Track A step 7 defines the archive,
   Build applies each delta to the living spec by hand, as a `spec` task in
   the same pull request, so the documentation rule holds. The delta stays in
   the folder as the record.
6. **Task kinds and complexity** are a fixed list (`design`, `spec`,
   `implement`, `test-unit`, `test-e2e`, `docs`, `review`) and three levels
   (`low`, `medium`, `high`), so Track A step 3 has fixed values to route on.
7. **Parent issues** hold a roadmap, carry no `stage:*` label, track children
   as GitHub sub-issues, and close when every child is closed or dropped. A
   new `scripts/stage.sh <issue> parent` target removes the stage label with
   a `Stage: <old> → parent` comment, so the label rule is kept through the
   script.
8. **One pull request per large change.** A large change gets a folder and
   one pull request. Splitting is for work that is really several changes,
   which become children of a parent issue.
9. **After merge** the folder stays in `docs/changes/` as the record, until
   step 7.

ADR 0003 records decisions 1, 2, 7 and 8, the ones later changes must
respect; the others are format details owned by `docs/changes/README.md`.

## Where it lands

- The format: `docs/changes/README.md` and templates in
  `docs/changes/_template/`.
- The process: `docs/lifecycle.md` (Plan, Build, parent issues), `CLAUDE.md`.
- The skills: `.claude/skills/plan/SKILL.md`, `.claude/skills/build/SKILL.md`.
- The script: `scripts/stage.sh`, `scripts/README.md`, and the stage
  transitions spec through the delta.
- The decision: `docs/adr/0003-change-folders.md`.

## Risks

- **Plan pushes.** Plan gains a branch, a push and a pull request; it asks
  for confirmation first, as Build does.
- **Size.** The change spans process documents, two skills and a script; the
  tasks keep each concern in its own commit.
- **#49** also changes `stage.sh`; whichever merges second rebases.

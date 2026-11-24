# Design: reading the stage of a closed issue

Part of the [change folders](../README.md).

- **Issue:** #54, the proposal: goal, scope and acceptance criteria.
- **Plan:** the `## Plan` comment on #54, with the Tests table and the
  risk assessment.
- **Tasks:** [`tasks.md`](tasks.md).
- **Spec deltas:** [stage-transitions](specs/stage-transitions/delta.md).

## Approach

Specify behaviour that already exists. [`scripts/stage.sh`](../../../scripts/stage.sh)
reads the issue's state and stage labels in one `gh issue view` call and,
with no target, prints the stage before it looks at the state. So a closed
issue that still carries `stage:merge` prints `merge`, as an open one would.

The change adds scenario STAGE-1.3 under the existing requirement STAGE-1 in
the [stage transitions spec](../../specs/stage-transitions/spec.md), through
[the delta](specs/stage-transitions/delta.md), and a sentence in the
`stage.sh` section of [`scripts/README.md`](../../../scripts/README.md#stagesh).
The script does not change.

## Decisions

1. **A scenario, not a requirement.** STAGE-1 already says the stage is
   printed for any issue; the closed case is one more scenario of it, so it
   takes the next unused ID, STAGE-1.3. No ADR: nothing is decided that
   `docs/adr/README.md` asks to record.
2. **Branch from `feature/change-folder`.** This issue is a test fixture for
   #52 and is closed without merging. Its branch is based on #52's branch,
   where `docs/changes/` and the updated skills exist, instead of
   `origin/main`.

## Where it lands

- `docs/specs/stage-transitions/spec.md`: scenario STAGE-1.3 under STAGE-1.
- `scripts/README.md`: the `stage.sh` section says that reading the stage
  works on closed issues.
- `docs/changes/README.md`: an index row for this folder.

## Risks

- The scenario could promise more than the script does. T1 checks each line
  of the scenario against the `stage.sh` lines that implement it.

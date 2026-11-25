# Delta: task routing

Part of the [change folder for #65](../../design.md). Changes the
[task routing spec](../../../../specs/task-routing/spec.md). The format is
in [`docs/changes/README.md`](../../../README.md#spec-deltas).

ROUTE-1 and ROUTE-1.4 keep their IDs: they still describe routing by kind
and complexity, with one kind more. Verified by lines are added to the
scenarios of ROUTE-3 and ROUTE-4; they record coverage, not behaviour, so
they are not part of this delta.

## ADDED

None.

## MODIFIED

### Requirement ROUTE-1: Route a task by kind and complexity

The table gains one row, after `spec`:

| Kind | low | medium | high |
|---|---|---|---|
| test-design | sonnet medium | sonnet high | opus high |

The rest of the requirement, including the other rows and the `docs`
levels, is unchanged.

#### Scenario ROUTE-1.4: Every cell

- **WHEN** `scripts/route.sh` runs for each kind and complexity pair in the
  table
- **THEN** each prints the agent and the model and effort in that cell

## REMOVED

None.

## Retired by this change

None.

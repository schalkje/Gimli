# Design: let route.sh print the routing table

Part of the [change folders](../README.md).

- **Issue:** #60, the proposal: goal, scope and acceptance criteria.
- **Plan:** the `## Plan` comment on #60, with the Tests table and the
  risk assessment.
- **Tasks:** [`tasks.md`](tasks.md).
- **Spec deltas:** [task-routing](specs/task-routing/delta.md).

## Approach

[`scripts/route.sh`](../../../scripts/route.sh) gains one option, `--table`,
that loops over the kinds and complexity levels in table order and prints
`<kind> <complexity> <agent> <model> <effort>` for each, from the same
`case` lookup the single-cell form uses, so the two cannot disagree. The
[task routing spec](../../specs/task-routing/spec.md) gets a requirement for
it, and the test checks it against the spec's table.

## Decisions

1. **A new requirement, ROUTE-5.** Printing the table is not routing one
   task, so it is a requirement of its own with scenario ROUTE-5.1, the next
   unused number.
2. **ROUTE-2.3 changes.** It says one argument exits with status 2; `--table`
   is one argument that does not. ROUTE-2.3 now excepts `--table` and keeps
   its ID, because it still describes rejecting a wrong number of arguments.
3. **Branch from `feature/task-routing`.** This issue is a test fixture for
   #58 and is closed without merging; `route.sh` exists only on #58's
   branch.

## Where it lands

- `docs/specs/task-routing/spec.md`: ROUTE-5 and the changed ROUTE-2.3.
- `scripts/README.md`: the `route.sh` section documents `--table`.
- `docs/changes/README.md`: an index row for this folder.

## Risks

- The table output and the single-cell output could drift. Both come from
  one lookup, and T3 checks the table output against the spec.

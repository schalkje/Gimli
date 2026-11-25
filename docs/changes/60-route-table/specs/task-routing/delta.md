# Delta: task routing

Part of the [change folder for #60](../../design.md). Changes the
[task routing spec](../../../../specs/task-routing/spec.md). The format is
in [`docs/changes/README.md`](../../../README.md#spec-deltas).

ROUTE-2.3 keeps its ID: it still describes rejecting a wrong number of
arguments, and `--table` joins the valid forms.

## ADDED

### Requirement ROUTE-5: Print the routing table

Given `--table` as its only argument, the system SHALL print every cell of
the table in ROUTE-1, one line per cell, as
`<kind> <complexity> <agent> <model> <effort>`, in the table's order of
kinds and of complexity levels, and exit with status 0.

#### Scenario ROUTE-5.1: Whole table

- **WHEN** `scripts/route.sh --table` runs
- **THEN** it prints 21 lines, starting with `design low gimli-design sonnet medium`
- **AND** each line agrees with `scripts/route.sh <kind> <complexity>` for
  that cell

## MODIFIED

### Requirement ROUTE-2: Reject invalid input

Unchanged; one of its scenarios changes.

#### Scenario ROUTE-2.3: Wrong number of arguments

- **WHEN** `scripts/route.sh` runs with no arguments, with one argument
  other than `--table`, or with more than two
- **THEN** it prints its usage and exits with status 2

## REMOVED

None.

## Retired by this change

None.

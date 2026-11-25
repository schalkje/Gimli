# Delta: traceability

Part of the [change folder for #65](../../design.md). Creates the
[traceability spec](../../../../specs/traceability/spec.md), a new capability
with prefix `TRACE`. The format is in
[`docs/changes/README.md`](../../../README.md#spec-deltas).

## ADDED

### Requirement TRACE-1: List every scenario

The system SHALL print one line per scenario heading in the capability specs,
`<ID> <status> <source>`, in the order of the spec files and of the
scenarios in them, leaving out the spec template.

#### Scenario TRACE-1.1: Every scenario

- **GIVEN** specs with three scenario headings between them
- **WHEN** `scripts/trace.sh` runs
- **THEN** it prints three lines, one per scenario, in that order

#### Scenario TRACE-1.2: Template left out

- **GIVEN** `docs/specs/_template/spec.md` with its example scenarios
- **WHEN** `scripts/trace.sh` runs
- **THEN** no line names a scenario of the template

### Requirement TRACE-2: Tested by a passing check

A scenario SHALL be `tested` when a test file in the tests folder exits with
status 0 and prints a line `ok <ID>: <description>` for it; the source is
the test file's name. A test file that prints `FAIL <ID>: ...` or exits
non-zero makes the scenarios it names `failing`.

#### Scenario TRACE-2.1: Passing check

- **GIVEN** a test file that exits 0 and prints `ok CAP-1.1: works`
- **WHEN** `scripts/trace.sh` runs
- **THEN** the line for CAP-1.1 is `CAP-1.1 tested <test file>`

#### Scenario TRACE-2.2: Failing check

- **GIVEN** a test file that prints `FAIL CAP-1.1: broken` and exits 1
- **WHEN** `scripts/trace.sh` runs
- **THEN** the line for CAP-1.1 has status `failing`
- **AND** it exits with status 1

#### Scenario TRACE-2.3: ID named but not checked

- **GIVEN** a test file that mentions CAP-1.1 only in a comment
- **WHEN** `scripts/trace.sh` runs
- **THEN** CAP-1.1 is not `tested`

### Requirement TRACE-3: Verified by

A scenario without a passing check SHALL take its status from a
`**Verified by:**` line under it in the spec: `not-yet` when the text starts
with `not yet`, otherwise `evidence`; the source is the rest of the line. A
passing check takes precedence over the line.

#### Scenario TRACE-3.1: Evidence

- **GIVEN** a scenario with `**Verified by:** [fixture run](https://example.org/1)`
  and no test
- **WHEN** `scripts/trace.sh` runs
- **THEN** its line has status `evidence` and the link as its source

#### Scenario TRACE-3.2: Not yet

- **GIVEN** a scenario with `**Verified by:** not yet: needs a gh stub, #1`
  and no test
- **WHEN** `scripts/trace.sh` runs
- **THEN** its line has status `not-yet` and the reason as its source

### Requirement TRACE-4: Exit status

The system SHALL exit with status 1 when any scenario is `uncovered` or
`failing`, or a test file exits non-zero, and with status 0 otherwise.

#### Scenario TRACE-4.1: Uncovered scenario

- **GIVEN** a scenario with no passing check and no Verified by line
- **WHEN** `scripts/trace.sh` runs
- **THEN** its line has status `uncovered` and source `-`
- **AND** it exits with status 1

#### Scenario TRACE-4.2: Every scenario covered

- **GIVEN** every scenario `tested`, `evidence` or `not-yet`
- **WHEN** `scripts/trace.sh` runs
- **THEN** it exits with status 0

### Requirement TRACE-5: Folders

The system SHALL read the specs and tests from `docs/specs` and
`scripts/tests` by default, or from the two folders given as arguments, and
exit with status 2 and its usage on any other number of arguments.

#### Scenario TRACE-5.1: Other folders

- **WHEN** `scripts/trace.sh <specs> <tests>` runs
- **THEN** it reads only those two folders

#### Scenario TRACE-5.2: Wrong number of arguments

- **WHEN** `scripts/trace.sh` runs with one argument, or more than two
- **THEN** it prints its usage and exits with status 2

## MODIFIED

None.

## REMOVED

None.

## Retired by this change

None.

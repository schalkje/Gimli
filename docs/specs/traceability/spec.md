# Traceability

Part of the [Gimli specs](../README.md).

- **Prefix:** `TRACE`
- **Implemented by:** [`scripts/trace.sh`](../../../scripts/trace.sh), tested
  by [`scripts/tests/trace_test.sh`](../../../scripts/tests/trace_test.sh).
- **Decisions:** [ADR 0005](../../adr/0005-traceability.md).

`scripts/trace.sh` lists every scenario of the [specs](../README.md) with
whether something shows that it holds: a passing check, a linked piece of
evidence, or an admitted gap. It fails when a scenario has none of these or
when a check fails. Maintainers and the Test stage use it to see what the
specs claim that nothing yet backs up.

## Requirements

### Requirement TRACE-1: List every scenario

The system SHALL print one line per scenario heading in the capability specs,
`<ID> <status> <source>`, in the byte order of the spec files' paths,
whatever the locale, and in the order of the scenarios in them, leaving out
the spec template and fenced code blocks. As in Markdown, fences and
headings may be indented up to three spaces, a fence closes only on a line
of the same character at least as long, and a backtick run followed by
another backtick on its line is inline code, not a fence. A code block
still open at the end of its file SHALL be named on standard error with the
line it opened on and make the run exit with status 1. A heading of any
level whose text starts with the word `Scenario`, in any case, but that
does not start exactly `#### Scenario <ID>:` SHALL get no line, be named on
standard error with its file and line number, and make the run exit with
status 1. So SHALL a scenario ID that heads more than one scenario, named
with both places; each heading still gets its line, with its own Verified
by line.

#### Scenario TRACE-1.1: Every scenario

- **GIVEN** specs with three scenario headings between them
- **WHEN** `scripts/trace.sh` runs
- **THEN** it prints three lines, one per scenario, in that order

#### Scenario TRACE-1.2: Template left out

- **GIVEN** `docs/specs/_template/spec.md` with its example scenarios
- **WHEN** `scripts/trace.sh` runs
- **THEN** no line names a scenario of the template

#### Scenario TRACE-1.3: Malformed scenario heading

- **GIVEN** a spec with the line `#### Scenario CAP-1.2 Name`, without the
  colon
- **WHEN** `scripts/trace.sh` runs
- **THEN** no line names CAP-1.2
- **AND** standard error names the spec file and the line number
- **AND** it exits with status 1

#### Scenario TRACE-1.4: Code blocks left out

- **GIVEN** a spec that shows `#### Scenario EX-1.1: Example` inside a
  fenced code block
- **WHEN** `scripts/trace.sh` runs
- **THEN** no line names EX-1.1

#### Scenario TRACE-1.5: Duplicate scenario ID

- **GIVEN** two scenario headings with the ID CAP-1.1
- **WHEN** `scripts/trace.sh` runs
- **THEN** standard error names the second heading's file and line and the
  first one's
- **AND** it exits with status 1

#### Scenario TRACE-1.6: Code block not closed

- **GIVEN** a spec with a line ```` ```sh ```` that no fence closes
- **WHEN** `scripts/trace.sh` runs
- **THEN** standard error names the file and the line the block opened on
- **AND** it exits with status 1

#### Scenario TRACE-1.7: Heading in another case

- **GIVEN** a spec with the line `#### scenario CAP-1.2: Name`, or
  `#### SCENARIO CAP-1.2: Name`
- **WHEN** `scripts/trace.sh` runs
- **THEN** no line names CAP-1.2
- **AND** standard error names the spec file and the line number
- **AND** it exits with status 1

#### Scenario TRACE-1.8: Byte order in any locale

- **GIVEN** spec folders `B` and `a`, and a locale whose collation puts `a`
  first
- **WHEN** `scripts/trace.sh` runs in that locale
- **THEN** the lines of the spec in `B` come before those of the spec in `a`

### Requirement TRACE-2: Tested by a passing check

A scenario SHALL be `tested` when a test file in the tests folder exits with
status 0 and prints a line `ok <ID>: <description>` for it; the source is
the test file's name; one or more spaces may follow `ok`. A test file that
prints `FAIL <ID>: ...`, again with one or more spaces, or exits non-zero
makes the scenarios it names `failing`.

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

A scenario without a passing check SHALL take its status from the first
`**Verified by:**` paragraph under it in the spec whose text is not empty.
The text is the rest of the `**Verified by:**` line and the lines after it
up to a blank line, a heading or a fence, each trimmed and joined with one
space. It is `not-yet` when the text starts with `not yet`, in any case,
followed by a space, `:` or the end of the text, with the reason after it
as the source; `evidence` when the text holds a Markdown link
`[text](target)`, with the text as the source. Any other text counts as no
paragraph. A passing check takes precedence over the paragraph.

#### Scenario TRACE-3.1: Evidence

- **GIVEN** a scenario with `**Verified by:** [fixture run](https://example.org/1)`
  and no test
- **WHEN** `scripts/trace.sh` runs
- **THEN** its line has status `evidence` and the text of the Verified by
  paragraph as its source

#### Scenario TRACE-3.2: Not yet

- **GIVEN** a scenario with `**Verified by:** not yet: needs a gh stub, #1`
  and no test
- **WHEN** `scripts/trace.sh` runs
- **THEN** its line has status `not-yet` and the reason as its source

#### Scenario TRACE-3.3: Neither evidence nor not yet

- **GIVEN** a scenario with `**Verified by:** TODO` and no test
- **WHEN** `scripts/trace.sh` runs
- **THEN** its line has status `uncovered`
- **AND** it exits with status 1

#### Scenario TRACE-3.4: Wrapped Verified by paragraph

- **GIVEN** a scenario whose Verified by paragraph wraps onto a second line,
  with no test
- **WHEN** `scripts/trace.sh` runs
- **THEN** its source holds the text of both lines, joined with one space
- **AND** a link split over the two lines gives status `evidence`

### Requirement TRACE-4: Exit status

The system SHALL exit with status 1 when any scenario is `uncovered` or
`failing`, a test file exits non-zero or prints any line starting `FAIL`,
or a scenario heading is malformed or reuses an ID (TRACE-1), and with
status 0 otherwise. It SHALL name on standard error each test file that
exits non-zero, with its status, followed by the last five lines of that
file's standard error, and each that exits 0 but prints a `FAIL` line;
standard output holds only the scenario lines.

#### Scenario TRACE-4.1: Uncovered scenario

- **GIVEN** a scenario with no passing check and no Verified by line
- **WHEN** `scripts/trace.sh` runs
- **THEN** its line has status `uncovered` and source `-`
- **AND** it exits with status 1

#### Scenario TRACE-4.2: Every scenario covered

- **GIVEN** every scenario `tested`, `evidence` or `not-yet`
- **WHEN** `scripts/trace.sh` runs
- **THEN** it exits with status 0

#### Scenario TRACE-4.3: Failing test file named

- **GIVEN** a test file that names no scenario and exits 3
- **WHEN** `scripts/trace.sh` runs
- **THEN** standard error holds `trace.sh: <test file> exited 3`
- **AND** it exits with status 1

### Requirement TRACE-5: Folders

The system SHALL read the specs and tests from `docs/specs` and
`scripts/tests` by default, or from the two folders given as arguments, and
exit with status 2 and its usage on any other number of arguments. It SHALL
exit with status 2, naming the folder on standard error and running no
test, when either folder is not a directory. It runs the tests with
`TRACE_RUNNING` set, holding the tests folders of the runs above it, and
SHALL refuse with status 2, running no test, a run without arguments while
it is set, and a run whose tests folder is one of them, so a test cannot
start the run that started it.

#### Scenario TRACE-5.1: Other folders

- **WHEN** `scripts/trace.sh <specs> <tests>` runs
- **THEN** it reads only those two folders

#### Scenario TRACE-5.2: Wrong number of arguments

- **WHEN** `scripts/trace.sh` runs with one argument, or more than two
- **THEN** it prints its usage and exits with status 2

#### Scenario TRACE-5.3: Missing folder

- **WHEN** `scripts/trace.sh <specs> <tests>` runs and one of them does not
  exist
- **THEN** standard error names it
- **AND** it exits with status 2 without running a test

#### Scenario TRACE-5.4: No run from inside a test

- **GIVEN** `TRACE_RUNNING` is set, as it is for a test `trace.sh` runs
- **WHEN** `scripts/trace.sh` runs without arguments
- **THEN** it exits with status 2 without running a test

#### Scenario TRACE-5.5: No rerun of a tests folder from inside a test

- **GIVEN** a test that `trace.sh` runs from tests folder `T`
- **WHEN** that test runs `scripts/trace.sh <specs> T`
- **THEN** that run exits with status 2 without running a test
- **AND** a run on another tests folder from the same test runs its tests

## Retired scenario IDs

None.

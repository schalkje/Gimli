# Delta: traceability

Part of the [change folder for #68](../../design.md). Changes the
[traceability spec](../../../../specs/traceability/spec.md). The format is
in [`docs/changes/README.md`](../../../README.md#spec-deltas).

TRACE-1, TRACE-3 and TRACE-5 keep their IDs: they describe the same
capability, with the gaps closed. TRACE-3.1 keeps its ID: a one-line
paragraph reads as before. The new behaviour gets new scenario IDs.

## ADDED

### Requirement TRACE-1: List every scenario

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

### Requirement TRACE-3: Verified by

#### Scenario TRACE-3.4: Wrapped Verified by paragraph

- **GIVEN** a scenario whose Verified by paragraph wraps onto a second line,
  with no test
- **WHEN** `scripts/trace.sh` runs
- **THEN** its source holds the text of both lines, joined with one space
- **AND** a link split over the two lines gives status `evidence`

### Requirement TRACE-5: Folders

#### Scenario TRACE-5.5: No rerun of a tests folder from inside a test

- **GIVEN** a test that `trace.sh` runs from tests folder `T`
- **WHEN** that test runs `scripts/trace.sh <specs> T`
- **THEN** that run exits with status 2 without running a test
- **AND** a run on another tests folder from the same test runs its tests

## MODIFIED

### Requirement TRACE-1: List every scenario

The system SHALL print one line per scenario heading in the capability specs,
`<ID> <status> <source>`, in the byte order of the spec files' paths, whatever
the locale, and in the order of the scenarios in them, leaving out the spec
template and fenced code blocks. As in Markdown, fences and headings may be
indented up to three spaces, a fence closes only on a line of the same
character at least as long, and a backtick run followed by another backtick
on its line is inline code, not a fence. A code block still open at the end
of its file SHALL be named on standard error with the line it opened on and
make the run exit with status 1. A heading of any level whose text starts
with the word `Scenario`, in any case, but that does not start exactly
`#### Scenario <ID>:` SHALL get no line, be named on standard error with its
file and line number, and make the run exit with status 1. So SHALL a
scenario ID that heads more than one scenario, named with both places; each
heading still gets its line, with its own Verified by line.

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

## REMOVED

None.

## Retired by this change

None.

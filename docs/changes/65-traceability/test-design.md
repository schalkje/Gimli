# Test design: spec-driven test design and a traceability check

Part of the [change folder for #65](design.md).

The cases `scripts/tests/trace_test.sh` (T5) must cover for
`scripts/trace.sh` (T4), one section per scenario of the
[traceability spec](../../specs/traceability/spec.md). T3 is a `design` task
because the `test-design` kind does not exist yet (design decision 9); this
file follows [the template](../_template/test-design.md). Every TRACE case
is implemented by T5, with the cases marked "extended in Review" added by
the review rounds on PR #67; the ROUTE-1.4 section, which the task routing
delta modifies, is checked by `route_test.sh` from T7.

## Shared fixtures and conventions

T4 and T5 both follow these. Where the spec is silent, this is the decision.

**Fixtures**

- `trace_test.sh` builds every case in its own pair of folders
  `$TMP/<case>/specs` and `$TMP/<case>/tests`, inside one `mktemp -d`
  directory that a `trap` removes. It runs `sh scripts/trace.sh <specs>
  <tests>` with those folders as absolute paths (design decision 5) and
  never runs `trace.sh` on `scripts/tests`, so it never runs itself.
- Notation below: `spec a: CAP-1.1, CAP-1.2` is `specs/a/spec.md` with a
  title, one `### Requirement CAP-1: R` heading per requirement number and a
  `#### Scenario CAP-1.1: S` heading per ID, in the order listed, each
  followed by a short GIVEN/WHEN/THEN list. `VB <text>` after an ID adds the
  paragraph `**Verified by:** <text>` after that scenario's list.
  `test a_test.sh: ok CAP-1.1; exit 0` is `tests/a_test.sh`, a
  `sh` script that prints `ok CAP-1.1: works` and exits 0; `FAIL CAP-1.1`
  prints `FAIL CAP-1.1: broken`. Anything not listed is not in the fixture.
- Fixture prefixes are `CAP` and `OTH`. Folder names of specs and file names
  of tests sort the way they are written, and the order of lines follows
  that sorted order of spec folders.

**What trace.sh does**

- It reads only `<specs>/*/spec.md` (not `<specs>/*.md`, not deeper), except
  the folder `_template`, and runs only `<tests>/*_test.sh` (not recursive,
  not `*.sh` in general) with `sh`. An empty tests folder, so an unmatched
  glob, runs nothing and is not an error.
- A scenario is a line starting `#### Scenario <ID>:`. The ID is
  `[A-Z]+-[0-9]+.[0-9]+`. Requirement headings, other prose that names an ID,
  and the Retired section produce no line. Any other heading, of any
  level and with spaces or a tab after the `#`s, whose text starts with the
  word `Scenario` (not `Scenarios`), such as one without the colon, with a
  digit in the prefix, two spaces, the wrong level or the colon first, is
  malformed: no line, a message
  `trace.sh: <file>:<line>: not a scenario heading: <line>` on standard
  error, and status 1. Lines inside a fenced code block are skipped: it
  opens on a line starting ```` ``` ```` or `~~~` and closes only on a line
  of the same character, at least as many, and nothing after them but
  spaces. Fences and headings may be indented up to three spaces; a
  backtick run with another backtick after it on the line is inline code,
  not a fence. A block still open at the end of a file adds
  `trace.sh: <file>:<line>: code block not closed` on standard error and
  gives status 1. Each heading has its own Verified by line, also when its
  ID is a duplicate. An ID heading a second scenario, in the same or a later file,
  prints its line as usual, adds `trace.sh: <file>:<line>: duplicate
  scenario ID <ID>, first at <file>:<line>` on standard error, and gives
  status 1.
- A heading is a line of one or more `#` followed by a space or the end; a
  line such as `#66 tracks this` is prose.
- A `**Verified by:**` line belongs to the nearest scenario heading above it,
  up to the next heading of any level. One above the first scenario heading,
  or under a requirement heading, belongs to no scenario. The line starts in
  column 1; the text after the label is trimmed of spaces at both ends. A
  line whose text is empty after trimming counts as no line, so a later
  line under the same scenario is read; after a non-empty one, later lines
  are ignored.
- A test file names an ID by a line of its standard output that starts in
  column 1 with `ok` and one or more spaces (`route_test.sh` prints `ok   `),
  or `FAIL` and one or more spaces, then the ID exactly, then `:`. `CAP-1.1:` does not
  name `CAP-1.10`. Comments, source text, prose and standard error name
  nothing. An ID that no spec has is ignored: no line, no error.
- Status of a scenario, first match wins:
  1. `failing`: a file prints `FAIL <ID>:` whatever its exit status, or
     prints `ok <ID>:` and exits non-zero. Failing beats a passing file and a
     Verified by line.
  2. `tested`: a file prints `ok <ID>:` and exits 0. Beats a Verified by line.
  3. `not-yet` if the Verified by text starts with `not yet`, in any case,
     followed by a space, `:` or the end of the text; else `evidence` if
     the text holds a Markdown link `[text](target)` anywhere; any other
     text counts as no line.
  4. `uncovered`.
- Source: `tested` and `failing` give the base name of the test file (for
  several files, the first in sorted order among those that fit the status);
  `evidence` the Verified by text, for example `[fixture run](https://example.org/1)`;
  `not-yet` the reason, which is the text after `not yet` and an optional
  `:`, trimmed; `-` when that is empty, and for `uncovered`.
- Exit status 1 when any line is `uncovered` or `failing`, any test file
  exits non-zero even if it names nothing, any test file prints a line
  starting `FAIL` whatever follows, or a scenario heading is malformed or
  reuses an ID; else 0. A file that exits 0 but prints a `FAIL` line is
  named as `trace.sh: <file> printed a FAIL line but exited 0`. All scenario lines are printed first in every case,
  standard output holds only those lines. Each test file that exits
  non-zero is named on standard error as `trace.sh: <file> exited <status>`,
  followed by the last five lines of its standard error, indented two
  spaces.
- A specs or tests folder that is not a directory exits 2 with
  `trace.sh: not a folder: <path>` on standard error, before any test runs.
- CRLF: a spec file or test output with CRLF line endings gives the same
  output as with LF, and no `\r` in any output line. The repository is
  checked out with `autocrlf` on Windows.
- Usage goes to standard error with status 2, no scenario lines on standard
  output, and no test file is run.
- With no arguments the defaults `docs/specs` and `scripts/tests` are read
  relative to the repository (the script's own location), not the current
  directory. The unit test runs them only on a copy of `trace.sh` in a
  fixture repository (TRACE-5.4 c), so it never runs itself; T10 runs
  `sh scripts/trace.sh` on the real specs.

**How the test checks**

- `check_run <label> <expected status> <expected stdout> <args...>` runs
  `trace.sh`, compares the whole standard output with the expected lines
  exactly (so a missing, extra or reordered line fails), compares the status,
  and prints `ok <label>` or `FAIL <label>` in `route_test.sh`'s style. A
  line is expected as `CAP-1.1 tested a_test.sh`, one space between fields.
  The label is `<scenario ID>: <case letter>, <short name>`.
- The cases of TRACE-1.1 and TRACE-1.2 compare the ID column only
  (`cut -d' ' -f1`), so the order and the set of IDs are tested apart from
  status; every other case compares whole lines.
- The test prints a summary line and exits 1 if any check failed. Its `ok`
  and `FAIL` lines start with the TRACE ID of the scenario, so `trace.sh`
  reads them for TRACE-1 to TRACE-5; only the trial break names none.

**Trial break.** Case TB: build the TRACE-2.1 fixture with `a_test.sh`
changed to `FAIL CAP-1.1; exit 1`, and run `check_run` in a subshell with its
output discarded, expecting `CAP-1.1 tested a_test.sh` and status 0. The
helper must report a mismatch, so the subshell exits non-zero. The test
prints `ok trial-break: check_run fails on a wrong line`, which names no
scenario, and `FAIL trial-break: ...` if the helper passed.

## Cases

### ROUTE-1.4: Every cell

Implemented by: T7. `route_test.sh` already reads the routing table from the
task routing spec and checks `route.sh` against every cell, so the new
`test-design` row needs no new case: T7 adds the row to the spec and to
`route.sh`, and the test fails until they agree.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | the routing table with the `test-design` row | `route.sh test-design low`, `medium` and `high` print `gimli-test-design sonnet medium`, `gimli-test-design sonnet high` and `gimli-test-design opus high` |

### TRACE-1.1: Every scenario

Implemented by: T5.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | `spec a: CAP-1.1, CAP-1.2`; `spec b: OTH-1.1`; empty tests folder | IDs `CAP-1.1`, `CAP-1.2`, `OTH-1.1`, three lines in that order |
| b | edge | `spec b: OTH-1.1` and `spec a: CAP-1.2, CAP-1.1`, created in that order | `CAP-1.2`, `CAP-1.1`, `OTH-1.1`: spec folders by name, scenarios in file order, not sorted by ID |
| c | edge | `spec a: CAP-1.1`; `spec b` with a title, a requirement heading and a `## Retired scenario IDs` section, no scenario | `CAP-1.1` only; no line for a requirement or a spec without scenarios |
| d | edge | `spec a: CAP-1.1` with the line `- see Scenario CAP-9.9 for more` in its list; `specs/README.md` containing `#### Scenario CAP-8.8: Not a spec` | `CAP-1.1` only: prose and loose files are not scenarios |
| e | edge | the fixture of a, every file written with CRLF line endings | the same three IDs, no `\r` in any line |

### TRACE-1.2: Template left out

Implemented by: T5.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | `spec _template: CAP-1.1, CAP-1.2, CAP-2.1`; `spec real: OTH-1.1 VB not yet: r` | exactly `OTH-1.1 not-yet r`, status 0 |
| b | edge | as a, plus `a_test.sh: ok CAP-1.1; exit 0` | still only the `OTH-1.1` line: a test naming a template ID adds nothing |
| c | edge | only `spec _template: CAP-1.1`; empty tests folder | no output, status 0 |

### TRACE-1.3: Malformed scenario heading

Implemented by: T5, extended in Review.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | failure | `spec a: CAP-1.1 VB not yet: r`, then the line `#### Scenario CAP-1.2 S` (line 13) | `CAP-1.1 not-yet r`, status 1, standard error `a/spec.md:13: not a scenario heading: #### Scenario CAP-1.2 S` |
| b | failure | as a with `#### Scenario C4P-1.2: S` | the same line, status 1, the heading named on standard error |
| c | edge | as a with `#### Scenarios` | `CAP-1.1 not-yet r`, status 0: not a scenario heading at all |
| d | failure | as a with `####  Scenario CAP-1.2: two spaces`, `### Scenario CAP-1.3: level`, `#### Scenario: CAP-1.4 colon first` and `####`, a tab, `Scenario CAP-1.5: tab` (lines 13 to 16) | `CAP-1.1 not-yet r`, status 1, each of lines 13 to 16 named as not a scenario heading |

### TRACE-1.4: Code blocks left out

Implemented by: T5, extended in Review.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | `spec a: CAP-1.1 VB not yet: r`, then a ```` ``` ```` block holding `#### Scenario EX-1.1: S` and `#### Scenario bad`, then a Verified by link after it | `CAP-1.1 not-yet r`, status 0: no EX-1.1 line, no malformed heading, and the later link does not replace the first line |
| b | edge | as a with a `~~~` block holding `#### Scenario EX-1.1: S` | `CAP-1.1 not-yet r`, status 0 |
| c | edge | as a, then a `~~~md` block holding a ```` ```sh ```` line, then `#### Scenario CAP-1.2: After VB not yet: s` | both lines, status 0: the other fence character does not close the block |
| d | edge | as a, then a ```` ```` ```` block holding ```` ``` ````, `#### Scenario EX-1.1: S` and ```` ``` ```` | `CAP-1.1 not-yet r`, status 0: a shorter fence does not close it |

### TRACE-1.5: Duplicate scenario ID

Implemented by: T5, extended in Review.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | failure | `spec a: CAP-1.1 VB not yet: r`, then `#### Scenario CAP-1.1: Copy` (line 13) | `CAP-1.1 not-yet r`, then `CAP-1.1 uncovered -`, status 1, standard error `a/spec.md:13: duplicate scenario ID CAP-1.1, first at ...` |
| b | failure | `spec a: CAP-1.1 VB not yet: r`; `spec b: CAP-1.1 VB not yet: s` | IDs `CAP-1.1` twice, status 1, standard error names `b/spec.md:5` |
| c | failure | `spec a: CAP-1.1`; `spec b: CAP-1.1 VB not yet: s` | `CAP-1.1 uncovered -`, `CAP-1.1 not-yet s`, status 1: each heading keeps its own Verified by line |

### TRACE-1.6: Code block not closed

Implemented by: T5, extended in Review.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | failure | `spec a: CAP-1.1 VB not yet: r`, then ```` ```sh ```` (line 13) and `#### Scenario CAP-1.2: Hidden`, never closed | `CAP-1.1 not-yet r`, status 1, standard error `a/spec.md:13: code block not closed` |
| b | edge | as a, but the block holds `echo` and closes with ```` ``` ```` indented two spaces, then `#### Scenario CAP-1.2: After VB not yet: s` | both lines, status 0 |
| c | edge | as a with the line ```` ```foo``` text ```` instead of a block, then CAP-1.2 as in b | both lines, status 0: inline code is not a fence |
| d | edge | `#### Scenario CAP-1.2: Three VB not yet: s` indented three spaces, and `#### Scenario CAP-1.3: Four` indented four | `CAP-1.1 not-yet r`, `CAP-1.2 not-yet s`, status 0: four spaces is not a heading |

### TRACE-2.1: Passing check

Implemented by: T5.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | `spec a: CAP-1.1`; `test a_test.sh: ok CAP-1.1; exit 0` | `CAP-1.1 tested a_test.sh`, status 0 |
| b | normal | `spec a: CAP-1.1, CAP-1.2`; `a_test.sh: ok CAP-1.1; exit 0`; `b_test.sh: ok CAP-1.2; exit 0` | each line names its own file; a summary line such as `2 passed, 0 failed` in a test's output changes nothing |
| c | edge | `a_test.sh` and `b_test.sh` both `ok CAP-1.1; exit 0` | `CAP-1.1 tested a_test.sh` (first in sorted order) |
| d | edge | `a_test.sh` prints `ok CAP-1.1: works` with CRLF endings, exit 0 | `CAP-1.1 tested a_test.sh` |
| e | edge | `a_test.sh` prints `ok   CAP-1.1: works` (three spaces, as `route_test.sh` does), exit 0 | `CAP-1.1 tested a_test.sh` |
| f | edge | `spec a: CAP-1.1, CAP-1.10`; `a_test.sh: ok CAP-1.10; exit 0` | `CAP-1.1 uncovered -`, `CAP-1.10 tested a_test.sh`: IDs match exactly |
| g | edge | `spec a: CAP-1.1`; `a_test.sh: ok CAP-1.1; ok NOPE-9.9; exit 0` | `CAP-1.1 tested a_test.sh` only; the unknown ID adds no line and no error |
| h | failure | `a_test.sh` prints `ok CAP-1.1 works` (no colon), or ` ok CAP-1.1: works` (indented); exit 0 | `CAP-1.1 uncovered -`: not a check line |

### TRACE-2.2: Failing check

Implemented by: T5.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | `a_test.sh: FAIL CAP-1.1; exit 1` | `CAP-1.1 failing a_test.sh`, status 1 |
| b | edge | `a_test.sh: ok CAP-1.1; exit 1` | `CAP-1.1 failing a_test.sh`, status 1: a file that exits non-zero fails the scenarios it names, whatever it printed |
| c | edge | `a_test.sh: FAIL CAP-1.1; exit 0` | `CAP-1.1 failing a_test.sh`, status 1 |
| d | edge | `a_test.sh: ok CAP-1.1; exit 0`; `b_test.sh: FAIL CAP-1.1; exit 1` | `CAP-1.1 failing b_test.sh`, status 1: failing wins over passing |
| e | edge | as d with the files swapped (`a_test.sh` fails, `b_test.sh` passes) | `CAP-1.1 failing a_test.sh`: source is the failing file, not the first file |
| f | edge | `spec a: CAP-1.1, CAP-1.2`; `a_test.sh: ok CAP-1.1; FAIL CAP-1.2; exit 1` | both lines `failing a_test.sh`, status 1 |
| g | edge | `spec a: CAP-1.1 VB [run](https://example.org/1)`; `a_test.sh: FAIL CAP-1.1; exit 1` | `CAP-1.1 failing a_test.sh`: failing wins over a Verified by line |
| h | failure | `a_test.sh` prints `FAIL CAP-1.1: broken` with CRLF endings, exit 1 | `CAP-1.1 failing a_test.sh`, status 1 |
| i | failure | `a_test.sh` prints `FAIL  CAP-1.1: broken` (two spaces), exit 0; `b_test.sh: ok CAP-1.1; exit 0` | `CAP-1.1 failing a_test.sh`, status 1 |

### TRACE-2.3: ID named but not checked

Implemented by: T5.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | `a_test.sh` with the comment `# CAP-1.1 is checked below` and no output, exit 0 | `CAP-1.1 uncovered -`, status 1 |
| b | edge | `a_test.sh` with the comment `# ok CAP-1.1: works`, exit 0 | `CAP-1.1 uncovered -` |
| c | edge | `a_test.sh` with `if false; then echo "ok CAP-1.1: works"; fi`, exit 0 | `CAP-1.1 uncovered -`: the file is run, not grepped |
| d | edge | `a_test.sh` prints `checking CAP-1.1` and `skipped: ok CAP-1.1: works`, exit 0 | `CAP-1.1 uncovered -`: the ID in a line that does not start with `ok` |
| e | edge | `a_test.sh` mentions `CAP-1.1` in a comment; `b_test.sh: ok CAP-1.1; exit 0` | `CAP-1.1 tested b_test.sh`: a mention does not hide a real check |

### TRACE-3.1: Evidence

Implemented by: T5.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | `spec a: CAP-1.1 VB [fixture run](https://example.org/1)`; empty tests | `CAP-1.1 evidence [fixture run](https://example.org/1)`, status 0 |
| b | edge | as a, plus `a_test.sh: ok CAP-1.1; exit 0` | `CAP-1.1 tested a_test.sh`: a passing check beats the line |
| c | edge | as a with the spec in CRLF | the same line, no `\r` at its end |
| d | edge | `spec a: CAP-1.1, CAP-1.2 VB [run](https://example.org/2)`, the line after CAP-1.2's list only | `CAP-1.1 uncovered -`, `CAP-1.2 evidence [run](https://example.org/2)`: the line belongs to the heading above it |
| e | edge | `spec a: CAP-1.1` with a `**Verified by:** [run](https://example.org/3)` paragraph under the requirement heading, above the scenario heading | `CAP-1.1 uncovered -` |
| f | edge | `spec a: CAP-1.1 VB   [run](https://example.org/1)   ` (extra spaces both sides) | source `[run](https://example.org/1)`, trimmed |
| g | edge | `spec a: CAP-1.1`; `spec b: OTH-1.1 VB [run](https://example.org/4)` | `CAP-1.1 uncovered -`: a line in the next file does not reach back |
| h | failure | `spec a: CAP-1.1` with the paragraph `Verified by: [run](https://example.org/1)` (no bold), or ` **Verified by:** ...` (indented) | `CAP-1.1 uncovered -` |
| i | edge | `#### Scenario CAP-1.1: S`, the prose line `#66 tracks this`, then `**Verified by:** [run](https://example.org/1)` | `CAP-1.1 evidence [run](https://example.org/1)`: a `#` line that is not a heading keeps the scope |
| j | edge | `spec a: CAP-1.1 VB` with empty text, then `**Verified by:** [run](https://example.org/1)` | `CAP-1.1 evidence [run](https://example.org/1)`: an empty line does not hide the next one |

### TRACE-3.2: Not yet

Implemented by: T5.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | `spec a: CAP-1.1 VB not yet: needs a gh stub, #1`; empty tests | `CAP-1.1 not-yet needs a gh stub, #1`, status 0 |
| b | edge | `VB not yet` with no reason | `CAP-1.1 not-yet -`, status 0 |
| c | edge | `VB not yet: r` and `a_test.sh: ok CAP-1.1; exit 0` | `CAP-1.1 tested a_test.sh` |
| d | edge | `VB [run](https://example.org/1), not yet reviewed` | `evidence` with the whole text: `not yet` counts only at the start |
| e | edge | as a with the spec in CRLF | the same line, no `\r` |
| f | edge | `CAP-1.1 VB Not yet: later`, `CAP-1.2 VB NOT YET` | `CAP-1.1 not-yet later`, `CAP-1.2 not-yet -`, status 0 |

### TRACE-3.3: Neither evidence nor not yet

Implemented by: T5, extended in Review.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | failure | `CAP-1.1 VB TODO`, `CAP-1.2 VB see the pull request`, `CAP-1.3 VB [run]`, `CAP-1.4 VB notyet` | all four `uncovered -`, status 1 |
| b | edge | `CAP-1.1 VB see [run](https://example.org/1)` | `CAP-1.1 evidence see [run](https://example.org/1)`, status 0: the link may be anywhere |

### TRACE-4.1: Uncovered scenario

Implemented by: T5.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | `spec a: CAP-1.1`; `a_test.sh: ok OTH-1.1; exit 0` | `CAP-1.1 uncovered -`, status 1 |
| b | edge | `spec a: CAP-1.1 VB [run](https://example.org/1), CAP-1.2`; the tests folder exists and is empty | `CAP-1.1 evidence [run](https://example.org/1)`, `CAP-1.2 uncovered -`, status 1, nothing on standard error: an empty tests folder is not an error, and no scenario is hidden because the other is covered |
| c | edge | `spec a: CAP-1.1, CAP-1.2`; the tests folder holds `helper.sh` and `x_test.txt` printing `ok CAP-1.1`, and none is `*_test.sh` | both `uncovered -`, status 1: only `*_test.sh` files count |
| d | failure | `spec a: CAP-1.1 VB` with empty text, `CAP-1.2 VB` with only spaces | both `uncovered -`, status 1: an empty Verified by line covers nothing |

### TRACE-4.2: Every scenario covered

Implemented by: T5.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | `spec a: CAP-1.1, CAP-1.2 VB [run](https://example.org/1), CAP-1.3 VB not yet: r`; `a_test.sh: ok CAP-1.1; exit 0` | `tested a_test.sh`, `evidence [run](https://example.org/1)`, `not-yet r`, status 0 |
| b | edge | `spec a: CAP-1.1 VB not yet: r`; no tests | status 0: only `not-yet` still exits 0 |
| c | edge | `specs` and `tests` both empty folders | no output, status 0 |
| d | failure | as a, plus `b_test.sh` with `exit 1` that prints nothing | the same three lines, status 1: a test file that exits non-zero fails the run even when it names no scenario |
| e | failure | as a, plus `b_test.sh: ok NOPE-9.9; exit 1` | the same three lines, status 1 |

### TRACE-4.3: Failing test file named

Implemented by: T5, extended in Review.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | failure | `spec a: CAP-1.1 VB not yet: r`; `a_test.sh` that writes `setup broke` on standard error and exits 3; `b_test.sh: ok OTH-1.1; exit 0` | `CAP-1.1 not-yet r`, status 1, standard error holds `trace.sh: a_test.sh exited 3` and then `  setup broke` |
| b | edge | as a | standard error does not name `b_test.sh` |
| c | failure | `spec a: CAP-1.1 VB not yet: r`; `a_test.sh` prints `FAIL NOPE-1.1: x` and `FAIL CAP-1.1 : x`, exit 0 | `CAP-1.1 not-yet r`, status 1, standard error `trace.sh: a_test.sh printed a FAIL line but exited 0` |

### TRACE-5.1: Other folders

Implemented by: T5.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | the current directory holds a decoy `docs/specs/decoy/spec.md` (`OTH-9.9`) and `scripts/tests/decoy_test.sh` (prints `FAIL OTH-9.9`, writes a file `ran`, exit 1); run with the fixture folders | only the fixture lines, status 0, and no `ran` file |
| b | edge | the folders given as relative paths from a fixture root, with a space in the folder names (`my specs`, `my tests`) | the same lines as with absolute paths |
| c | edge | the folders given with a trailing `/` | the same lines |
| d | edge | `tests/sub/b_test.sh` (`ok CAP-1.1; exit 0`) and `specs/sub/deeper/spec.md` (`OTH-2.2`) | neither appears: no recursion |

### TRACE-5.2: Wrong number of arguments

Implemented by: T5.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | failure | one argument, a valid specs folder | status 2, standard error holds `trace.sh [<specs> <tests>]`, standard output empty |
| b | failure | three arguments (both folders and an extra) | status 2, usage, standard output empty |
| c | failure | four arguments | status 2, usage |
| d | edge | any of a to c with a fixture `tests/a_test.sh` that writes a file `ran` | no `ran` file: nothing is run before the arguments are checked |

Zero arguments is the default mode; TRACE-5.4 c tests it on a fixture
repository, and the real specs and tests cover it when T10 runs `trace.sh`.

### TRACE-5.3: Missing folder

Implemented by: T5, extended in Review.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | failure | a specs folder that does not exist; a tests folder whose `a_test.sh` writes a file `ran` | status 2, no standard output, standard error `trace.sh: not a folder: <path>`, no `ran` file |
| b | failure | a tests folder that does not exist | status 2, the folder named on standard error |
| c | failure | a plain file given as the specs folder | status 2 |

### TRACE-5.4: No run from inside a test

Implemented by: T5, extended in Review. The cases run a copy of `trace.sh`
and `lib.sh` in a fixture repository, so that a broken guard runs the
fixture's tests and never `trace_test.sh` itself.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | failure | `TRACE_RUNNING=1`, no arguments; the fixture's `a_test.sh` writes a file `ran` | status 2, no standard output, standard error `trace.sh: already running the tests`, no `ran` file |
| b | edge | folders given; `a_test.sh` records `TRACE_RUNNING` | the usual line, status 0, and the test saw `TRACE_RUNNING=1` |
| c | normal | `TRACE_RUNNING` unset, no arguments, the fixture repository's `docs/specs` and `scripts/tests` | `CAP-1.1 tested a_test.sh`, status 0: the default folders are the script's own repository |

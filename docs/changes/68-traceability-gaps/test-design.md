# Test design: close the remaining traceability gaps

Part of the [change folder for #68](design.md).

The cases `scripts/tests/trace_test.sh` (T4) must cover for
[`scripts/trace.sh`](../../../scripts/trace.sh) (T3), one section per
scenario the [spec delta](specs/traceability/delta.md) adds or modifies in the
[traceability spec](../../specs/traceability/spec.md): TRACE-1.7, 1.8, 3.1,
3.4 and 5.5. The file follows [the template](../_template/test-design.md).
Every case below is implemented by T4. The cases of
[#65's test design](../65-traceability/test-design.md) for every other
scenario stay as they are, except where this file says a case changes.

## Shared fixtures and conventions

The fixture notation, the `check_run` helper and what `trace.sh` does are in
[#65's "Shared fixtures and conventions"](../65-traceability/test-design.md#shared-fixtures-and-conventions);
they hold here too (`mkspec`, `mktest`, `mkcheck`, `chk`, `check_err`, a
fixture per case, `sh` runs the script, `ok <label>` and `FAIL <label>` lines
starting with the scenario ID). What this change adds:

**Notation**

- `VB <l1> // <l2>` is a Verified by paragraph on two lines: `**Verified by:**
  <l1>` and `<l2>` on the next line, no blank line between. Each further `//`
  adds a line. T4 passes the line break as a newline inside the `mkspec` text.
  A line after the paragraph is still followed by `mkspec`'s blank line.
- `then <line>` after a `VB` means a hand-written spec: the same shape as
  `mkspec`'s (title, requirement heading, scenario heading, GIVEN/WHEN/THEN
  list), then the paragraph, then `<line>` directly, with no blank line
  between. `blank, <line>` puts a blank line between. Line numbers do not
  matter in these cases; the text of a spec is written by `printf`.

**Verified by paragraph (TRACE-3.1, 3.4)**

- The paragraph starts at a line starting `**Verified by:**` in column 1 and
  ends before the first blank line (empty or only spaces and tabs), heading
  or fence, or at the end of the file. A heading and a fence are as in
  TRACE-1: up to three spaces of indent. Four spaces is not one, so such a
  line is a continuation, joined like any other.
- Its text is the pieces joined with one space, each piece trimmed of spaces
  and tabs, and the whole text trimmed at both ends. So `**Verified by:**`
  alone on its line, followed by `[run](u)`, has the text `[run](u)`: no
  leading space. A paragraph whose text is empty counts as no paragraph and
  the next one is read, as in #65 case 3.1 j.
- A line starting `#66` is prose and is joined. No `\r` reaches any output
  line, in a wrapped paragraph too.
- Not tested, the code may choose: a second `**Verified by:**` line inside
  one paragraph.

**Recursion guard (TRACE-5.5)**

- `TRACE_RUNNING` holds physical folders, one per line, each as
  `cd <tests> && pwd -P` prints it. The test compares with `$(cd "$T" &&
  pwd -P)`, never with `$T`, because the temporary directory may be a link.
  A folder matches by the whole line: `tests2` and `my` are not `tests`
  and `my tests`.
- The refusal is `trace.sh: already running the tests in <physical folder>`
  on standard error, one line and nothing else, status 2, empty standard
  output. The refusal of a run without arguments keeps its text from
  TRACE-5.4 (`trace.sh: already running the tests; a test must pass
  folders`), and comes first when both apply. A tests folder that does not
  exist is TRACE-5.3's `not a folder` and comes before the guard, because
  the guard needs the physical path. Which message a run gets when two
  checks fail at once is otherwise not tested, only the status 2.
- `RERUN <specs> <tests>` in a fixture test means the line
  `sh "$TRACE" <specs> <tests> > "$0.out" 2> "$0.err"; echo $? > "$0.st"`,
  with the paths written in at build time. The fixture test then prints its
  own `ok` line and exits 0, whatever the inner status. It counts its calls
  in `$0.calls` (one line each) and does the rerun only on its first call, so
  a broken guard runs it twice and never forever. A working guard leaves one
  line in `$0.calls`. The inner run uses the real `trace.sh`; the fixture
  folders keep it from running `trace_test.sh`.
- `TRACE_RUNNING` is set for a case in one of two ways: through the outer run
  (`chk` on the fixture, so `trace.sh` sets it for the test, which is the
  flow TRACE-5.5 describes), or directly, as `TRACE_RUNNING=<value> sh
  "$TRACE" <specs> <tests>` when a case needs a value `trace.sh` would not
  build. `trace_test.sh` runs under `trace.sh` too (T6), so the value it
  starts with already holds `scripts/tests`; no case depends on it being
  unset except 5.4 c, which keeps `env -u TRACE_RUNNING`. A case that
  records the value checks for a whole line with `grep -x -F`, never for the
  whole value.
- Changes to #65's cases: 5.4 b (`TRACE_RUNNING=1`) becomes "the test saw its
  physical tests folder as a line of `TRACE_RUNNING`"; 5.4 a keeps
  `TRACE_RUNNING=1`, which a run without arguments refuses whatever it holds.

**Byte order (TRACE-1.8)**

- `pick_locale <candidate>...` prints the first candidate for which `LC_ALL=<c>
  sh -c 'cd "$1" && set -- *; echo "$*"' _ <probe>` prints `a B`, `<probe>`
  being a folder with files `B` and `a`, and prints nothing otherwise. The
  candidates are `en_US.UTF-8`, then the lines of `locale -a` that hold
  `utf8` or `utf-8` in any case, if `locale` exists. A locale the system does
  not have falls back to `C` and is not picked. On a machine whose `sh` is
  dash no locale is picked, because dash globs in byte order.
- The case sets `LC_ALL` for its run only and puts it back, not in a subshell,
  so the counters keep their values. The tests inside the fixture run in that
  locale too, which `trace.sh` does not change (design decision 4). The lines
  must be the same as in the `C` locale.
- The `ok` line says which case it was. With a locale: `ok   TRACE-1.8: a,
  B before a under <locale>`. Without: `ok   TRACE-1.8: a, B before a (no
  locale found in which the glob puts a before B; checked in the current
  locale)`. Both start with `TRACE-1.8:` so `trace.sh` reads them. A failure
  is `FAIL TRACE-1.8: a, ...` with the lines it got.

**Trial breaks.** The trial break of #65 (case TB) stays. This change adds
two, both in a subshell with their output discarded and both expecting the
helper to fail, printing `ok trial-break: ...` (naming no scenario) when it
did and `FAIL trial-break: ...` when it passed:

- TB2, order: the TRACE-1.8 fixture checked against the lines in glob order
  (`CAP-1.1 ...` before `OTH-1.1 ...`). It fails in every locale.
- TB3, rerun: the TRACE-5.5 a fixture with its `RERUN` run as `env -u
  TRACE_RUNNING sh ...`, so the guard cannot act. The inner run then runs the
  test again, `$0.calls` has two lines and the inner status is 0, so the
  rerun check must fail. This shows the check sees an unguarded rerun
  without editing `trace.sh`.

T4 also runs each new check against `main`'s `trace.sh` (task T4) and
reports which fail there: 1.7, 1.8 (only where a locale was found), 3.4 and
5.5 are expected to.

## Cases

### TRACE-1.7: Heading in another case

Implemented by: T4. Base fixture B: `spec a: CAP-1.1 VB not yet: r`, then the
line under test as line 13.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | failure | B with `#### scenario CAP-1.2: Name` | `CAP-1.1 not-yet r`, status 1, standard error `a/spec.md:13: not a scenario heading: #### scenario CAP-1.2: Name` |
| b | failure | B with `#### SCENARIO CAP-1.2: Name` | `CAP-1.1 not-yet r`, status 1, standard error `a/spec.md:13: not a scenario heading: #### SCENARIO CAP-1.2: Name` |
| c | failure | B with, on lines 13 to 16, `#### ScEnArIo CAP-1.2: Mixed`, `### scenario CAP-1.3: Level`, `#### scenario` and `####`, a tab, `SCENARIO CAP-1.4: Tab` | `CAP-1.1 not-yet r`, status 1, each of lines 13 to 16 named as not a scenario heading |
| d | edge | B with `#### Scenarios`, `#### scenarios` and `#### SCENARIOS` on lines 13 to 15 | `CAP-1.1 not-yet r`, status 0, nothing on standard error: a heading about scenarios in general is prose, in any case |
| e | edge | `spec a: CAP-1.1`, then `#### scenario CAP-1.2: Name`, a blank line and `**Verified by:** [run](https://example.org/1)` | `CAP-1.1 uncovered -`, status 1: the malformed heading ends CAP-1.1's scope, and its paragraph is nobody's |
| f | edge | B with a ```` ``` ```` block holding `#### scenario CAP-1.2: Name` and `#### SCENARIO CAP-1.3: Name` | `CAP-1.1 not-yet r`, status 0, nothing on standard error: code blocks are skipped |
| g | edge | case a with the spec in CRLF | the same line and status; no `\r` anywhere in standard error |

### TRACE-1.8: Byte order in any locale

Implemented by: T4.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | `spec B: OTH-1.1 VB not yet: r`; `spec a: CAP-1.1 VB not yet: s`; empty tests; `trace.sh` run with `LC_ALL` set to `pick_locale`'s result, or unchanged when it prints nothing | `OTH-1.1 not-yet r` then `CAP-1.1 not-yet s`, status 0; the `ok` line is the one of the conventions, for the locale or without one |
| b | edge | `spec a: CAP-1.1`; empty tests but `B_test.sh` and `a_test.sh`, both `ok CAP-1.1; exit 0`; same locale as a | `CAP-1.1 tested B_test.sh`, status 0: the first test file in byte order is the source |
| c | edge | `pick_locale C POSIX` | prints nothing: the picker does not accept a locale in which the glob gives `B a`. Label `TRACE-1.8: c, the locale picker rejects C and POSIX` |

Case c is how the "no locale found" branch is tested on a machine that has
one: the branch itself is only reached, and its `ok` line printed, on a
machine without a collating locale.

### TRACE-3.1: Evidence

Implemented by: T4. The wording changed from line to paragraph and the
behaviour did not: all of #65's cases 3.1 a to j stay and must pass
unmodified, which shows the one-line paragraph is unchanged.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | #65 case 3.1 a: `spec a: CAP-1.1 VB [fixture run](https://example.org/1)`; empty tests | `CAP-1.1 evidence [fixture run](https://example.org/1)`, status 0 |
| b | edge | `spec a: CAP-1.1`, `**Verified by:** [run](https://example.org/1)` as the last line of the file, with no final newline | `CAP-1.1 evidence [run](https://example.org/1)`: the end of the file ends the paragraph |

### TRACE-3.4: Wrapped Verified by paragraph

Implemented by: T4. Empty tests folder unless stated. `r`, `s` stand for
plain words.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | normal | `spec a: CAP-1.1 VB not yet: waits for the stub // and the review, #66` | `CAP-1.1 not-yet waits for the stub and the review, #66`, status 0 |
| b | normal | `spec a: CAP-1.1 VB see [fixture // run](https://example.org/1)` | `CAP-1.1 evidence see [fixture run](https://example.org/1)`, status 0: the link split over two lines counts |
| c | edge | `VB [run]( // https://example.org/1)` | `CAP-1.1 evidence [run]( https://example.org/1)`, status 0: joined with one space, nothing removed |
| d | edge | `VB not yet: a // b // c` | `CAP-1.1 not-yet a b c`: any number of lines |
| e | edge | `VB not yet: first   //     second line  ` (spaces at both ends and indent) | `CAP-1.1 not-yet first second line`: trimmed, joined by one space |
| f | edge | `VB not // yet: r` | `CAP-1.1 not-yet r`: `not yet` split over the lines still starts the text |
| g | edge | `VB [run](https://example.org/1) // not yet reviewed` | `CAP-1.1 evidence [run](https://example.org/1) not yet reviewed`: starts with a link, so evidence |
| h | edge | `VB` with empty text `// [run](https://example.org/1)` (the label alone on its line) | `CAP-1.1 evidence [run](https://example.org/1)`, no leading space |
| i | edge | `VB not yet: a // b`, then a later paragraph `**Verified by:** [run](https://example.org/1)` under the same scenario | `CAP-1.1 not-yet a b`: the first non-empty paragraph wins |
| j | edge | CRLF line endings in the spec of a | the same line as a, no `\r` |
| k | edge | `spec a: CAP-1.1`, `**Verified by:** not yet: a`, newline, `b` as the last two lines of the file, no final newline | `CAP-1.1 not-yet a b`: the end of the file ends the paragraph |
| l | failure | `VB see the // pull request` | `CAP-1.1 uncovered -`, status 1: wrapped text with neither a link nor `not yet` is no paragraph |
| m | edge | `VB not yet: r`, blank, `see [run](https://example.org/1)` | `CAP-1.1 not-yet r`: a blank line ends the paragraph; what follows is not joined |
| n | edge | `VB TODO`, blank, `[run](https://example.org/1)` | `CAP-1.1 uncovered -`, status 1: the later prose is not a paragraph of the scenario |
| o | edge | `VB not yet: r`, then a line of three spaces and a tab, then `[run](https://example.org/1)` | `CAP-1.1 not-yet r`: a line of only spaces and tabs is blank |
| p | edge | `VB not yet: r then #### Scenario CAP-1.2: S` (the heading directly after the paragraph) | `CAP-1.1 not-yet r`, `CAP-1.2 uncovered -`, status 1: a scenario heading ends the paragraph and is not joined |
| q | edge | `VB not yet: r then ## Other heading`, and `**Verified by:** [run](https://example.org/1)` under it | `CAP-1.1 not-yet r`, status 0: a heading of any level ends it, and the paragraph under it belongs to no scenario |
| r | edge | `VB not yet: r then` a ```` ```sh ```` block holding `#### Scenario EX-1.1: S`, closed by ```` ``` ```` and then `tail [run](https://example.org/1)` directly after | `CAP-1.1 not-yet r`, status 0: the fence ends the paragraph, and neither the block nor the tail is joined; no EX-1.1 line. The same with `~~~` |
| s | edge | `VB not yet: r then` `   #### Scenario CAP-1.2: S` (three spaces), and in another fixture the same with four spaces | three: `CAP-1.1 not-yet r`, `CAP-1.2 uncovered -`, status 1. Four: `CAP-1.1 not-yet r #### Scenario CAP-1.2: S`, no CAP-1.2 line, status 0: it is a continuation line |
| t | edge | `VB not yet: waits then #66 tracks this` | `CAP-1.1 not-yet waits #66 tracks this`: a `#` line that is not a heading is prose and joined |
| u | edge | `VB [run](https://example.org/1) // more`, and `a_test.sh: ok CAP-1.1; exit 0` | `CAP-1.1 tested a_test.sh`: a passing check still beats the paragraph |

### TRACE-5.5: No rerun of a tests folder from inside a test

Implemented by: T4. In the cases, `S` and `T` are the fixture folders, `T2` is
`$D/tests2` (a second tests folder, whose name starts with `T`'s), and the
fixture `spec a: CAP-1.1` gets `a_test.sh: RERUN <args>; ok CAP-1.1; exit 0`
(see the conventions). "Outer" is `chk` on `S` and `T`; "inner" is the run
`a_test.sh` starts. Unless stated the outer result is `CAP-1.1 tested
a_test.sh` and status 0.

| Case | Kind | Given (fixture) | Expected |
|---|---|---|---|
| a | failure | `RERUN "$S" "$T"` | inner status 2 (`a_test.sh.st` holds `2`), `.out` empty, `.err` the one line `trace.sh: already running the tests in <physical T>`, `a_test.sh.calls` one line: the test was not run again |
| b | failure | as a, each in its own fixture, with the tests folder as `$T/../tests`, `$T/`, `$T/.` and `$D/./tests` | the same inner status, message and one call in each: a path that resolves to the running folder is refused |
| c | failure | as a with `ln -s "$T" "$D/link"` and `RERUN "$S" "$D/link"` | the same. If `ln -s` makes no symbolic link (`[ -L "$D/link" ]` false, as in Git Bash by default), the case prints `ok   TRACE-5.5: c, symbolic link (skipped: no symbolic links here)` |
| d | normal | `spec b: OTH-1.1` in `S2`; `T2/b_test.sh: ok OTH-1.1; writes $0.ran; exit 0`; `a_test.sh` runs `RERUN "$S2" "$T2"` | inner status 0, `.out` is `OTH-1.1 tested b_test.sh`, `T2/b_test.sh.ran` exists: another tests folder runs its tests |
| e | edge | as d, `b_test.sh` records `$TRACE_RUNNING` and does `RERUN "$S" "$T"`, with `b_test.sh.calls` as in the conventions | in `b_test.sh.st` status 2 and the message names the physical `T`; the recorded value holds the physical `T` and the physical `T2` as whole lines; `a_test.sh.calls` one line |
| f | edge | `TRACE_RUNNING=/some/other` set directly, `S` and `T` given; `a_test.sh` records `$TRACE_RUNNING` | `CAP-1.1 tested a_test.sh`, status 0; the recorded value holds `/some/other` and the physical `T`, each as a whole line: a value from above is kept and extended |
| g | failure | `TRACE_RUNNING` set directly to `/some/other`, a newline and the physical `T`; `a_test.sh` writes `$0.ran` | status 2, no standard output, standard error the refusal message of the conventions, no `a_test.sh.ran`: the folder may be any line of the list |
| h | edge | the tests folder is `$D/my tests`, `RERUN "$S" "$D/my tests"` as the test; also `TRACE_RUNNING` set directly to the physical `$D/my` and the run on `my tests` | the rerun is refused, status 2 and message with the whole path; the run with the value `$D/my` runs its tests: a folder with a space matches as one line, not as words, and a prefix is no match |
| i | failure | `TRACE_RUNNING` set directly to the physical `T`, specs `S` and a tests folder `$D/nope` | status 2, standard error `trace.sh: not a folder: $D/nope` (TRACE-5.3's message), no standard output |
| j | edge | #65's 5.4 a, kept: `TRACE_RUNNING=1`, no arguments, in the fixture repository | status 2, `trace.sh: already running the tests` on standard error, no `ran` file: a run without arguments is refused whatever `TRACE_RUNNING` holds |

## Left open

- The spec does not say what `TRACE_RUNNING` holds; it says only "the tests
  folders of the runs above it". One physical path per line is design
  decision 3, and cases e to h depend on it.
- "The word `Scenario`" in TRACE-1 is not defined for a following digit or
  underscore (`Scenario2`); `Scenarios` and `SCENARIOS` are prose, and no
  case tests the others.
- TRACE-3 does not say what the text is when the label line is empty and the
  next line is not. This file decides: the text is trimmed as a whole
  (3.4 h).
- TRACE-1.8 can only be checked where `sh` collates in a locale; elsewhere it
  prints the fallback line and the byte-order check is a plain one.

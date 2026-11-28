# Tasks: close the remaining traceability gaps

Part of the [change folder for #68](design.md).

Build takes the next `todo` task whose dependencies are all `done`, and sets
its status in the commit that completes it. The format is in
[`docs/changes/README.md`](../README.md#tasksmd). Each task is routed by its
Kind and Complexity ([task routing spec](../../specs/task-routing/spec.md)).

| Stream | Tasks | Concern |
|---|---|---|
| A | T1 | The spec and the STAGE-2.x reason |
| B | T2, T3, T4 | Test design, the script and its test |
| C | T5 | The scripts README |
| D | T6 | Review |

T1 is the contract: every other stream depends on the spec it writes.

### T1: Apply the traceability delta

- **Stream:** A
- **Depends on:** none
- **Kind:** spec
- **Complexity:** low
- **Owns:** `docs/specs/traceability/spec.md`, `docs/specs/stage-transitions/spec.md`, `docs/specs/README.md`
- **Covers:** TRACE-1.7, TRACE-1.8, TRACE-3.1, TRACE-3.4, TRACE-5.5
- **Status:** done

Apply [the delta](specs/traceability/delta.md) to the living spec: replace
the TRACE-1, TRACE-3 and TRACE-5 requirement text and TRACE-3.1, and add
each new scenario after the last scenario of its requirement. In
`docs/specs/stage-transitions/spec.md`, set the Verified by line of
STAGE-2.1, 2.2 and 2.3 to `**Verified by:** not yet: stage.sh checks this
before it calls gh, but has no test yet, #66.` In `docs/specs/README.md`,
say that a Verified by paragraph may wrap and its lines are read joined.

### T2: Design the tests for the gaps

- **Stream:** B
- **Depends on:** T1
- **Kind:** test-design
- **Complexity:** medium
- **Owns:** `docs/changes/68-traceability-gaps/test-design.md`
- **Covers:** TRACE-1.7, TRACE-1.8, TRACE-3.1, TRACE-3.4, TRACE-5.5
- **Status:** done

Write the cases for each scenario the delta adds or modifies, in the
[template](../_template/test-design.md)'s form, reusing the fixture
notation and conventions of [#65's test design](../65-traceability/test-design.md)
by link rather than restating them. Cover at least: `scenario` and
`SCENARIO` headings, with `Scenarios` still prose; a two-line not-yet
reason, a link split over two lines, and a blank line, a heading and a
fence each ending the paragraph; a one-line TRACE-3.1 paragraph unchanged;
a rerun of the running tests folder refused, given directly and by a path
that resolves to it, and a different folder still run; folders `B` and `a`
in byte order under a collating locale, and the ok line when no such
locale exists (design decision 5). Name the trial break.

### T3: Close the gaps in trace.sh

- **Stream:** B
- **Depends on:** T1, T2
- **Kind:** implement
- **Complexity:** medium
- **Owns:** `scripts/trace.sh`
- **Covers:** TRACE-1.7, TRACE-1.8, TRACE-3.1, TRACE-3.4, TRACE-5.5
- **Status:** done

Design decisions 1 to 4: match the malformed check case-insensitively; read
the Verified by paragraph joined; keep the physical tests folders in
`TRACE_RUNNING`, one per line, and refuse a run whose tests folder is in
it; sort the spec and test file lists with `LC_ALL=C sort`. Update the
usage header. POSIX shell and awk as now; no `gh`, no network.

### T4: Test the gaps

- **Stream:** B
- **Depends on:** T2, T3
- **Kind:** test-unit
- **Complexity:** medium
- **Owns:** `scripts/tests/trace_test.sh`
- **Covers:** TRACE-1.7, TRACE-1.8, TRACE-3.1, TRACE-3.4, TRACE-5.5
- **Status:** done

Implement the cases in `test-design.md` in `trace_test.sh`'s existing
style, printing `ok <ID>: ...` or `FAIL <ID>: ...`, and update its header's
Covers line. Run each new check against `main`'s `trace.sh`
(`git show origin/main:scripts/trace.sh`) and report which fail there.

### T5: Update the scripts README

- **Stream:** C
- **Depends on:** T3
- **Kind:** docs
- **Complexity:** medium
- **Owns:** `scripts/README.md`
- **Covers:** none
- **Status:** done

In the `trace.sh` section: lines in byte order of the spec paths; the
heading check in any case; Verified by text read as a joined paragraph;
exit 2 also for a tests folder a run above is already running, with what
`TRACE_RUNNING` holds.

### T6: Review the change

- **Stream:** D
- **Depends on:** T1, T2, T3, T4, T5
- **Kind:** review
- **Complexity:** medium
- **Owns:** none
- **Covers:** none
- **Status:** done

Run `sh scripts/trace.sh` (it must exit 0, with TRACE-1.7, 1.8, 3.4 and 5.5
`tested` and STAGE-2.1 to 2.3 `not-yet` with the new reason),
`sh scripts/tests/trace_test.sh` and `sh scripts/tests/route_test.sh`.
Check that the spec, delta, `trace.sh`, its test and `test-design.md`
agree, that every document in "Where it lands" changed, and that links
resolve. Report each finding with file and line.

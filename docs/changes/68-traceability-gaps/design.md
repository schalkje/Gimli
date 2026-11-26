# Design: close the remaining traceability gaps

Part of the [change folders](../README.md).

- **Issue:** #68, the proposal: goal, scope and acceptance criteria.
- **Plan:** the `## Plan` comment on #68, with the Tests table and the
  risk assessment.
- **Tasks:** [`tasks.md`](tasks.md).
- **Spec deltas:** [traceability](specs/traceability/delta.md).

## Approach

Four small changes to [`scripts/trace.sh`](../../../scripts/trace.sh), each
closing a way a scenario slipped past it in the fifth review round of PR
#67, and one correction to the STAGE spec's Verified by lines. Each
behaviour change modifies a TRACE requirement and adds a scenario, so
`trace.sh` reports the new behaviour as `tested` like the rest. The cases
go in this folder's [`test-design.md`](test-design.md), and
[`scripts/tests/trace_test.sh`](../../../scripts/tests/trace_test.sh) gains
checks for them, following the fixture style it already has.

## Decisions

1. **Case-insensitive malformed check.** A heading whose text starts with
   the word `scenario` in any case, and is not exactly
   `#### Scenario <ID>:`, is malformed. Only the exact form is a scenario;
   `#### scenario CAP-1.2:` is reported, not accepted, so specs keep one
   spelling. New scenario TRACE-1.7.
2. **Verified by is a paragraph.** Its text is the `**Verified by:**` line
   and the lines after it up to a blank line, a heading or a fence, each
   trimmed and joined with one space (decided in Refine). The format in
   `docs/specs/README.md` already calls it a paragraph, so the format does
   not change; only the reading does. New scenario TRACE-3.4; TRACE-3.1 says
   paragraph instead of line, with the same behaviour, so it keeps its ID.
3. **Recursion is refused by folder.** `TRACE_RUNNING` holds the physical
   paths (`cd <tests> && pwd -P`) of the tests folders the runs above are
   running, one per line. A run whose tests folder is in that list exits 2
   before running a test, whether the folder came from arguments or the
   default. A run on another folder adds its own and goes on, so
   `trace_test.sh` keeps working. TRACE-5.4 stays as it is: a run without
   arguments is still refused whenever `TRACE_RUNNING` is set. New scenario
   TRACE-5.5. No ADR: this is how the TRACE-5 rule is enforced, not a new
   decision beside ADR 0005.
4. **Byte order by sorting, not by locale.** The spec and test file lists
   are sorted with `LC_ALL=C sort` instead of trusting the glob, whose order
   follows `LC_COLLATE` in bash and not in dash. The tests themselves still
   run in the caller's locale. New scenario TRACE-1.8.
5. **The locale check says when it cannot run.** TRACE-1.8's check picks a
   locale in which the glob puts `a` before `B`: it tries `en_US.UTF-8`,
   then the UTF-8 locales `locale -a` lists. When none does, it still
   checks the byte order and says in its `ok` line that no such locale was
   found, so the gap shows in the output instead of passing silently.
6. **STAGE-2.x stays not yet.** STAGE-2.1 to 2.3 get the reason
   `not yet: stage.sh checks this before it calls gh, but has no test yet,
   #66.` #66 writes the tests (decided in Refine). Verified by lines record
   coverage, not behaviour, so this needs no delta (#65 design decision 4).
   ADR 0005 is not edited: it is accepted on `main`, and its claim that all
   20 STAGE scenarios need the stub is corrected in the pull request body.

## Where it lands

This section is the plan's Documentation entry.

- `docs/specs/traceability/spec.md`: TRACE-1, TRACE-3 and TRACE-5
  requirement text, TRACE-3.1's THEN line, and scenarios TRACE-1.7, 1.8,
  3.4 and 5.5, from the delta.
- `docs/specs/stage-transitions/spec.md`: the Verified by reason of
  STAGE-2.1 to 2.3.
- `docs/specs/README.md`: a Verified by paragraph may wrap, and its lines
  are read joined.
- `scripts/trace.sh`: the four behaviour changes and its usage header.
- `scripts/tests/trace_test.sh`: checks for the new and modified scenarios.
- `scripts/README.md`: the `trace.sh` section: byte order, the
  case-insensitive heading check, the joined Verified by text, and exit 2
  for a tests folder already being run.
- `docs/changes/README.md`: the index row for this folder.

## Risks

- **Joining swallows the next paragraph.** A Verified by paragraph followed
  directly by prose, without a blank line, would take that prose in. The
  spec format puts a blank line after it, and T4 checks that a blank line,
  heading or fence ends it.
- **The recursion guard refuses a legitimate run.** A test that runs
  `trace.sh` on its own fixture folders must still work; T4 checks it, and
  every existing case in `trace_test.sh` is one.
- **A locale check that cannot fail on a machine.** Decision 5 makes the
  ok line say so; on Git Bash, where Test runs, `en_US.UTF-8` does change
  the glob order.

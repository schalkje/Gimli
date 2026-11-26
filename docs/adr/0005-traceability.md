# 0005. Trace every scenario to a passing check, evidence or a stated gap

Part of the [architecture decision records](README.md).

- **Status:** Accepted
- **Date:** 2026-11-25
- **Issue:** #65, from the roadmap in #46

## Context

Since [ADR 0002](0002-documentation-model.md), what Gimli does is written as
scenarios with IDs that are never reused, so tests and evidence can point at
them. Nothing checked that they do. `scripts/tests/route_test.sh` prints
`ok ROUTE-1.4: ...` for each passing check by convention, but the 20 STAGE
scenarios have no test, because `stage.sh` calls `gh` and there is no stub
yet, and parts of ROUTE were shown by runs recorded on pull requests. Which
scenarios anything backs up could only be found by reading every test and
pull request.

The roadmap in #46 wants the specs to drive the tests. Issue #65 asks for a
check that lists every scenario with its proof; its design is in the
[change folder](../changes/65-traceability/design.md). Refine left two
questions to decide: what the check does with a scenario that has no proof,
and where it learns which scenarios are covered.

## Decision

1. **Coverage comes from running the tests.** A scenario is tested only when
   a test file exits with status 0 and prints `ok <ID>:` for it, as
   [TRACE-2](../specs/traceability/spec.md#requirement-trace-2-tested-by-a-passing-check)
   states. An ID that appears in a test file is not enough.
2. **Everything else is in the spec.** A scenario without a passing check
   carries a `**Verified by:**` line under it: a link to its evidence, or
   `not yet` with a reason and the issue that will close it. Its format is in
   [`docs/specs/README.md`](../specs/README.md#format), and how the check reads
   it in
   [TRACE-3](../specs/traceability/spec.md#requirement-trace-3-verified-by).
   There is no separate coverage file.
3. **A stated gap passes, visibly.** `scripts/trace.sh` passes with `not-yet`
   scenarios and prints each one on every run. A scenario with neither a
   passing check nor a Verified by line, or with a failing check, fails it, as
   [TRACE-4](../specs/traceability/spec.md#requirement-trace-4-exit-status)
   states.

The rules the check applies are the [traceability spec](../specs/traceability/spec.md).

## Considered options

What the check does with a scenario that has no proof:

- **Fail, with stated gaps allowed.** Chosen: a new scenario must get a test
  or a Verified by line, and a known gap is admitted rather than hidden.
- **Report only.** Print the coverage and never fail. Gaps would be silent
  again, and nothing would make a new scenario get a test. Not chosen.
- **Fail without exceptions.** Every scenario tested or evidenced now. The
  STAGE scenarios need a `gh` stub first (#66), so this would block the change
  or force fake evidence. Not chosen.

Where coverage comes from:

- **The test output names the IDs, and the spec lists the rest.** Chosen:
  only a check that ran and passed counts, and the proof for the rest sits
  next to the scenario it backs.
- **A separate coverage file** mapping IDs to tests. One more file, which
  drifts from both the specs and the tests. Not chosen.
- **Grepping the test files for the IDs.** It counts tests that fail or never
  run, and IDs in comments. Not chosen.

## Consequences

- A scenario's proof is visible next to it in the spec, or in the test output
  that names it.
- The Test stage runs `trace.sh`, and Evidence pastes its lines for the
  scenarios a change touches ([`lifecycle.md`](../lifecycle.md#5-test)).
- A `not yet` line can become permanent. The reason and the issue it names
  are printed on every run, so the gap stays in sight.
- A test that proves a scenario must print its ID, so the style of the tests
  is now a rule ([`scripts/README.md`](../../scripts/README.md#tests)).
- `trace.sh` runs every test, so the tests must stay fast and offline.

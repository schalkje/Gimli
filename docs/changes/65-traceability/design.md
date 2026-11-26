# Design: spec-driven test design and a traceability check

Part of the [change folders](../README.md).

- **Issue:** #65, the proposal: goal, scope and acceptance criteria.
- **Plan:** the `## Plan` comment on #65, with the Tests table and the
  risk assessment.
- **Tasks:** [`tasks.md`](tasks.md).
- **Spec deltas:** [traceability](specs/traceability/delta.md), a new
  capability spec; [task-routing](specs/task-routing/delta.md).

## Approach

A scenario ID already ties a spec to its tests by convention:
`scripts/tests/route_test.sh` prints `ok ROUTE-1.4: ...` for each passing
check. This change makes that convention the rule and adds a check for it.

`scripts/trace.sh` reads every scenario heading in `docs/specs/`, runs every
`scripts/tests/*_test.sh`, and gives each scenario one status: `tested`
from a passing check line, `evidence` or `not-yet` from a `**Verified by:**`
line in the spec, `failing`, or `uncovered`. It exits 1 on `failing` or
`uncovered`. The rules are a new capability spec, `TRACE`, so the check
covers itself.

Test design becomes its own task kind. A `test-design` task writes
`test-design.md` in the change folder: for each scenario it covers, the
normal, edge and failure cases, and which test task implements them. Plan
adds one whenever a change's delta adds or modifies scenarios, and the
`implement`, `test-unit` and `test-e2e` tasks for those scenarios depend on
it.

## Decisions

1. **Coverage comes from running the tests.** A scenario is `tested` only
   when a test file exits 0 and prints `ok <ID>:`. Grepping test files for
   IDs would count tests that fail or never run. Recorded in ADR 0005.
2. **Everything else is in the spec.** A `**Verified by:**` paragraph under
   a scenario holds a link to its evidence, or `not yet` with a reason and
   the issue that will close it. No separate coverage file to drift.
   Recorded in ADR 0005.
3. **Not yet passes the check, visibly.** `trace.sh` exits 0 with not-yet
   scenarios, and prints each one. The gap is explicit instead of silent;
   a scenario with neither a test nor a line fails. Recorded in ADR 0005.
4. **Verified by lines are not spec changes.** They record coverage, not
   behaviour, so a change adds or edits them without a delta.
5. **`trace.sh` takes its folders as arguments.** `trace.sh [<specs>
   <tests>]`, defaulting to `docs/specs` and `scripts/tests`, so
   `trace_test.sh` runs it on fixture folders in a temporary directory and
   never runs itself.
6. **Status words and output.** One line per scenario,
   `<ID> <status> <source>`; statuses `tested`, `evidence`, `not-yet`,
   `failing`, `uncovered`; source `-` when there is none. Evidence pastes
   the lines for the scenarios a change touches.
7. **`test-design` routing.** low `sonnet medium`, medium `sonnet high`,
   high `opus high`: deciding what to test is reasoning work, and its
   quality bounds every test written after it. The agent
   `gimli-test-design` writes documents only, so it has no Bash.
8. **The follow-up exists before Build.** Plan creates the issue (#66) for the
   `gh` stub and the STAGE tests when it is applied, so the STAGE Verified
   by lines can link it.
9. **Bootstrap.** This change is routed, but its own test design (T3) is a
   `design` task, because the `test-design` kind and its agent only exist
   after T7.

## Where it lands

This section is the plan's Documentation entry.

- `docs/specs/traceability/spec.md` (new): the `TRACE` spec, from the
  delta; a row in the index of `docs/specs/README.md`.
- `docs/specs/README.md`: the Verified by line in Format.
- `docs/specs/stage-transitions/spec.md`: a not-yet Verified by line per
  scenario, linking the follow-up, #66.
- `docs/specs/task-routing/spec.md`: the `test-design` row and ROUTE-1.4,
  from the delta; evidence Verified by lines for ROUTE-3.1, 3.2 and 4.1, and
  not yet for ROUTE-3.3 (#64).
- `docs/adr/0005-traceability.md` (new): decisions 1 to 3; a row in the
  index of `docs/adr/README.md`.
- `scripts/trace.sh` and `scripts/tests/trace_test.sh` (new): a `trace.sh`
  section and the test naming convention in `scripts/README.md`.
- `.claude/agents/gimli-test-design.md` (new): a row in the roster of
  `docs/architecture/agents.md` and in the documentation map of `README.md`.
- `scripts/route.sh`: the `test-design` kind and its cells.
- `docs/changes/README.md`: `test-design` in the kinds, `test-design.md` in
  the files, and the Plan rule.
- `docs/changes/_template/test-design.md` (new): the template.
- `.claude/skills/plan/SKILL.md`: the Plan rule.
- `docs/lifecycle.md`: Test runs `trace.sh`; Evidence pastes its lines.
- `.github/PULL_REQUEST_TEMPLATE.md`: the Test output comment asks for the
  `trace.sh` lines.
- `docs/architecture/README.md`: traceability among the scripts, and the
  principle "Every scenario is tested, evidenced or marked not yet".
- `CLAUDE.md`: the scripts line names tracing.

## Risks

- **A test that prints `ok` for a broken check.** `trace.sh` also requires
  the test file to exit 0, and T5 checks a failing fixture.
- **Parsing Markdown in shell.** The spec format is fixed in
  `docs/specs/README.md`; T5 runs `trace.sh` on fixtures with the edge cases
  in T3's test design.
- **Not yet becomes permanent.** Each not-yet line names a reason and,
  where one exists, the issue that closes it; `trace.sh` prints them on
  every run.

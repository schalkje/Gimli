# Tasks: spec-driven test design and a traceability check

Part of the [change folder for #65](design.md).

Build takes the next `todo` task whose dependencies are all `done`, and sets
its status in the commit that completes it. The format is in
[`docs/changes/README.md`](../README.md#tasksmd). Each task is routed by its
Kind and Complexity ([task routing spec](../../specs/task-routing/spec.md)).

| Stream | Tasks | Concern |
|---|---|---|
| A | T1, T2 | The rule and its decision |
| B | T3, T4, T5 | Test design, the check and its test |
| C | T6, T7 | Verified by lines and the `test-design` kind |
| D | T8, T9 | The Plan skill and the process documents |
| E | T10 | Review |

T1 is the contract: every other stream depends on the spec it writes.

### T1: Write the traceability spec

- **Stream:** A
- **Depends on:** none
- **Kind:** spec
- **Complexity:** medium
- **Owns:** `docs/specs/traceability/spec.md`, `docs/specs/README.md`
- **Covers:** TRACE-1.1, TRACE-1.2, TRACE-2.1, TRACE-2.2, TRACE-2.3, TRACE-3.1, TRACE-3.2, TRACE-4.1, TRACE-4.2, TRACE-5.1, TRACE-5.2
- **Status:** done

Create the living spec from [the delta](specs/traceability/delta.md), using
the spec template, with `scripts/trace.sh` as what implements it and
ADR 0005 as its decision. Add its row to the index in `docs/specs/README.md`,
and define the `**Verified by:**` line in its Format section: a paragraph
under a scenario's list, holding a link to the evidence, or `not yet` with a
reason and, where one exists, the issue that will close it.

### T2: Record ADR 0005

- **Stream:** A
- **Depends on:** T1
- **Kind:** docs
- **Complexity:** high
- **Owns:** `docs/adr/0005-traceability.md`, `docs/adr/README.md`
- **Covers:** none
- **Status:** done

Decisions 1 to 3 of the design, with the options from Refine: fail, report
only, or fail without exceptions; coverage from test output, a coverage
file, or grepping test files. Status `Accepted`, the next number unused on
`main`, and the index row.

### T3: Design the tests for the traceability check

- **Stream:** B
- **Depends on:** T1
- **Kind:** design
- **Complexity:** medium
- **Owns:** `docs/changes/_template/test-design.md`, `docs/changes/65-traceability/test-design.md`
- **Covers:** TRACE-1.1, TRACE-1.2, TRACE-2.1, TRACE-2.2, TRACE-2.3, TRACE-3.1, TRACE-3.2, TRACE-4.1, TRACE-4.2, TRACE-5.1, TRACE-5.2
- **Status:** done

Write the template: per scenario, its ID, the cases to test (normal, edge,
failure) with the expected result, and the task that implements them. Then
fill it for every TRACE scenario: the fixture specs and test files each case
needs, and edge cases such as a scenario with both a passing check and a
Verified by line, a test file that prints `ok` and exits 1, CRLF line
endings, and an empty tests folder.

### T4: Add scripts/trace.sh

- **Stream:** B
- **Depends on:** T1, T3
- **Kind:** implement
- **Complexity:** medium
- **Owns:** `scripts/trace.sh`
- **Covers:** TRACE-1.1, TRACE-1.2, TRACE-2.1, TRACE-2.2, TRACE-2.3, TRACE-3.1, TRACE-3.2, TRACE-4.1, TRACE-4.2, TRACE-5.1, TRACE-5.2
- **Status:** done

POSIX shell, following `route.sh`: a usage header, `lib.sh` for `usage`,
`trace.sh [<specs> <tests>]`. Collect scenario IDs and Verified by lines
from each `<specs>/*/spec.md` except `_template`, run each
`<tests>/*_test.sh` with `sh`, collect `ok` and `FAIL` lines and exit
statuses, and print `<ID> <status> <source>` per scenario. Exit as TRACE-4
and TRACE-5 say. No `gh`, no network.

### T5: Test trace.sh against its spec

- **Stream:** B
- **Depends on:** T3, T4
- **Kind:** test-unit
- **Complexity:** medium
- **Owns:** `scripts/tests/trace_test.sh`
- **Covers:** TRACE-1.1, TRACE-1.2, TRACE-2.1, TRACE-2.2, TRACE-2.3, TRACE-3.1, TRACE-3.2, TRACE-4.1, TRACE-4.2, TRACE-5.1, TRACE-5.2
- **Status:** done

Implement the cases in `test-design.md`: build fixture spec and tests
folders in a temporary directory, run `trace.sh` on them, and check each
line and exit status, printing `ok <ID>: ...` or `FAIL <ID>: ...` in
`route_test.sh`'s style. Remove the temporary directory. Show that a check
can fail.

### T6: Add Verified by lines to the existing specs

- **Stream:** C
- **Depends on:** T1
- **Kind:** spec
- **Complexity:** low
- **Owns:** `docs/specs/stage-transitions/spec.md`, `docs/specs/task-routing/spec.md`
- **Covers:** none
- **Status:** done

Every STAGE scenario gets `**Verified by:** not yet: stage.sh calls gh;
needs a gh stub, #66.` ROUTE-3.1 to 3.3 get a link to the fixture
run on #60 (PR #62, summarised in PR #59), and ROUTE-4.1 to the run on #61
(PR #63). ROUTE-1 and ROUTE-2 get none; `route_test.sh` covers them.

### T7: Add the test-design kind

- **Stream:** C
- **Depends on:** T3, T6
- **Kind:** implement
- **Complexity:** medium
- **Owns:** `.claude/agents/gimli-test-design.md`, `scripts/route.sh`, `docs/specs/task-routing/spec.md`, `docs/changes/README.md`
- **Covers:** ROUTE-1.1, ROUTE-1.2, ROUTE-1.3, ROUTE-1.4, ROUTE-2.1
- **Status:** done

Apply [the routing delta](specs/task-routing/delta.md): the `test-design`
row and ROUTE-1.4. Add the kind and its cells to `route.sh`. Write
`gimli-test-design.md` like the other agents, with the medium cell as its
default and tools Read, Grep, Glob, Edit, Write. In `docs/changes/README.md`
add the kind, `test-design.md` to the files table, and the rule that a
change whose delta adds or modifies scenarios gets a `test-design` task the
test tasks depend on. Run `sh scripts/tests/route_test.sh`.

### T8: Teach /plan the test-design rule

- **Stream:** D
- **Depends on:** T7
- **Kind:** implement
- **Complexity:** medium
- **Owns:** `.claude/skills/plan/SKILL.md`
- **Covers:** none
- **Status:** todo

Where the plan writes `tasks.md` for a change folder: when a delta adds or
modifies scenarios, add a `test-design` task covering them, and make each
`test-unit` and `test-e2e` task for those scenarios depend on it. Link the
rule in `docs/changes/README.md` instead of restating it.

### T9: Update the process documents

- **Stream:** D
- **Depends on:** T4, T7, T8
- **Kind:** docs
- **Complexity:** medium
- **Owns:** `docs/lifecycle.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `scripts/README.md`, `docs/architecture/README.md`, `docs/architecture/agents.md`, `README.md`, `CLAUDE.md`
- **Covers:** none
- **Status:** todo

`docs/lifecycle.md`: Test runs `scripts/trace.sh`; Evidence pastes its lines
for the scenarios the change touches. The pull request template's Test
output comment asks for those lines. `scripts/README.md`: a `trace.sh`
section, and the `ok <ID>:` convention under Tests.
`docs/architecture/README.md`: traceability in the Scripts row and the
principle. `docs/architecture/agents.md` and `README.md`: the new agent.
`CLAUDE.md`: the scripts line.

### T10: Review the change

- **Stream:** E
- **Depends on:** T1, T2, T3, T4, T5, T6, T7, T8, T9
- **Kind:** review
- **Complexity:** medium
- **Owns:** none
- **Covers:** none
- **Status:** todo

Run `sh scripts/trace.sh` (it must exit 0 and list all scenarios),
`sh scripts/tests/route_test.sh` and `sh scripts/tests/trace_test.sh`.
Check that the spec, `trace.sh`, its test and `test-design.md` agree, that
every document in "Where it lands" changed, and that links resolve. Report
each finding with file and line.

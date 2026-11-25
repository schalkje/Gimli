# Tasks: agent roster and model routing for tasks

Part of the [change folder for #58](design.md).

Build takes the next `todo` task whose dependencies are all `done`, and sets
its status in the commit that completes it. The format is in
[`docs/changes/README.md`](../README.md#tasksmd). Until this change merges,
Build does these tasks itself; routing applies from the next change.

| Stream | Tasks | Concern |
|---|---|---|
| A | T1, T2 | The rule and its decision |
| B | T3, T4 | The lookup script and its test |
| C | T5 | The agents |
| D | T6, T8 | Architecture and process documents |
| E | T7 | The Build skill |
| F | T9 | Checks |

T1 is the contract: every other stream depends on the spec it writes.

### T1: Write the task routing spec

- **Stream:** A
- **Depends on:** none
- **Kind:** spec
- **Complexity:** medium
- **Owns:** `docs/specs/task-routing/spec.md`, `docs/specs/README.md`
- **Covers:** ROUTE-1.1, ROUTE-1.2, ROUTE-1.3, ROUTE-1.4, ROUTE-2.1, ROUTE-2.2, ROUTE-2.3, ROUTE-3.1, ROUTE-3.2, ROUTE-3.3, ROUTE-4.1
- **Status:** done

Create the living spec from [the delta](specs/task-routing/delta.md), using
the spec template, with `scripts/route.sh` and `.claude/skills/build/SKILL.md`
as what implements it and ADR 0004 as its decision. Add its row to the index
in `docs/specs/README.md`.

### T2: Record ADR 0004

- **Stream:** A
- **Depends on:** T1
- **Kind:** docs
- **Complexity:** high
- **Owns:** `docs/adr/0004-task-routing.md`, `docs/adr/README.md`
- **Covers:** none
- **Status:** done

Decisions 2, 6, 9 and 10 of the design, with the roster options from Refine
(one agent per kind, per kind and tier, or a few roles), the commit options
(agent commits, or Build commits), and what was left for later (decision
12). Status `Accepted`, the next number unused
on `main`, and the index row.

### T3: Add scripts/route.sh

- **Stream:** B
- **Depends on:** T1
- **Kind:** implement
- **Complexity:** low
- **Owns:** `scripts/route.sh`, `scripts/README.md`
- **Covers:** ROUTE-1.1, ROUTE-1.2, ROUTE-1.3, ROUTE-1.4, ROUTE-2.1, ROUTE-2.2, ROUTE-2.3
- **Status:** done

POSIX shell, following `risk.sh`: a usage header, `lib.sh` for `usage` and
`in_list` if they fit, the table as a `case` statement, status 2 on invalid
input with nothing on standard output. A `route.sh` section and a tests
section in `scripts/README.md`.

### T4: Test route.sh against the spec

- **Stream:** B
- **Depends on:** T3
- **Kind:** test-unit
- **Complexity:** medium
- **Owns:** `scripts/tests/route_test.sh`
- **Covers:** ROUTE-1.1, ROUTE-1.2, ROUTE-1.3, ROUTE-1.4, ROUTE-2.1, ROUTE-2.2, ROUTE-2.3
- **Status:** done

Read the routing table from `docs/specs/task-routing/spec.md` with `awk`,
run `route.sh` for every cell and check the agent, model and effort, then check the three
invalid-input scenarios for status 2 and empty standard output. One line per
check, a summary line, and a non-zero exit on any failure. Fail too if the
table has fewer than 21 cells, so a broken parse cannot pass.

### T5: Add the agent roster

- **Stream:** C
- **Depends on:** T1
- **Kind:** implement
- **Complexity:** medium
- **Owns:** `.claude/agents/gimli-design.md`, `.claude/agents/gimli-spec.md`, `.claude/agents/gimli-implement.md`, `.claude/agents/gimli-test-unit.md`, `.claude/agents/gimli-test-e2e.md`, `.claude/agents/gimli-docs.md`, `.claude/agents/gimli-review.md`
- **Covers:** ROUTE-3.2
- **Status:** done

One file per kind: `name`, a `description` that names the kind and says it
is called by `/build` for one task, `model` and `effort` as design decision
7 gives. The body says what the agent is given (the context packet), that it
changes only the files in its task's Owns list, reads more only on demand,
leaves to scripts and tools what they do reliably, never commits, pushes,
labels or comments, and reports the files it changed and anything it could
not do.

### T6: Describe the roster and the context packet

- **Stream:** D
- **Depends on:** T1, T5
- **Kind:** docs
- **Complexity:** medium
- **Owns:** `docs/architecture/agents.md`, `docs/architecture/README.md`
- **Covers:** none
- **Status:** todo

`docs/architecture/agents.md`: the seven agents and their defaults, the
context packet and why (ADR 0001), the Owns check, the rule that agents
leave deterministic work to scripts and tools, and links to the spec,
`route.sh` and ADR 0004. In `docs/architecture/README.md`, an Agents row in
the parts table and the principle "Agents change only their task's files;
Build commits", linking ROUTE-3.

### T7: Teach /build to delegate tasks

- **Stream:** E
- **Depends on:** T3, T5, T6
- **Kind:** implement
- **Complexity:** high
- **Owns:** `.claude/skills/build/SKILL.md`
- **Covers:** ROUTE-3.1, ROUTE-3.2, ROUTE-3.3, ROUTE-4.1
- **Status:** todo

In step 3, for a change folder: for each task, run `scripts/route.sh` on its
Kind and Complexity, assemble the context packet, call the Agent tool with
the agent, model and effort; check the
changed files against Owns (`git status --porcelain`), return the task once
or record a deviation when they differ, then set the status and commit with
a `Routed: <agent> <model> <effort>` line. A task
with no Kind or Complexity, or a `route.sh` error, is a deviation and Build
stops at the gate. A comment plan is built in the main session, unchanged.

### T8: Update the process documents

- **Stream:** D
- **Depends on:** T6, T7
- **Kind:** docs
- **Complexity:** medium
- **Owns:** `docs/lifecycle.md`, `docs/changes/README.md`, `CLAUDE.md`, `README.md`
- **Covers:** none
- **Status:** todo

`docs/lifecycle.md`: the Build activity says tasks of a change folder are
routed to agents, linking the spec. `docs/changes/README.md`: Kind and
Complexity choose the agent, linking the spec for what each `docs` level
means; adding a kind also changes the roster, `route.sh` and the spec. `CLAUDE.md`: `.claude/agents/` and `scripts/tests/`
in Repository layout. `README.md`: a map row per agent and `.claude/agents/`
in the layout tree.

### T9: Run the checks

- **Stream:** F
- **Depends on:** T1, T2, T3, T4, T5, T6, T7, T8
- **Kind:** review
- **Complexity:** low
- **Owns:** none
- **Covers:** none
- **Status:** todo

Run `sh scripts/tests/route_test.sh` and the link check from `README.md`;
check this folder against the templates.

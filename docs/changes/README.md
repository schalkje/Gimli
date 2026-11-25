# Change folders

Part of the [Gimli documentation](../../README.md#documentation). The decisions
behind change folders are in [ADR 0003](../adr/0003-change-folders.md).

A change folder holds the plan of one large change: how it is built, the work
split into tasks, and what it changes in the capability specs. It lets a large
change be delivered as one pull request, with work that can later run in
parallel streams on the right agent.

A change folder does not restate what lives elsewhere:

| Where | Holds |
|---|---|
| The issue body | The proposal: goal, scope, requirements, acceptance criteria. |
| The `## Plan` comment | The link to the folder, the Tests table and the risk assessment. |
| The change folder | The design, including the plan's Documentation entry in `design.md`, the tasks and the spec deltas. |

## When a change gets a folder

The Plan stage decides. A change gets a folder when at least one of these
holds:

- it adds, changes or removes requirements in a capability spec;
- its work falls into more than one stream;
- it has more than about five steps.

Otherwise the `## Plan` comment is the whole plan, as described in the Plan
stage of [`lifecycle.md`](../lifecycle.md#3-plan).

## Location and files

A change folder is `docs/changes/<issue>-<slug>/`: the issue number and a few
lowercase words joined with hyphens. It holds:

| File | Holds | Template |
|---|---|---|
| `design.md` | How the change is built: approach, decisions, where they land, risks. | [`_template/design.md`](_template/design.md) |
| `test-design.md` | The cases the tests must cover, per scenario. | [`_template/test-design.md`](_template/test-design.md) |
| `tasks.md` | The work as tasks, in the format below. | [`_template/tasks.md`](_template/tasks.md) |
| `specs/<capability>/delta.md` | One per capability spec the change touches, in the format below. | [`_template/specs/capability/delta.md`](_template/specs/capability/delta.md) |

The templates sit at the same depth as a real change folder, so their links
are right when copied.

## Life of a change folder

| Stage | What happens |
|---|---|
| Plan | Plan writes the folder, creates the change branch, commits the folder, opens the draft pull request, and posts the `## Plan` comment linking to it. When the issue returns to Plan, Plan updates the folder on the existing branch and pull request, keeping the status of tasks already done. |
| Build | Build follows `tasks.md` and applies each delta to its living spec as a `spec` task, so the documentation rule holds. |
| Review | The folder is reviewed with the rest of the pull request. |
| Merge | The folder stays in `docs/changes/` as the record of the change. |

Merging deltas into the living specs automatically, and archiving old
folders, are later work (#46, Track A step 7).

## tasks.md

`tasks.md` starts with a table of streams, then one section per task:

```markdown
### T<n>: <title>

- **Stream:** <letter>
- **Depends on:** <task IDs, or none>
- **Kind:** <kind>
- **Complexity:** <low | medium | high>
- **Owns:** <files the task creates or changes, or none>
- **Covers:** <scenario IDs the task implements or tests, or none>
- **Status:** <todo | done | deferred>

<What the task does, in a few sentences.>
```

| Field | Rule |
|---|---|
| Task ID | `T1`, `T2`, ... in the order written; never reused within the folder. |
| Stream | A letter. Tasks in different streams can run in parallel once their dependencies are done. |
| Depends on | Task IDs that must be `done` first. The dependencies form no cycle. |
| Kind | One of `design`, `spec`, `test-design` (decides the cases the tests cover and writes `test-design.md`), `implement`, `test-unit`, `test-e2e`, `docs`, `review`. With Complexity, chooses the agent that does the task. |
| Complexity | `low`, `medium` or `high`. Chooses the agent's model and effort; what each level means for `docs` is in [ROUTE-1](../specs/task-routing/spec.md#requirement-route-1-route-a-task-by-kind-and-complexity). |
| Owns | The files the task changes. Two tasks in different streams own different files, so parallel work does not conflict. |
| Covers | The scenario IDs, in the form of [`specs/README.md`](../specs/README.md#scenario-ids), that the task implements or tests. |
| Status | `todo` until done. Build sets `done` in the commit that completes the task, or `deferred` with a `## Build: deviation` comment saying why. A task that depends on a `deferred` task is deferred too. On re-entry, a deferred task that review or the return note asks for goes back to `todo`, with the tasks deferred because of it. |

The kinds and complexity levels are a fixed list, so Build can choose an
agent, model and effort from them, as the
[task routing spec](../specs/task-routing/spec.md) says. Adding a kind is a
change to this document, and also needs an agent in `.claude/agents/`, a row
in the routing table and a change to `scripts/route.sh`;
`scripts/tests/route_test.sh` reads the kinds from the table and fails until
the table and the script agree.

A task that defines what other streams build on, such as an interface or a
format, comes first, and the other streams depend on it.

### Test design task

When a change's spec delta adds or modifies scenarios, `tasks.md` has a
`test-design` task covering them, and every `implement`, `test-unit` and
`test-e2e` task for those scenarios depends on it. The task writes `test-design.md`, so the
tests and the code are decided from the same cases: its Owns list names
`test-design.md`, and Build gives that file to each task that depends on it
([context packet](../architecture/agents.md#context-packet)).

## Spec deltas

A delta says what a change does to one capability spec. It has four sections,
each `None.` when empty:

| Section | Holds |
|---|---|
| `## ADDED` | New requirements and scenarios, written as they will appear in the spec, with the next IDs never used on `main`. |
| `## MODIFIED` | Changed requirements and scenarios, each in full as it will read, keeping its ID. |
| `## REMOVED` | Removed requirements and scenarios, by ID and name, with the reason. |
| `## Retired by this change` | Every ID the change gives up: the removed ones, a removed requirement's number and all its scenario IDs. |

A delta follows the ID rules in [`specs/README.md`](../specs/README.md#scenario-ids):
a changed scenario that describes the same behaviour keeps its ID, a removed
one is retired, and no ID is ever reused. The section names follow OpenSpec's
ADDED, MODIFIED and REMOVED.

## Index

| Change folder | Issue |
|---|---|
| [`52-change-folder`](52-change-folder/design.md) | #52: the change folder and tasks format |
| [`58-task-routing`](58-task-routing/design.md) | #58: agent roster and model routing for tasks |
| [`65-traceability`](65-traceability/design.md) | #65: spec-driven test design and a traceability check |

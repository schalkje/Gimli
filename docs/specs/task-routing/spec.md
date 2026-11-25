# Task routing

Part of the [Gimli specs](../README.md).

- **Prefix:** `ROUTE`
- **Implemented by:** [`scripts/route.sh`](../../../scripts/route.sh), tested
  by [`scripts/tests/route_test.sh`](../../../scripts/tests/route_test.sh);
  [`.claude/skills/build/SKILL.md`](../../../.claude/skills/build/SKILL.md)
  for delegation; the agents in `.claude/agents/`, described in
  [Agents](../../architecture/agents.md).
- **Decisions:** [ADR 0004](../../adr/0004-task-routing.md).

Build hands each task of a [change folder](../../changes/README.md) to an
agent whose model and effort fit the task's kind and complexity, and keeps
the commits itself. The task fields are defined in
[`docs/changes/README.md`](../../changes/README.md#tasksmd).

## Requirements

### Requirement ROUTE-1: Route a task by kind and complexity

Given a task's kind and complexity, the system SHALL print the agent, model
and effort from this table, as one line `<agent> <model> <effort>`. The agent
is `gimli-<kind>`; each cell gives the model and the effort, chosen
independently.

| Kind | low | medium | high |
|---|---|---|---|
| design | sonnet medium | sonnet high | opus high |
| spec | sonnet medium | sonnet high | opus high |
| implement | sonnet low | sonnet medium | opus high |
| test-unit | haiku low | sonnet low | sonnet medium |
| test-e2e | sonnet low | sonnet medium | opus high |
| docs | haiku low | sonnet medium | opus high |
| review | sonnet high | opus medium | opus high |

For `docs`, the levels mean: `low` is a mechanical change the task states
exactly, such as a version number, a named parameter, spelling, or a README
line for a described change; `medium` is deciding what to write, explaining
new behaviour, updating architecture documents, or keeping several files in
step; `high` is recording decisions and their trade-offs, or resolving
documents that conflict.

The table is the default routing policy. Complexity chooses the model and
effort; the issue's risk tier chooses the assurance (review and human
approval), not a stronger model.

#### Scenario ROUTE-1.1: High complexity

- **WHEN** `scripts/route.sh implement high` runs
- **THEN** it prints `gimli-implement opus high` and exits with status 0

#### Scenario ROUTE-1.2: Low complexity

- **WHEN** `scripts/route.sh docs low` runs
- **THEN** it prints `gimli-docs haiku low` and exits with status 0

#### Scenario ROUTE-1.3: Effort independent of model

- **WHEN** `scripts/route.sh review low` runs
- **THEN** it prints `gimli-review sonnet high` and exits with status 0

#### Scenario ROUTE-1.4: Every cell

- **WHEN** `scripts/route.sh` runs for each of the 21 kind and complexity
  pairs in the table
- **THEN** each prints the agent and the model and effort in that cell

### Requirement ROUTE-2: Reject invalid input

The system SHALL exit with status 2, print nothing on standard output, and
name the valid values when its input is invalid.

#### Scenario ROUTE-2.1: Unknown kind

- **WHEN** `scripts/route.sh deploy low` runs
- **THEN** it names the valid kinds and exits with status 2

#### Scenario ROUTE-2.2: Unknown complexity

- **WHEN** `scripts/route.sh implement extreme` runs
- **THEN** it names the valid complexity levels and exits with status 2

#### Scenario ROUTE-2.3: Wrong number of arguments

- **WHEN** `scripts/route.sh` runs with no arguments, one, or more than two
- **THEN** it prints its usage and exits with status 2

### Requirement ROUTE-3: Delegate the tasks of a change folder

When Build works through a change folder's `tasks.md`, it SHALL hand each
task to the agent and model `route.sh` gives, one task at a time, taking
the next `todo` task whose dependencies are done, lowest ID first, and make
the commit itself.

#### Scenario ROUTE-3.1: Task handed to its agent

- **GIVEN** a `todo` task of kind `implement` and complexity `high` whose
  dependencies are `done`
- **WHEN** Build takes it
- **THEN** it calls the agent `gimli-implement` with model `opus` and effort
  `high`
- **AND** gives it the task's section of `tasks.md`, its Owns list, the
  Decisions of `design.md`, the spec sections for the scenarios it covers,
  and the architecture principles

#### Scenario ROUTE-3.2: Build commits

- **GIVEN** an agent has finished a task and changed only files in its Owns
  list
- **WHEN** Build continues
- **THEN** Build sets the task's status to `done` and commits the change
- **AND** the commit message has a line `Routed: <agent> <model> <effort>`
  with what `route.sh` gave
- **AND** the branch, its last commit and its remote copy are as before
  the agent ran; if not, Build stops and reports it

#### Scenario ROUTE-3.3: File outside the task

- **GIVEN** an agent changed a file that is not in its task's Owns list
- **WHEN** Build checks the changed files
- **THEN** Build reverts the change and returns the task to the agent once
  with the Owns list
- **AND** if the agent changes such a file again, Build reverts it or keeps
  it, and records either as a deviation
- **AND** it never commits such a change without a deviation

### Requirement ROUTE-4: No routing without a change folder

When a change has no change folder, Build SHALL do the work itself, without
delegating.

#### Scenario ROUTE-4.1: Comment plan

- **GIVEN** an issue whose `## Plan` comment links no change folder
- **WHEN** `/build` runs
- **THEN** it implements the plan's Steps in the main session and calls no
  `gimli-*` agent

## Retired scenario IDs

None.

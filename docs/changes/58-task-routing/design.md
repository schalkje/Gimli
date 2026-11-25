# Design: agent roster and model routing for tasks

Part of the [change folders](../README.md).

- **Issue:** #58, the proposal: goal, scope and acceptance criteria.
- **Plan:** the `## Plan` comment on #58, with the Tests table and the
  risk assessment.
- **Tasks:** [`tasks.md`](tasks.md).
- **Spec deltas:** [task-routing](specs/task-routing/delta.md), a new
  capability spec.

## Approach

A task in a change folder already has a Kind and a Complexity
([`docs/changes/README.md`](../README.md#tasksmd)). This change turns those
two fields into a choice of agent, model and effort, and makes `/build` hand
each task to that choice instead of doing the work in the main session.

Three parts, each with one job:

- **The rule** is a new capability spec, `docs/specs/task-routing/spec.md`,
  prefix `ROUTE`. It holds the routing table from the issue and the
  scenarios for delegation.
- **The lookup** is `scripts/route.sh <kind> <complexity>`, a POSIX shell
  script like the other lifecycle helpers. It prints one line,
  `<agent> <model> <effort>`, for example `gimli-implement opus high`.
- **The workers** are seven agent definitions in `.claude/agents/`, one per
  kind, each with a default `model` and `effort` and a short body saying
  what it is given, what it may change, and that it never commits.

`/build` stays the orchestrator. For each task it takes from `tasks.md`, it
runs `route.sh`, builds the context packet, and calls the Agent tool with the
agent, the model and the effort. The agent edits
the files its task owns and reports back. Build compares the changed files
with the task's Owns list, sets the status and commits, as it does today.

The context packet is the progressive-disclosure rule of
[ADR 0001](../../adr/0001-progressive-disclosure.md) applied to agents: the
task's own section of `tasks.md`, its Owns list, the Decisions of
`design.md`, the delta or spec sections for the scenarios it covers, and the
architecture principles. Anything else the agent reads only when it needs
it. The new page `docs/architecture/agents.md` describes the roster and the
packet.

## Decisions

1. **Agents named `gimli-<kind>`.** `gimli-design`, `gimli-spec`,
   `gimli-implement`, `gimli-test-unit`, `gimli-test-e2e`, `gimli-docs`,
   `gimli-review`. The kind is the name, so there is no second mapping to
   keep, and the prefix keeps them apart from built-in and plugin agents
   when Gimli is installed elsewhere (Track B).
2. **Complexity is data, not more agents.** One agent per kind; the routing
   table chooses the model per call through the Agent tool's model
   override. Recorded in ADR 0004.
3. **Model and effort per cell.** Each cell of the table gives a model and
   an effort, chosen independently, so Sonnet on high effort is possible
   where it may beat Opus on low. `route.sh` prints one line of three words,
   `<agent> <model> <effort>`, and Build always passes both. Haiku cells
   name `low`: Haiku 5.5 supports effort, but the `haiku` alias resolves to
   Haiku 4.5, which has none, on Bedrock and Vertex AI. The starting table follows an outside review
   of the first draft: design at medium complexity uses Sonnet on high
   effort. Documentation is Gimli's specification, so `docs` is split by
   what the writing needs: Haiku only for mechanical updates the task
   states exactly, Sonnet for deciding and synchronising what to write, and
   Opus for decisions, trade-offs and conflicting documents. The spec
   defines the three `docs` levels so Plan rates them the same way each
   time.
4. **One table, checked twice.** The spec states the table; `route.sh` holds
   its own copy as a `case` statement, so it needs nothing but POSIX shell;
   the test reads the table from the spec and checks `route.sh` against all
   21 cells. Drift between the two fails the test.
5. **The first automated test.** `scripts/tests/route_test.sh`, POSIX shell,
   run as `sh scripts/tests/route_test.sh`, exits non-zero on any failure and
   prints one line per check. It calls no network and no `gh`. Running it in
   CI is later work.
6. **Agents edit, Build commits.** An agent never commits, pushes, changes a
   label or posts a comment; Build undoes an agent's commit before checking.
   A change outside the task's Owns list is reverted and the task returned
   to the agent once; a repeat is reverted or kept, and recorded as a
   deviation either way. Build never commits it silently. Changed in Review
   from "return once or keep", so the retry can succeed. Recorded in
   ADR 0004.
7. **Agent defaults.** Frontmatter `model` and `effort` are the
   medium-complexity cell of the table, so an agent run without routing
   behaves like a medium task.
8. **No change folder, no routing.** A comment plan has no Kind or
   Complexity to route on; Build does that work itself, as today.
9. **Complexity picks the model, risk picks the assurance.** A risky but
   simple task does not get a bigger model; the issue's risk tier decides
   its review and human approval, as `docs/risk-assessment.md` already does,
   and step 6 adds specialised reviewers. Recorded in ADR 0004.
10. **Deterministic before a model.** An agent never does what a script or
    tool does reliably: running tests, formatting, checking links, changing
    labels. It interprets results and fixes problems. Recorded in ADR 0004
    and on the agents page.
11. **A routing record from the start.** Each commit Build makes for a
    routed task has a line `Routed: <agent> <model> <effort>`. It costs
    nothing now and is the first data for measuring routing later (Track C,
    Track D).
12. **Not in this change.** From the same review, and placed on the
    roadmap in #46: escalating to a stronger model after observable failure
    (with step 5), new task kinds such as `test-design` (step 4) and
    `security-review` (step 6), an uncertainty dimension and cross-model
    review (step 6), and routing telemetry beyond the `Routed:` line
    (Track D).

## Where it lands

This section is the plan's Documentation entry.

- `docs/specs/task-routing/spec.md` (new): the `ROUTE` capability spec,
  from the delta; a row in the index of `docs/specs/README.md`.
- `docs/adr/0004-task-routing.md` (new): decisions 2, 6, 9 and 10; a row in the
  index of `docs/adr/README.md`.
- `docs/architecture/agents.md` (new): the roster and the context packet;
  an Agents row in the parts table of `docs/architecture/README.md`, and a
  principle "Agents change only their task's files; Build commits",
  linking ROUTE-3.
- `.claude/agents/gimli-*.md` (new, seven files): one row each in the
  documentation map in `README.md`, as "Where a new document goes" requires
  for a file outside `docs/`, and `.claude/agents/` in its layout tree.
- `scripts/route.sh` (new) and `scripts/tests/route_test.sh` (new): a
  `route.sh` section and a tests section in `scripts/README.md`.
- `.claude/skills/build/SKILL.md`: step 3 delegates each task of a change
  folder.
- `docs/lifecycle.md`: the Build activity names routing.
- `docs/changes/README.md`: the Kind and Complexity rows say they choose the
  agent, and adding a kind also changes the roster, `route.sh` and the spec.
- `CLAUDE.md`: `.claude/agents/` and `scripts/tests/` in Repository layout.

## Risks

- **An agent changes files it does not own.** Build's Owns check (decision
  6) catches it before the commit.
- **The spec table and `route.sh` drift.** The test reads the spec
  (decision 4).
- **Delegation loses context the main session had.** The packet is defined
  in one place, and the fixture run for AC5 shows what each agent got.
- **The starting table is a guess.** It is a default policy, not a
  measurement; the `Routed:` lines let later work compare it with results.
- **Bootstrap.** This change is built without routing; AC5 is proven on a
  test fixture issue, as #52 was.

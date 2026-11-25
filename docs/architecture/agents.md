# Agents

Part of the [architecture](README.md).

The agents in [`.claude/agents/`](../../.claude/agents/) do the tasks of a
[change folder](../changes/README.md) for `/build`. Which agent, model and
effort a task gets is the [task routing spec](../specs/task-routing/spec.md);
why it works this way is [ADR 0004](../adr/0004-task-routing.md). This page
says what the agents are and what each one is given.

## Roster

One agent per task kind. Its frontmatter `model` and `effort` are the
medium-complexity cell of the routing table, so an agent run without routing
behaves like a medium task; `/build` passes the cell's model and effort on
every call.

| Agent | Kind | Default | Tools | Changes files |
|---|---|---|---|---|
| [`gimli-design`](../../.claude/agents/gimli-design.md) | `design` | sonnet, high | Read, Grep, Glob, Edit, Write | Yes |
| [`gimli-spec`](../../.claude/agents/gimli-spec.md) | `spec` | sonnet, high | Read, Grep, Glob, Edit, Write | Yes |
| [`gimli-implement`](../../.claude/agents/gimli-implement.md) | `implement` | sonnet, medium | Read, Grep, Glob, Edit, Write, Bash | Yes |
| [`gimli-test-unit`](../../.claude/agents/gimli-test-unit.md) | `test-unit` | sonnet, low | Read, Grep, Glob, Edit, Write, Bash | Yes |
| [`gimli-test-e2e`](../../.claude/agents/gimli-test-e2e.md) | `test-e2e` | sonnet, medium | Read, Grep, Glob, Edit, Write, Bash | Yes |
| [`gimli-docs`](../../.claude/agents/gimli-docs.md) | `docs` | sonnet, medium | Read, Grep, Glob, Edit, Write | Yes |
| [`gimli-review`](../../.claude/agents/gimli-review.md) | `review` | opus, medium | Read, Grep, Glob, Bash | No |

Agents that write code or tests get Bash to run their checks; agents that
write documents do not need it; the review agent reads and runs checks but
changes nothing.

## Context packet

An agent starts with only what its task needs, the rule of
[ADR 0001](../adr/0001-progressive-disclosure.md) applied to agents. Less
context also lets a cheaper model do the task. `/build` gives each agent:

| Part | From |
|---|---|
| The task's own section | `tasks.md`: title, fields and description |
| The files it may change | the task's Owns list |
| The design decisions | the Decisions section of `design.md` |
| What it implements or tests | the spec or delta sections for the scenario IDs in the task's Covers field |
| What it is reviewed against | the Principles section of the [architecture overview](README.md#principles) |

Anything else, such as a file the task names or an existing pattern to
follow, the agent reads when it needs it.

## How Build uses an agent

1. `scripts/route.sh <kind> <complexity>` gives the agent, model and effort.
2. Build calls the agent with the context packet, that model and that effort,
   and waits: one task at a time until parallel Build (#46, Track A step 5).
3. The agent changes files and reports back. It never commits, pushes,
   changes a label or posts a comment.
4. Build compares the changed files with the task's Owns list. A change to a
   file outside it is reverted and the task returned to the agent once, with
   the list; if it happens again, Build reverts or keeps it and records a
   `## Build: deviation` either way. It is never committed silently.
   If the agent switched branch, committed or pushed, Build stops and
   reports it instead of repairing it. A task the agent cannot finish is fixed by Build as a
   deviation, with a `Fixed-by: build` line in its commit, or deferred with
   the agent's changes reverted.
5. Build sets the task's status and commits, with a line
   `Routed: <agent> <model> <effort>` in the message.

The Owns check is what will let parallel Build run tasks of different
streams side by side without conflicts.

## Deterministic before a model

An agent never does what a script or tool does reliably: running tests,
formatting, checking links, changing labels or merging. An agent with Bash
runs the tool, reads the result, and fixes what the result shows; one without
Bash names in its report the checks Build should run. Files a check
generates are removed again unless the task owns them.

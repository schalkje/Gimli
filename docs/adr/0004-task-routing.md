# 0004. Route tasks to agents by kind and complexity

Part of the [architecture decision records](README.md).

- **Status:** Accepted
- **Date:** 2026-11-25
- **Issue:** #58, from the roadmap in #46

## Context

Since [ADR 0003](0003-change-folders.md), a large change is a list of tasks in
a change folder, each with a Kind and a Complexity. Until now `/build` did
every task itself, on whatever model the session ran. The roadmap in #46
wants each task run by the model that fits it: strong reasoning where
mistakes are costly, cheap models for mechanical work, and only the context
the task needs ([ADR 0001](0001-progressive-disclosure.md)).

An outside review of the first plan for #58 also pointed out that the size
of a task, its risk and the right model are different questions, and that
much of the work needs no model at all.

## Decision

1. **One agent per task kind, with complexity as data.** Seven agents,
   `gimli-<kind>`, one per kind in [`docs/changes/README.md`](../changes/README.md#tasksmd).
   A routing table in the [task routing spec](../specs/task-routing/spec.md)
   gives each kind and complexity a model and an effort, chosen
   independently, and Build passes both when it calls the agent.
   `scripts/route.sh` is the lookup.
2. **Agents edit, Build commits.** An agent changes only the files its task
   owns and reports back. It never commits, pushes, changes a label or posts
   a comment. Build checks the changed files against the task's Owns list,
   sets the status and commits, so the commit, status and push rules stay in
   one skill.
3. **Complexity picks the model, risk picks the assurance.** A risky but
   simple task does not get a stronger model to implement it. The issue's
   risk tier decides its review and human approval, as
   [`risk-assessment.md`](../risk-assessment.md) already does.
4. **Deterministic before a model.** An agent never does what a script or
   tool does reliably, such as running tests, formatting, checking links or
   changing labels. It interprets the results and fixes the problems.

## Considered options

- **One agent per kind and model tier,** for example `gimli-implement-opus`.
  Every choice is visible in a file name, but the roster grows to 15 to 20
  files that repeat each other. Not chosen.
- **A few roles,** such as architect, builder, tester and writer, with kinds
  mapped onto them. Fewer files, but the mapping from kind to role is another
  table to keep in step. Not chosen.
- **Agents commit their own task.** Closer to one commit per worktree in
  parallel Build later, but every agent would need the commit conventions,
  and a change outside a task's files would reach a commit unchecked. Not
  chosen.
- **The strongest model for every high-risk task.** Simple, but it spends the
  most expensive model where a review does more, and it mixes two decisions
  the lifecycle already keeps apart. Not chosen.

## Consequences

- A kind added to `docs/changes/README.md` also needs an agent, a row in the
  routing table, a change to `route.sh`, and the kind list and cell count in
  the routing test; the test fails until all of them agree.
- The table is a starting policy, not a measurement. Each routed commit
  carries a `Routed: <agent> <model> <effort>` line, the first data for
  measuring it later (#46, Track D).
- Changes without a change folder are not routed; Build does them itself.
- Escalating to a stronger model on observable failure, new kinds such as
  `test-design` and `security-review`, and cross-model review are later
  roadmap steps (#46, Track A steps 4 to 6).

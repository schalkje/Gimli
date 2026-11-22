# 0001. Progressive disclosure

Part of the [architecture decision records](README.md).

- **Status:** Accepted
- **Date:** 2026-11-22
- **Issue:** #47, from the roadmap in #46

## Context

Gimli is becoming a specification-driven system (#46): it will hold
functional specs, architecture and decisions, and hand work to agents that
each run one kind of task on a model suited to it. That is a lot of
information. A person reading it, or an agent loading it into a limited
context window, needs only part of it for any one task. Loading everything
costs attention, tokens and money, and makes a cheaper model less likely to
cope.

The same applies to the process: a typo fix and a multi-stream feature should
not carry the same ceremony.

## Decision

Gimli applies **progressive disclosure** everywhere: show the short version
first, and make the detail available one step down for whoever needs it.

## Considered options

- **One comprehensive document per topic.** Everything about a topic in one
  place. Easy to find, but a reader or agent always loads all of it. Not
  chosen.
- **Progressive disclosure.** Short layers that link down to detail. A reader
  or agent stops at the layer they need. Chosen.

## Consequences

**Documentation.**
- Every document is short and links to the next layer down; the
  [documentation model](../documentation-model.md) defines the layers.
- A document does not repeat what a lower layer owns; it links to it.
- `README.md` is the top layer. Its documentation map lists the entry point
  of each layer and the documents people start from, not every document
  below them; the exact rule is
  [where a new document goes](../documentation-model.md#where-a-new-document-goes).

**Agents and skills.**
- An agent receives a context packet with its task, the relevant spec
  slice and the decisions and principles that apply, not the whole
  repository. Defining the packet is part of the agent roster in #46.
- A skill keeps its `SKILL.md` short and loads references only when the step
  that needs them runs.
- Smaller context lets a cheaper model handle more tasks, which supports
  choosing the right model for each task.

**Process.**
- The amount of process grows with the change: a small change keeps the
  light flow of [`lifecycle.md`](../lifecycle.md); only a large change gets
  the heavier structure planned in #46.

**Harder.** Information is spread over more, smaller files, so links must be
kept correct, and a reader looking for everything has to follow them.

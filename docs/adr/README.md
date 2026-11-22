# Architecture decision records

Part of the [Gimli documentation](../../README.md#documentation), in the
decision layer of the [documentation model](../documentation-model.md).

An architecture decision record (ADR) records one decision that shapes Gimli:
the context, the decision, the options that were considered, and the
consequences. ADRs say *why* Gimli is the way it is; the
[specs](../specs/README.md) and the [architecture](../architecture/README.md)
say *what* it is now.

## When to write an ADR

Write an ADR when a change makes a decision that does at least one of these:

- constrains how later changes are made;
- chooses between real alternatives, so the reason is worth keeping;
- would be costly to reverse.

The decision is made during the Plan stage of [`lifecycle.md`](../lifecycle.md):
the plan names the new ADR in its Documentation entry, and Build writes it with
status `Accepted`. Merging the pull request is the acceptance: an ADR on `main`
with status `Accepted` applies, and one in a pull request that never merges
never reaches `main`. A routine change that follows an existing decision needs
no ADR.

Only when the owner wants the options on record before deciding does a plan
name an ADR with status `Proposed`. A later pull request then changes it to
`Accepted` or `Rejected`.

## Format

ADRs use a lightweight form of [MADR](https://adr.github.io/madr/): Status,
Date, Issue, Context, Decision, Considered options, Consequences. Start from
[`template.md`](template.md).

## Numbering

Each ADR is a file `NNNN-<slug>.md`: a four-digit number and a few lowercase
words joined with hyphens. Build takes the next number not yet used on `main`
when it writes the file. If another pull request merges an ADR with the same
number first, the later pull request renumbers its ADR, and the links to it,
before it merges. A number on `main` is never reused, not even for an ADR that
is superseded or deprecated.

## Status

| Status | Meaning |
|---|---|
| `Proposed` | On `main` for discussion, without a decision yet. |
| `Accepted` | The decision applies. An ADR is written with this status in the pull request that makes the decision. |
| `Rejected` | A proposal that was decided against; it never applied. |
| `Superseded by NNNN` | Applied, then replaced by a later ADR, which links back to this one. |
| `Deprecated` | Applied, but no longer does, and nothing replaces it. |

A `Proposed` ADR may be edited until it is decided, and the pull request that
accepts or rejects it may change its content along with its status. An
accepted ADR is not rewritten once it is on `main`. A changed decision is a
new ADR that supersedes the old one; the only edit to the old ADR is its
status line.

## Index

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-progressive-disclosure.md) | Progressive disclosure | Accepted |
| [0002](0002-documentation-model.md) | Documentation model: specs, architecture and ADRs under `docs/` | Accepted |

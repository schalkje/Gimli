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
the plan names the new ADR in its Documentation entry, Build writes it, and it
is accepted when its pull request merges. A routine change that follows an
existing decision needs no ADR.

## Format

ADRs use a lightweight form of [MADR](https://adr.github.io/madr/): Status,
Date, Issue, Context, Decision, Considered options, Consequences. Start from
[`template.md`](template.md).

## Numbering

Each ADR is a file `NNNN-<slug>.md`: a four-digit number in order of
acceptance and a few lowercase words joined with hyphens. A number is never
reused, not even for an ADR that is superseded or deprecated.

## Status

| Status | Meaning |
|---|---|
| `Proposed` | Written in a pull request that has not merged yet. |
| `Accepted` | Merged; the decision applies. |
| `Superseded by NNNN` | Replaced by a later ADR, which links back to this one. |
| `Deprecated` | No longer applies, and nothing replaces it. |

An accepted ADR is not rewritten. A changed decision is a new ADR that
supersedes the old one; the only edit to the old ADR is its status line.

## Index

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-progressive-disclosure.md) | Progressive disclosure | Accepted |
| [0002](0002-documentation-model.md) | Documentation model: specs, architecture and ADRs under `docs/` | Accepted |

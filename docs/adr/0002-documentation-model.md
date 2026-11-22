# 0002. Documentation model: specs, architecture and ADRs under docs/

Part of the [architecture decision records](README.md).

- **Status:** Accepted
- **Date:** 2026-11-22
- **Issue:** #47, from the roadmap in #46

## Context

Gimli's documentation is its specification ([`lifecycle.md`](../lifecycle.md),
documentation rule), but it describes only the process. Nothing builds up
into a lasting description of what the product does, how it is built, or why
it was built that way. The roadmap in #46 needs that: later steps add spec
deltas per change, key tests to scenarios, and give agents slices of the
documentation. Those steps need one agreed place and format to build on.

[ADR 0001](0001-progressive-disclosure.md) requires the documentation to be
layered.

## Decision

Gimli's documentation has three layers, all under `docs/`, described in the
[documentation model](../documentation-model.md):

- **Specs**, in `docs/specs/<capability>/spec.md`: what Gimli does, as
  requirements with scenarios.
- **Architecture**, in `docs/architecture/`: how Gimli is built, and the
  principles changes are reviewed against.
- **Decisions**, in `docs/adr/`: why, one ADR per decision.

Requirements are SHALL statements, each with scenarios. Scenario IDs have the
form `<CAP>-<req>.<n>`, for example `STAGE-3.2`: a capability prefix, the
requirement number and the scenario number. A published ID is never reused;
a removed scenario's ID is retired. The format is defined in
[`docs/specs/README.md`](../specs/README.md).

## Considered options

- **All under `docs/`.** One documentation root, so the documentation rule
  and the README map stay simple. Chosen.
- **A top-level `specs/` folder,** with architecture and ADRs in `docs/`.
  Closer to OpenSpec, but two documentation roots. Not chosen.
- **OpenSpec's `openspec/` layout.** Keeps the option of running the
  OpenSpec tool directly, but splits the documentation and ties Gimli to
  another tool's layout before that is decided (#46, open question 1). Not
  chosen; the spec format stays compatible with OpenSpec's requirement and
  scenario style instead.
- **Slug-based scenario IDs,** such as `stage-transition/moves-label`.
  Self-explanatory, but long, and they break when a scenario is renamed. Not
  chosen.

## Consequences

- Stable scenario IDs can later be referenced from tests and from pull
  request evidence (#46, Track A step 4).
- Existing documents under `docs/` stay where they are; the
  [architecture overview](../architecture/README.md) places each in a layer.
  Converting `lifecycle.md` and `risk-assessment.md` into capability specs is
  later work.
- The documentation rule in `lifecycle.md` covers the new layers, so a
  change that alters what a spec, the architecture or an ADR index describes
  updates it in the same pull request.
- The Plan stage decides whether a change needs an ADR, using
  [`docs/adr/README.md`](README.md).

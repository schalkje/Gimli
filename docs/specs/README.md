# Specs

Part of the [Gimli documentation](../../README.md#documentation), in the
spec layer of the [documentation model](../documentation-model.md).

A capability spec says what one capability of Gimli does, as requirements
with scenarios. It is the lasting answer to "what should this do?": tests and
evidence can point at its scenarios, and the reasons behind it are in the
[ADRs](../adr/README.md). The format is decided in
[ADR 0002](../adr/0002-documentation-model.md).

## Format

Each capability has a folder with one file, `docs/specs/<capability>/spec.md`,
where `<capability>` is a few lowercase words joined with hyphens. Start by
copying [`_template/spec.md`](_template/spec.md) to the new folder; its links
are already right for that location.

- A header names the capability's **prefix**, the files that implement it,
  and the ADRs behind it.
- Each requirement is a heading `### Requirement <CAP>-<req>: <name>` and one
  statement using SHALL, written so that it can be tested.
- Each requirement has one or more scenarios, each a heading
  `#### Scenario <CAP>-<req>.<n>: <name>` and a list of **GIVEN** (optional),
  **WHEN**, **THEN** and **AND** lines describing observable behaviour.
- A spec ends with a **Retired scenario IDs** section.

This is the requirement-and-scenario style OpenSpec uses, so the format stays
compatible with it.

## Scenario IDs

A scenario ID has the form `<CAP>-<req>.<n>`, for example `STAGE-3.2`:

- `<CAP>` is the capability prefix: a short uppercase word, unique across all
  specs, chosen when the spec is created. Pick the word people use for the
  capability, for example `STAGE` for stage transitions.
- `<req>` is the requirement number within the spec, from 1.
- `<n>` is the scenario number within the requirement, from 1.

IDs are stable once a spec is on `main`, because tests and evidence will
refer to them:

- A changed scenario keeps its ID if it still describes the same behaviour.
- A removed scenario gives up its ID, and a removed requirement gives up its
  number and the IDs of all its scenarios. Each is listed under **Retired
  scenario IDs**, a requirement as `<CAP>-<req>`, and is never used again.
- New requirements and scenarios take the next number never used on `main`,
  retired numbers included.

## Index

| Capability | Prefix | What it covers |
|---|---|---|
| [Stage transitions](stage-transitions/spec.md) | `STAGE` | Reading and changing an issue's lifecycle stage with `scripts/stage.sh`. |

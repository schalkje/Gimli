# Documentation model

Part of the [Gimli documentation](../README.md#documentation).

Gimli's documentation is layered, so a reader or an agent can stop at the
layer they need ([ADR 0001](adr/0001-progressive-disclosure.md)). The layers
and their format are decided in [ADR 0002](adr/0002-documentation-model.md);
this page describes them as they are now.

## Layers

```text
README.md                          what Gimli is, and the map
├── docs/specs/                    what Gimli does
│   └── <capability>/spec.md       requirements and scenarios
├── docs/architecture/             how Gimli is built
│   └── README.md                  overview, principles, index
└── docs/adr/                      why Gimli is built this way
    └── NNNN-<slug>.md             one decision each
```

| Layer | Holds | Entry point | Format |
|---|---|---|---|
| Specs | Requirements as SHALL statements, each with scenarios that have stable IDs | [`specs/README.md`](specs/README.md) | [`specs/template.md`](specs/template.md) |
| Architecture | Gimli's parts, how they interact, and the principles changes are reviewed against | [`architecture/README.md`](architecture/README.md) | Free form, short: one overview, with a document per part added when the overview would grow too long |
| Decisions | One decision each: context, decision, options, consequences | [`adr/README.md`](adr/README.md) | [`adr/template.md`](adr/template.md) |

## How the layers link

- `README.md` links to this page and to the entry point of each layer, not to
  every document below it.
- Each entry point is an index: it explains its layer briefly and lists the
  documents in it.
- A document links down to detail and sideways to related documents in other
  layers: a spec to the ADR behind it, an ADR to the spec or architecture it
  shaped.
- A document does not repeat what another document owns; it links to it.

## Where a new document goes

| You are writing down | Put it in |
|---|---|
| What Gimli does, in a way that can be tested | a capability spec in `docs/specs/` |
| How a part of Gimli works, or a principle code is reviewed against | `docs/architecture/` |
| A decision and why it was made | a new ADR in `docs/adr/` |
| A process document that is not a capability spec yet, such as a new stage procedure | directly in `docs/`, placed in a layer in the [architecture overview](architecture/README.md#where-the-documents-in-docs-fit) and listed in the README map's Process group |

A new document is added to its layer's index; a document directly in `docs/`
is added to the placement table in the architecture overview instead. It goes in the
[documentation map](../README.md#documentation) only when it is the entry
point of a layer or a document people start from.

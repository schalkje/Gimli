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

Beside the layers, [change folders](changes/README.md) in `docs/changes/`
record how each large change was planned; their spec deltas change the spec
layer.

| Layer | Holds | Entry point | Format |
|---|---|---|---|
| Specs | Requirements as SHALL statements, each with scenarios that have stable IDs | [`specs/README.md`](specs/README.md) | [`specs/_template/spec.md`](specs/_template/spec.md) |
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

This section is the rule. `lifecycle.md`, `CLAUDE.md` and the Plan and Build
skills link here instead of restating it.

| You are writing down | Put it in | List it in | README map |
|---|---|---|---|
| What Gimli does, in a way that can be tested | `docs/specs/<capability>/spec.md` | the index in [`specs/README.md`](specs/README.md#index) | No |
| How a part of Gimli works, or a principle code is reviewed against | `docs/architecture/` | the [architecture overview](architecture/README.md) | No |
| A decision and why it was made | `docs/adr/NNNN-<slug>.md` | the index in [`adr/README.md`](adr/README.md#index) | No |
| The plan of one large change: design, tasks, spec deltas | `docs/changes/<issue>-<slug>/` | the index in [`changes/README.md`](changes/README.md#index) | No |
| A process document that is not a capability spec yet, such as a new stage procedure | directly in `docs/` | the [placement table](architecture/README.md#where-the-documents-in-docs-fit) in the architecture overview | Yes, in the group it belongs to |
| A document outside `docs/` that describes a file beside it, such as a skill, a template or a folder's README | next to what it describes | nothing else | Yes, in the group it belongs to |
| The entry point of a new layer, or of a folder of documents such as `docs/changes/` | its folder | this page | Yes |

The README map lists only the last three kinds; everything else is reached
through the index it is listed in.

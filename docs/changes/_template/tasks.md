# Tasks: <title>

Part of the [change folder for #<issue>](design.md).

Build takes the next `todo` task whose dependencies are all `done`, and sets
its status in the commit that completes it. The format is in
[`docs/changes/README.md`](../README.md#tasksmd).

| Stream | Tasks | Concern |
|---|---|---|
| A | T1 | <what this stream covers> |

### T1: <title>

- **Stream:** A
- **Depends on:** none
- **Kind:** <design | spec | test-design | implement | test-unit | test-e2e | docs | review>
- **Complexity:** <low | medium | high>
- **Owns:** <files, or none>
- **Covers:** <scenario IDs, or none>
- **Status:** todo

<What the task does, in a few sentences.>

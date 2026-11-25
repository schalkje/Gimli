# Tasks: let route.sh print the routing table

Part of the [change folder for #60](design.md).

Build takes the next `todo` task whose dependencies are all `done`, and sets
its status in the commit that completes it. The format is in
[`docs/changes/README.md`](../README.md#tasksmd).

| Stream | Tasks | Concern |
|---|---|---|
| A | T1 | The spec |
| B | T2, T3 | The script and its test |
| C | T4 | The script documentation |
| D | T5 | Review |

T1 is the contract: streams B and C depend on the scenario it writes.

### T1: Apply the task routing delta

- **Stream:** A
- **Depends on:** none
- **Kind:** spec
- **Complexity:** low
- **Owns:** `docs/specs/task-routing/spec.md`
- **Covers:** ROUTE-2.3, ROUTE-5.1
- **Status:** done

Apply [the delta](specs/task-routing/delta.md) to the living spec: add
ROUTE-5 after ROUTE-4, and replace ROUTE-2.3 with its new text.

### T2: Add --table to route.sh

- **Stream:** B
- **Depends on:** T1
- **Kind:** implement
- **Complexity:** low
- **Owns:** `scripts/route.sh`
- **Covers:** ROUTE-2.3, ROUTE-5.1
- **Status:** done

Accept `--table` as the only argument; loop over the kinds and levels in
table order and print `<kind> <complexity>` followed by the single-cell
lookup's output. Update the usage header. Every other argument rule stays.

### T3: Test --table against the spec

- **Stream:** B
- **Depends on:** T2
- **Kind:** test-unit
- **Complexity:** low
- **Owns:** `scripts/tests/route_test.sh`
- **Covers:** ROUTE-2.3, ROUTE-5.1
- **Status:** done

Add a ROUTE-5.1 check: `route.sh --table` prints 21 lines, each matching the
spec's cell for its kind and complexity, in the table's order. Keep the
ROUTE-2.3 checks passing.

### T4: Document --table

- **Stream:** C
- **Depends on:** T2
- **Kind:** docs
- **Complexity:** low
- **Owns:** `scripts/README.md`
- **Covers:** none
- **Status:** done

In the `route.sh` section, add `scripts/route.sh --table` to the example
block with a comment `# all 21 cells, one per line`, and say in one sentence
that it prints every cell as `<kind> <complexity> <agent> <model> <effort>`.

### T5: Review the change

- **Stream:** D
- **Depends on:** T1, T2, T3, T4
- **Kind:** review
- **Complexity:** medium
- **Owns:** none
- **Covers:** ROUTE-2.3, ROUTE-5.1
- **Status:** done

Run `sh scripts/tests/route_test.sh` and check that the links in the
changed files resolve. Check that the spec, `route.sh` and `scripts/README.md`
agree on `--table`, and report any finding with file and line.

# Tasks: reading the stage of a closed issue

Part of the [change folder for #54](design.md).

Build takes the next `todo` task whose dependencies are all `done`, and sets
its status in the commit that completes it. The format is in
[`docs/changes/README.md`](../README.md#tasksmd).

| Stream | Tasks | Concern |
|---|---|---|
| A | T1 | The spec |
| B | T2 | The script documentation |
| C | T3 | Checks |

### T1: Apply the stage transitions delta

- **Stream:** A
- **Depends on:** none
- **Kind:** spec
- **Complexity:** low
- **Owns:** `docs/specs/stage-transitions/spec.md`
- **Covers:** STAGE-1.3
- **Status:** done

Apply [the delta](specs/stage-transitions/delta.md) to the living spec:
STAGE-1.3 after STAGE-1.2. Check each line against the `gh issue view` call
and the no-target branch of `scripts/stage.sh`.

### T2: Note closed issues in the stage.sh section

- **Stream:** B
- **Depends on:** none
- **Kind:** docs
- **Complexity:** low
- **Owns:** `scripts/README.md`
- **Covers:** STAGE-1.3
- **Status:** done

In "Behaviour worth knowing", add that reading the stage works the same on a
closed issue.

### T3: Check links

- **Stream:** C
- **Depends on:** T1, T2
- **Kind:** review
- **Complexity:** low
- **Owns:** none
- **Covers:** none
- **Status:** todo

Run the link check from `README.md` and confirm the spec and folder links
resolve.

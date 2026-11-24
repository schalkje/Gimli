# Tasks: change folder and tasks format

Part of the [change folder for #52](design.md).

Build takes the next `todo` task whose dependencies are all `done`, and sets
its status in the commit that completes it. Streams group tasks that could
run in parallel; until Track A step 5, Build runs them one at a time. The
format is in [`docs/changes/README.md`](../README.md#tasksmd).

| Stream | Tasks | Concern |
|---|---|---|
| A | T1, T2 | The format and its decision |
| B | T3, T4, T5 | Process documents |
| C | T6, T7 | The `parent` target |
| D | T8, T9 | The Plan and Build skills |
| E | T10 | Checks |

T1 is the contract: every other stream depends on the format it defines.

### T1: Define the change folder, tasks and delta formats

- **Stream:** A
- **Depends on:** none
- **Kind:** docs
- **Complexity:** medium
- **Owns:** `docs/changes/README.md`, `docs/changes/_template/design.md`, `docs/changes/_template/tasks.md`, `docs/changes/_template/specs/capability/delta.md`
- **Covers:** none
- **Status:** done

`docs/changes/README.md`: location and name, files, the criteria for a
folder, who writes it at which stage, life after merge, the `tasks.md` fields
with the fixed kinds and complexity levels and the no-cycle rule, the delta
format with its stable-ID rule, and an index of change folders. Templates sit
at the same depth as a real folder, so their links are right when copied.

### T2: Record ADR 0003

- **Stream:** A
- **Depends on:** T1
- **Kind:** docs
- **Complexity:** low
- **Owns:** `docs/adr/0003-change-folders.md`, `docs/adr/README.md`
- **Covers:** none
- **Status:** done

Decisions 1, 2, 7 and 8 of the design; index row in `docs/adr/README.md`.

### T3: Update the lifecycle

- **Stream:** B
- **Depends on:** T1
- **Kind:** docs
- **Complexity:** medium
- **Owns:** `docs/lifecycle.md`
- **Covers:** none
- **Status:** done

A "Parent issues" section; the Plan stage's activity, artifact and exit for a
change with a folder; the Build stage's entry and artifact when Plan opened
the pull request; one pull request per large change.

### T4: Update CLAUDE.md and the README

- **Stream:** B
- **Depends on:** T3
- **Kind:** docs
- **Complexity:** low
- **Owns:** `CLAUDE.md`, `README.md`
- **Covers:** none
- **Status:** done

`CLAUDE.md`: where plans go, who opens the draft pull request, the splitting
rule in Working style, `docs/changes/` in Repository layout. `README.md`: the
documentation map and the layout tree.

### T5: Place change folders in the documentation model

- **Stream:** B
- **Depends on:** T1
- **Kind:** docs
- **Complexity:** low
- **Owns:** `docs/documentation-model.md`, `docs/architecture/README.md`, `docs/specs/README.md`
- **Covers:** none
- **Status:** done

A row for change folders in "Where a new document goes"; change folders in
the architecture overview's parts; `docs/specs/README.md` links to the delta
format.

### T6: Apply the stage transitions delta

- **Stream:** C
- **Depends on:** none
- **Kind:** spec
- **Complexity:** low
- **Owns:** `docs/specs/stage-transitions/spec.md`
- **Covers:** STAGE-9.1, STAGE-9.2, STAGE-9.3
- **Status:** done

Apply [the delta](specs/stage-transitions/delta.md) to the living spec.

### T7: Add the parent target to stage.sh

- **Stream:** C
- **Depends on:** T6
- **Kind:** implement
- **Complexity:** low
- **Owns:** `scripts/stage.sh`, `scripts/README.md`
- **Covers:** STAGE-9.1, STAGE-9.2, STAGE-9.3
- **Status:** done

Accept `parent` as a target next to `close`; update the usage header and the
`stage.sh` section of `scripts/README.md`.

### T8: Teach /plan to write a change folder

- **Stream:** D
- **Depends on:** T1, T3
- **Kind:** implement
- **Complexity:** high
- **Owns:** `.claude/skills/plan/SKILL.md`
- **Covers:** none
- **Status:** done

Decide the folder by the criteria; for a folder, write it from the templates,
and after confirmation create the branch, commit, push, open the draft pull
request, and post a `## Plan` comment with the folder link, the Tests table
and the risk assessment. Comment-only plans stay as today. A non-interactive
run never creates a branch.

### T9: Teach /build to follow tasks.md

- **Stream:** D
- **Depends on:** T1, T3
- **Kind:** implement
- **Complexity:** high
- **Owns:** `.claude/skills/build/SKILL.md`
- **Covers:** none
- **Status:** done

Tell a first Build on Plan's pull request from a re-entry by the latest
`Stage: … → build` comment; follow `tasks.md` in dependency order, setting
each status in its commit; push only, without opening a second pull request.

### T10: Check links and the worked example

- **Stream:** E
- **Depends on:** T1, T2, T3, T4, T5, T6, T7, T8, T9
- **Kind:** review
- **Complexity:** low
- **Owns:** none
- **Covers:** none
- **Status:** done

Run the link check from `README.md`; check this folder against the templates
from T1.

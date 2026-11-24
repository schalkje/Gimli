# Delta: stage transitions

Part of the [change folder for #52](../../design.md). Changes the
[stage transitions spec](../../../../specs/stage-transitions/spec.md). The format
is in [`docs/changes/README.md`](../../../README.md#spec-deltas).

STAGE-2.3 keeps its ID: it still describes rejecting a target that is not
valid, and `parent` joins the valid targets. The spec's introduction also
names `parent` next to `close` as a valid target that is not a stage.

## ADDED

### Requirement STAGE-9: Mark a parent issue

Given the target `parent`, the system SHALL record the transition and remove
every stage label, without closing or reopening the issue.

#### Scenario STAGE-9.1: Issue with a stage becomes a parent

- **GIVEN** an open issue at `stage:refine`
- **WHEN** `scripts/stage.sh <issue> parent "Roadmap for Track A."` runs
- **THEN** a comment `Stage: refine → parent` with the note is posted
- **AND** the issue carries no `stage:*` label and stays open
- **AND** it prints `#<issue>: refine → parent`

#### Scenario STAGE-9.2: Issue without a stage label

- **GIVEN** an issue with no `stage:*` label
- **WHEN** `scripts/stage.sh <issue> parent` runs
- **THEN** it prints `#<issue>: no stage label`
- **AND** posts no comment and changes no label

#### Scenario STAGE-9.3: Closed issue stays closed

- **GIVEN** a closed issue that carries a stage label
- **WHEN** `scripts/stage.sh <issue> parent` runs
- **THEN** the comment is posted and the label removed
- **AND** the issue stays closed

## MODIFIED

### Requirement STAGE-2: Reject invalid arguments

Unchanged; one of its scenarios changes.

#### Scenario STAGE-2.3: Unknown stage

- **WHEN** the target is not one of the valid stages and not `close` or `parent`
- **THEN** it names the valid targets and exits with status 2
- **AND** posts no comment and changes no label

## REMOVED

None.

## Retired by this change

None.

# Delta: stage transitions

Part of the [change folder for #54](../../design.md). Changes the
[stage transitions spec](../../../../specs/stage-transitions/spec.md). The format
is in [`docs/changes/README.md`](../../../README.md#spec-deltas).

## ADDED

#### Scenario STAGE-1.3: Closed issue with a stage

Under requirement STAGE-1.

- **GIVEN** a closed issue that still carries `stage:merge`
- **WHEN** `scripts/stage.sh <issue>` runs
- **THEN** it prints `merge`
- **AND** posts no comment, changes no label, and the issue stays closed

## MODIFIED

None.

## REMOVED

None.

## Retired by this change

None.

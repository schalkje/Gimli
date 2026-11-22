# Stage transitions

Part of the [Gimli specs](../README.md).

- **Prefix:** `STAGE`
- **Implemented by:** [`scripts/stage.sh`](../../../scripts/stage.sh), with
  helpers from [`scripts/lib.sh`](../../../scripts/lib.sh). Usage is in
  [`scripts/README.md`](../../../scripts/README.md#stagesh).
- **Decisions:** none recorded; the stage model itself is defined in
  [`lifecycle.md`](../../lifecycle.md#stage-status).

Every issue moves through the lifecycle stages, recorded as one `stage:*`
label. Stage transitions read and change that label so that each change is
also recorded as a comment on the issue, which keeps the audit trail complete.

The valid stages are `refine`, `plan`, `build`, `test`, `evidence`,
`assess`, `review` and `merge`. `close` is a valid target, but not a stage.

## Requirements

### Requirement STAGE-1: Report the current stage

Given only an issue number, the system SHALL print the issue's current stage
and change nothing, unless STAGE-8 applies.

#### Scenario STAGE-1.1: Issue with a stage

- **GIVEN** an issue with the label `stage:plan`
- **WHEN** `scripts/stage.sh <issue>` runs
- **THEN** it prints `plan`
- **AND** posts no comment and changes no label

#### Scenario STAGE-1.2: Issue without a stage

- **GIVEN** an issue with no `stage:*` label
- **WHEN** `scripts/stage.sh <issue>` runs
- **THEN** it prints `none`

The output for an issue carrying several stage labels is not specified yet:
`stage.sh` prints all of them, for example `plan build`, which is not a stage.
It is part of #49.

### Requirement STAGE-2: Reject invalid arguments

The system SHALL exit with status 2 and change nothing when its arguments are
invalid.

#### Scenario STAGE-2.1: No arguments

- **WHEN** `scripts/stage.sh` runs without arguments
- **THEN** it prints its usage and exits with status 2

#### Scenario STAGE-2.2: Issue is not a number

- **WHEN** the first argument is not a plain number, for example `#5` or `abc`
- **THEN** it reports that the issue must be a number and exits with status 2

#### Scenario STAGE-2.3: Unknown stage

- **WHEN** the target is not one of the valid stages and not `close`
- **THEN** it names the valid targets and exits with status 2
- **AND** posts no comment and changes no label

### Requirement STAGE-3: Move to a stage

Given a valid stage, the system SHALL record the transition as a comment and
leave the issue with exactly that one stage label.

#### Scenario STAGE-3.1: Move without a note

- **GIVEN** an issue at `stage:refine`
- **WHEN** `scripts/stage.sh <issue> plan` runs
- **THEN** a comment `Stage: refine → plan` is posted
- **AND** the issue carries `stage:plan` and no other `stage:*` label
- **AND** it prints `#<issue>: refine → plan`

#### Scenario STAGE-3.2: Move with a note

- **WHEN** `scripts/stage.sh <issue> build Plan posted.` runs
- **THEN** the comment has `Stage: <old> → build` as its first line, then a
  blank line, then `Plan posted.`
- **AND** all words after the stage are joined into the note, quoted or not

#### Scenario STAGE-3.3: Issue without a stage

- **GIVEN** an issue with no `stage:*` label
- **WHEN** it is moved to `refine`
- **THEN** the comment reads `Stage: none → refine` and the issue carries
  `stage:refine`

#### Scenario STAGE-3.4: Issue with several stage labels

- **GIVEN** an issue carrying more than one valid `stage:*` label, none of
  which is the target
- **WHEN** it is moved to a stage
- **THEN** every old stage label is removed and only the target label remains

The case where one of several stage labels is the target is not specified
yet: `stage.sh` would remove and add the same label in one edit, and `gh`
then leaves no label at all, as the
[`risk.sh` section of `scripts/README.md`](../../../scripts/README.md#risksh)
explains. Fixing it is #49.

### Requirement STAGE-4: Comment before label

The system SHALL post the transition comment before it changes any label or
the issue's open or closed state, so that a failure part way always leaves the
transition documented.

#### Scenario STAGE-4.1: Label change fails on a move

- **GIVEN** an open issue
- **WHEN** it is moved to a stage, posting the comment succeeds, and the label
  change fails
- **THEN** the comment is on the issue and the old stage label is unchanged

#### Scenario STAGE-4.2: Later step fails on close or reopen

- **WHEN** a close or a reopen fails after the comment is posted
- **THEN** the comment is on the issue, but the issue may be partly changed:
  on `close`, the stage label is removed before the issue is closed; on a
  reopen, the issue is reopened before the labels change
- **AND** the script stops with a non-zero status, so the partial state is
  visible to whoever ran it

### Requirement STAGE-5: No-op at the same stage

The system SHALL change nothing when the issue is already at the target
stage.

#### Scenario STAGE-5.1: Already at the target stage

- **GIVEN** an issue at `stage:build`
- **WHEN** `scripts/stage.sh <issue> build` runs
- **THEN** it prints `#<issue>: already at build`
- **AND** posts no comment and changes no label

#### Scenario STAGE-5.2: Closed issue already at the target stage

- **GIVEN** a closed issue that still carries `stage:build`
- **WHEN** `scripts/stage.sh <issue> build` runs
- **THEN** it prints `#<issue>: already at build`
- **AND** posts no comment, and the issue stays closed

### Requirement STAGE-6: Close

Given the target `close`, the system SHALL record the transition, remove the
stage label, and leave the issue closed.

#### Scenario STAGE-6.1: Close an open issue

- **GIVEN** an open issue at `stage:merge`
- **WHEN** `scripts/stage.sh <issue> close "Merged in #6."` runs
- **THEN** a comment `Stage: merge → close` with the note is posted
- **AND** the `stage:merge` label is removed and the issue is closed

#### Scenario STAGE-6.2: Close an issue GitHub already closed

- **GIVEN** an issue closed by a closing keyword that still carries
  `stage:merge`
- **WHEN** `scripts/stage.sh <issue> close` runs
- **THEN** the comment is still posted and the label removed
- **AND** the issue stays closed

### Requirement STAGE-7: Reopen a closed issue

Moving a closed issue to a stage other than its current one SHALL reopen it.
At its current stage, STAGE-5.2 applies instead.

#### Scenario STAGE-7.1: Return a closed issue to Build

- **GIVEN** a closed issue that does not carry `stage:build`
- **WHEN** `scripts/stage.sh <issue> build "Regression found."` runs
- **THEN** the comment is posted, the issue is reopened, and it carries
  `stage:build`

### Requirement STAGE-8: Refuse a non-canonical stage label

The system SHALL abort with status 1, before posting anything, when the issue
carries a `stage:*` label that is not one of the valid stages.

#### Scenario STAGE-8.1: Unknown stage label on the issue

- **GIVEN** an issue carrying `stage:done`
- **WHEN** `scripts/stage.sh <issue>` runs with no target or with a valid
  target (an invalid target fails first, under STAGE-2.3)
- **THEN** it reports the non-canonical label, says to fix it by hand, and
  exits with status 1
- **AND** posts no comment and changes no label

## Retired scenario IDs

None.

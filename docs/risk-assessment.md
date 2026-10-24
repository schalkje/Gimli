# Risk assessment

Every change receives a risk tier. The tier decides how much human involvement
the change requires before merge. Risk is assessed twice: preliminarily during
Refine and Plan, and finally during Assess against the actual diff.

## Tiers

| Tier | Label | Meaning |
|---|---|---|
| Low | `risk:low` | Small, well-understood, easily reversed. Wrong outcome is cheap to detect and fix. |
| Medium | `risk:medium` | Moderate scope or some uncertainty. Wrong outcome is noticeable and fixable without lasting harm. |
| High | `risk:high` | Broad impact, hard to reverse, or touches something sensitive. Wrong outcome causes real damage or is costly to undo. |
| Critical | `risk:critical` | Failure would be severe or irreversible. Requires the most careful human scrutiny. |

## Dimensions

Assess each dimension, then take the highest resulting tier.

### Impact

What is affected if the change is wrong?

| Finding | Tier floor |
|---|---|
| Documentation, comments, formatting, internal tooling with no runtime effect | Low |
| Behaviour change in a single component with clear boundaries | Medium |
| Changes to shared interfaces, public APIs, data formats, or build and release pipeline | High |
| Security controls, authentication, authorisation, secrets handling, data deletion, or anything handling money or personal data | Critical |

### Reversibility

How hard is it to undo?

| Finding | Tier floor |
|---|---|
| Revert the commit and the problem is gone | Low |
| Revert plus some manual cleanup | Medium |
| Data migrations, external side effects, published artifacts, or anything consumers may already depend on | High |

### Uncertainty

How well is the change understood?

| Finding | Tier floor |
|---|---|
| Pattern already exists in the codebase; change follows it | Low |
| New pattern or dependency, but within familiar territory | Medium |
| Unfamiliar area, speculative approach, or acceptance criteria that were hard to pin down | High |

### Size

How large is the diff?

| Finding | Tier floor |
|---|---|
| Few files, small diff, one concern | Low |
| Several files or several concerns | Medium |
| Large diff touching many areas | High. Consider splitting the issue. |

### Test coverage

How well do tests prove the change?

| Finding | Tier adjustment |
|---|---|
| Every acceptance criterion has an automated test | May lower the final tier by one step, but never below the Impact floor |
| Some criteria rely on manual evidence only | No adjustment |
| Change is not covered by tests and cannot reasonably be | Raise by one step |

## Procedure

1. Score each dimension using the tables above.
2. Take the highest tier floor as the base.
3. Apply the test coverage adjustment.
4. Record the tier and a one or two sentence justification. During Plan this
   goes in the plan comment; during Assess it goes in the Risk assessment
   section of the pull request body.
5. Apply the `risk:<tier>` label.

## Escalation

- If the final tier at Assess is higher than the tier set at Plan, the
  Risk assessment section must explain what changed.
- Anyone, human or agent, may raise the tier at any time with a comment
  explaining why. Lowering a tier set by a human requires that human's
  agreement.
- When in doubt between two tiers, choose the higher.

## Review requirements by tier

See the Review stage in `lifecycle.md` for the review path each tier requires.

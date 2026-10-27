# Gimli

Gimli is an agentic software development system. This repository is both the
product and its first user: all work on Gimli follows the Gimli development
lifecycle described in `docs/lifecycle.md`.

## How work happens here

- Every change starts as a GitHub issue created from the work item template.
  Do not start implementation from an informal request; create or refine an
  issue first.
- Follow the stages in `docs/lifecycle.md` in order: Refine, Plan, Build, Test,
  Evidence, Assess, Review, Merge. Each stage has entry and exit criteria.
  Do not skip a stage or declare one complete without meeting its exit criteria.
- Assess risk using `docs/risk-assessment.md`. The risk tier decides whether a
  change needs human review or can proceed through AI review.
- Mark a pull request ready for review only when the Evidence stage is
  complete: marking it ready starts the AI review on GitHub
  (`.github/workflows/claude-code-review.yml`). It reviews a pull request
  once; if that review skipped, did not finish, or predates later commits,
  run `/code-review <pr>` on the final diff.
  `@claude` in a comment asks Claude for an explanation or a fix.
- Use the `gh` CLI for all GitHub interaction: reading and updating issues,
  commenting, creating pull requests, applying labels.
- Move issues between stages with `scripts/stage.sh <issue> <stage> [note]`,
  and set the risk tier with `scripts/risk.sh <issue> <tier> [note]`, never by
  editing `stage:*` or `risk:*` labels directly. See `scripts/README.md`.
- Record decisions and evidence in GitHub, not only in the conversation. Plans
  go on the issue as a comment; test evidence goes in the pull request body.

## Repository layout

- `README.md`: product vision and overview.
- `docs/lifecycle.md`: stage definitions, entry and exit criteria, artifacts.
- `docs/risk-assessment.md`: risk tiers and the criteria that assign them.
- `.github/ISSUE_TEMPLATE/`: the work item template that starts the cycle.
- `.github/PULL_REQUEST_TEMPLATE.md`: the pull request template that carries
  evidence and the final risk assessment.
- `.claude/skills/`: one skill per automated lifecycle stage, invoked as
  `/<stage> <issue>`. The table at the end of `docs/lifecycle.md` says which
  stages have one.

## Conventions

- Branch names: `<type>/<short-description>`, for example `feature/refine-skill`
  or `fix/issue-template-typo`. Reference the issue number in the pull request.
- Commit messages: imperative mood, one logical change per commit.
- Pull requests target `main` and use `.github/PULL_REQUEST_TEMPLATE.md`.
  Build opens the draft with only the Summary and linked issue filled; every
  section is filled by the Evidence and Assess stages, which the template
  implements.
- Documentation is the specification. When behaviour and `docs/` disagree,
  fix one of them in the same change.

## Working style

- Prefer small, well-scoped issues. If refinement reveals a large change, split
  it into multiple issues and link them.
- When a stage cannot be completed as specified, say so explicitly in the issue
  or pull request rather than silently adapting the process.

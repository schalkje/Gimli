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
- Assess risk using `docs/risk-assessment.md`. Every change gets an AI review;
  the risk tier decides what human review it needs on top of that.
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
- `main` accepts changes only through a squash-merged pull request: the
  ruleset `protect-main` enforces it, with no bypass for anyone. See
  `docs/repository-settings.md`. Everything else in Review, including human
  approval, is a process rule GitHub does not check.
- Merge a `risk:medium` or higher pull request only on the owner's explicit
  instruction in that session, and record it in a pull request comment first:
  `Human approval: <owner> instructed the merge on <date>.`
- Do not change, disable or delete the ruleset or the repository's merge
  settings unless the owner asks in that session. The admin credentials Claude
  runs with could; that is why this rule exists.
- Record decisions and evidence in GitHub, not only in the conversation. Plans
  go on the issue as a comment; test evidence goes in the pull request body.

## Repository layout

- `README.md`: product vision, overview, and the documentation map. A new
  document goes in its layer's index; only entry points and documents people
  start from go in the map (`docs/documentation-model.md`).
- `docs/documentation-model.md`: the documentation layers and how they link.
- `docs/specs/`: capability specs, requirements with scenarios whose IDs
  (`<CAP>-<req>.<n>`) are never reused; format in `docs/specs/README.md`.
- `docs/architecture/`: Gimli's parts and the principles changes are
  reviewed against.
- `docs/adr/`: architecture decision records; when to write one is in
  `docs/adr/README.md`.
- `docs/lifecycle.md`: stage definitions, entry and exit criteria, artifacts.
- `docs/risk-assessment.md`: risk tiers and the criteria that assign them.
- `docs/ai-review.md`: how the AI review workflow, the local `/code-review`
  fallback and `claude.yml` behave.
- `docs/workflow-dependencies.md`: what the workflows pin and load, and how to
  update a pin or re-vendor the plugin.
- `docs/repository-settings.md`: the `protect-main` ruleset and merge settings.
- `scripts/`: the stage, risk and guard helpers and the ruleset setup,
  documented in `scripts/README.md`.
- `.github/workflows/`: the AI review (`claude-code-review.yml`) and the
  mention workflow (`claude.yml`).
- `.github/ISSUE_TEMPLATE/`: the work item template that starts the cycle.
- `.github/PULL_REQUEST_TEMPLATE.md`: the pull request template that carries
  evidence and the final risk assessment.
- `.claude/skills/`: one skill per automated lifecycle stage, invoked as
  `/<stage> <issue>`. The table at the end of `docs/lifecycle.md` says which
  stages have one.
- `.claude-plugin/marketplace.json` and `vendor/claude-plugins/`: the
  `code-review` plugin the AI review workflow runs, vendored verbatim from
  upstream into `vendor/claude-plugins/code-review/`. Never edit that copy by
  hand; re-vendor it and update the provenance in
  `vendor/claude-plugins/README.md` as `docs/workflow-dependencies.md`
  describes.

## Conventions

- Branch names: `<type>/<short-description>`, for example `feature/refine-skill`
  or `fix/issue-template-typo`. Reference the issue number in the pull request.
- Commit messages: imperative mood, one logical change per commit.
- Pull requests target `main` and use `.github/PULL_REQUEST_TEMPLATE.md`.
  Build opens the draft with only the Summary and linked issue filled; every
  section is filled by the Evidence and Assess stages, which the template
  implements.
- Documentation is the specification. When behaviour and `docs/` disagree,
  fix one of them in the same change, following the documentation rule in
  `docs/lifecycle.md`.

## Working style

- Prefer small, well-scoped issues. If refinement reveals a large change, split
  it into multiple issues and link them.
- When a stage cannot be completed as specified, say so explicitly in the issue
  or pull request rather than silently adapting the process.

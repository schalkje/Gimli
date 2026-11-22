# AI review

Part of the [Gimli documentation](../README.md#documentation).

Every change gets an AI review in the Review stage of the lifecycle
(`lifecycle.md`, [8. Review](lifecycle.md#8-review)). That stage says when a
review counts and how its findings are resolved. This document describes the
tooling that produces the review: the GitHub workflows, the local fallback,
and how to ask Claude on a pull request. What the workflows load and how
their dependencies are pinned is in
[`workflow-dependencies.md`](workflow-dependencies.md).

## The review workflow

The AI review is `.github/workflows/claude-code-review.yml`. It runs the
`code-review` plugin on GitHub when a pull request is marked ready, skips
drafts, and posts its findings as inline comments, or one summary comment when
it finds none, as the Claude GitHub App. Later pushes start the workflow again,
but the plugin reviews a pull request only once: it skips any pull request that
already has a Claude comment, and may post nothing on one it judges trivial
(see below). The plugin is a copy vendored in
`vendor/claude-plugins/` and the workflow's actions are pinned to commit SHAs,
so an upstream change reaches the review only through a pull request here,
except what the pinned action downloads at run time.
What the review loads from `main` and from the pull request under review, and
the limits, are in `workflow-dependencies.md`, section "What the review
loads". The review is independent of the authoring session's context but not
of its model provider; a reviewer from another provider is tracked in #1.

## Behaviour worth knowing

- **Local review.** `/code-review <pr>` is also the fallback when Actions is
  unavailable. It does not skip reviewed pull requests; it prints its
  findings, or posts them with `--comment`. Do not delete the workflow's
  comments to force a re-run: they are the review threads Review resolves.
- **Trivial pull requests.** The plugin may finish without posting anything
  on a pull request it judges trivial. In the #28 verification, the
  ready-for-review run on a one-line HTML comment change ended after 2 turns
  with no comment
  ([run 40578896724](https://github.com/schalkje/Gimli/actions/runs/40578896724)).
  When the plugin reviews and finds nothing it posts a "No issues found"
  summary, so no Claude comment after the head commit means the review
  skipped: run `/code-review <pr>`.
- **Held runs after `claude.yml` commits.** A commit pushed by the
  `claude.yml` workflow starts a review run that GitHub holds as
  `action_required`, with actor `github-actions[bot]`, under the repository's
  `first_time_contributors` approval policy
  ([run 40579775116](https://github.com/schalkje/Gimli/actions/runs/40579775116);
  observed once, not tested beyond it). Do not approve it: such a pull
  request already has a Claude comment, the reply to the mention, so the
  plugin would skip it. Run `/code-review <pr>` instead.
- **Asking Claude.** A comment containing `@claude` from the owner, a member,
  or a collaborator starts `.github/workflows/claude.yml`; a mention from
  anyone else starts no job. The action then acts only for users with write
  access, so a read-only collaborator is refused. It answers questions and can
  commit a requested fix to the pull request's branch. Claude reads the whole
  thread, including text from people who cannot trigger it, so check whose
  text is in the thread before asking. By default the action
  pushes only to that branch and does not merge or approve. The ruleset on
  `main` stops its token from pushing there, but nothing stops it from pushing
  to the pull request's branch or merging: the Claude app's token can write
  code and workflows. Its commits are subject to the rule above.
- **Workflow changes.** The action only runs a workflow file identical to the
  copy on `main`, so a pull request that changes `claude-code-review.yml` is
  not reviewed by it; review such a pull request with `/code-review <pr>`.
  The workflow loads the plugin from `main`, so a pull request that changes
  the vendored plugin is reviewed by the previous copy; the new one takes
  effect after the merge.
- **Forks.** Pull requests from forks are skipped, because GitHub withholds
  the secret from them; review them with `/code-review <pr>`. For the same
  reason `claude.yml` fails on reviews and review comments of a fork pull
  request; ask in a plain pull request comment instead.
- **Mentions.** Any comment from the owner, a member, or a collaborator that
  contains the trigger word `@claude` starts `claude.yml`, including a
  `## AI review` comment. When writing about the workflow in a comment, refer to it as
  "the `claude.yml` workflow" rather than writing the mention.


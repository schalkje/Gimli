# 0003. Change folders, parent issues and one pull request per large change

Part of the [architecture decision records](README.md).

- **Status:** Accepted
- **Date:** 2026-11-24
- **Issue:** #52, from the roadmap in #46

## Context

Until now a plan was one `## Plan` comment, and a large change was split into
several issues, each with its own pull request. The roadmap in #46 wants a
large change delivered as one pull request, with its work split into tasks
that can later run as parallel streams on the right agent and model, and
with the spec changes it makes written down before the code. A plan comment
has no room for that, and splitting spreads one design over several pull
requests.

Roadmaps such as #46 also do not fit the rule that every issue carries
exactly one stage label: they are never refined, planned or built themselves.

## Decision

1. **A large change gets a change folder** in `docs/changes/<issue>-<slug>/`
   with its design, its tasks and its spec deltas. Plan decides by criteria:
   the change touches a capability spec, has more than one stream, or has
   more than about five steps. Below that, the `## Plan` comment stays the
   whole plan. The format is in [`docs/changes/README.md`](../changes/README.md).
2. **Plan writes the folder on the change branch.** In an interactive run,
   after confirmation, Plan creates the branch, commits the folder, opens the
   draft pull request and posts a `## Plan` comment that links to it, so the
   design can be reviewed before any code.
3. **One pull request per large change.** A large change is not split into
   issues; splitting is for work that is really several changes.
4. **Parent issues** hold work that is several changes. A parent carries no
   stage label, tracks its children as GitHub sub-issues, and is closed when
   every child is closed or dropped. `scripts/stage.sh <issue> parent`
   removes its stage label with a recorded transition.

## Considered options

- **Plan comment only, split large changes.** Today's rule. Simple, but the
  design of a large change ends up in several pull requests and nowhere
  lasting. Not chosen.
- **A change folder with a proposal file, as OpenSpec has.** The issue body
  already is the proposal; a copy would drift. Not chosen.
- **Build writes the folder from a long plan comment.** Keeps Plan off git,
  but the design would exist twice and could not be reviewed in the pull
  request before Build. Not chosen.
- **Parent issues stay at `stage:refine`.** Keeps the one-label rule
  literally, but the label would mean nothing. Not chosen.

## Consequences

- Plan gains a write it did not have: a branch, a push and a draft pull
  request, always behind the user's confirmation.
- Build follows `tasks.md` and finds Plan's pull request instead of opening
  one; it tells a first Build from a re-entry by whether Build has moved the
  issue to Test before.
- A return to Plan updates the folder on the existing branch and pull
  request, keeping the status of tasks already done.
- Large pull requests take a higher risk tier for their size; the design in
  the pull request, reviewed first, is what keeps them reviewable.
- Later steps of #46 build on the task fields: routing on kind and
  complexity, traceability on covered scenarios, parallel Build on streams,
  dependencies and owned files, and the archive on deltas.

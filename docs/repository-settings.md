# Repository settings

Part of the [Gimli documentation](../README.md#documentation).

Gimli's lifecycle (`lifecycle.md`) delivers every change as a pull request.
This document records the GitHub settings that enforce that on `main`, the
exact calls that apply them, and what they do not enforce.

Apply or re-apply them with:

```sh
scripts/protect-main.sh [<owner>/<repo>]
```

It defaults to the repository of the current directory, is safe to run again,
and prints the resulting settings and ruleset.

## What GitHub enforces

A repository ruleset named `protect-main`, active on the default branch, with
an empty bypass list:

| Rule | Effect |
|---|---|
| `pull_request` | A change reaches `main` only through a pull request. Zero approvals are required, because GitHub never counts the author's own approval and this repository has one maintainer. Only squash merge is allowed (`allowed_merge_methods`), which also keeps history linear. |
| `non_fast_forward` | No force push to `main`. |
| `deletion` | `main` cannot be deleted. |

The bypass list is empty, so no actor is exempt: not the owner, not
administrators, not the Claude GitHub App. `gh pr merge --admin` cannot skip
the rules either.

The repository's merge settings match the ruleset:

| Setting | Value |
|---|---|
| `allow_squash_merge` | `true` |
| `allow_merge_commit` | `false` |
| `allow_rebase_merge` | `false` |
| `delete_branch_on_merge` | `true` |

`allowed_merge_methods` repeats squash-only inside the ruleset, so it still
holds if someone re-enables another merge method in the settings.
`delete_branch_on_merge` makes `gh pr merge --delete-branch` redundant, though
it still works.

## What remains a process rule

The ruleset does not require status checks, resolved conversations, or
approvals. Those Review exit criteria in `lifecycle.md`, and the definition of
human approval there, are rules the people and agents following the lifecycle
keep; GitHub does not check them.

**The limit.** Anyone with admin rights can change, disable, or delete the
ruleset and the merge settings. Claude Code runs with the owner's credentials,
which are admin credentials, so it could too. By the rule in `CLAUDE.md`,
Claude does not change them unless the owner asks in that session. That is a
process rule; nothing on GitHub enforces it. Making approvals binding would
need Claude to act under a separate, non-admin identity.

## The calls

`scripts/protect-main.sh` makes these calls, with `<r>` the `<owner>/<repo>`.

Merge settings:

```sh
gh api -X PATCH repos/<r> \
  -F allow_squash_merge=true \
  -F allow_merge_commit=false \
  -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true
```

Find the ruleset by name, among rulesets defined on the repository itself:

```sh
gh api --paginate "repos/<r>/rulesets?includes_parents=false" \
  --jq '.[] | select(.name == "protect-main") | .id'
```

No id: create it with `gh api -X POST repos/<r>/rulesets --input -`. One id:
replace it with `gh api -X PUT repos/<r>/rulesets/<id> --input -`. More than
one: the script stops and changes nothing further, so a duplicate is never
updated by mistake. Both requests send the same body:

```json
{
  "name": "protect-main",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["~DEFAULT_BRANCH"], "exclude": [] }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ["squash"]
      }
    }
  ],
  "bypass_actors": []
}
```

`~DEFAULT_BRANCH` rather than `refs/heads/main` lets the same call work in a
repository whose default branch has another name.

Because the lookup is by name and the update is a `PUT`, a second run leaves
exactly one ruleset with the same id and the same settings.

## Checking the result

```sh
gh api repos/<r> \
  --jq '{allow_squash_merge, allow_merge_commit, allow_rebase_merge, delete_branch_on_merge}'
gh api repos/<r>/rulesets/<id> --jq '{enforcement, conditions, rules, bypass_actors}'
gh api "repos/<r>/rulesets?includes_parents=false" --jq length
```

## Recovery

If the ruleset blocks work it should not, the owner edits or disables it in
the web UI (Settings, Rules, Rulesets, `protect-main`), or deletes it:

```sh
gh api -X DELETE repos/<r>/rulesets/<id>
```

Restore other merge settings with the same `PATCH` call and different values.
Re-running `scripts/protect-main.sh` puts everything back as recorded here.

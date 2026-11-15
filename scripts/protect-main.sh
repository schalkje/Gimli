#!/usr/bin/env sh
# Protect the default branch: changes arrive only through a squash-merged pull
# request, with no force push, no deletion, and no bypass for anyone.
#
#   protect-main.sh [<owner>/<repo>]   apply the settings and ruleset, print both
#
# Defaults to the repository of the current directory. Idempotent: a second
# run updates the ruleset named protect-main in place. Fails if more than one
# ruleset in the repository carries that name.
# See docs/repository-settings.md.

set -eu

. "$(dirname "$0")/lib.sh"

NAME=protect-main

[ $# -le 1 ] || usage
case "${1:-}" in
  -h|--help) usage ;;
esac

REPO=${1:-}
if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
fi
case "$REPO" in
  */*/*|/*|*/|*[!A-Za-z0-9._/-]*) echo "$PROG: expected <owner>/<repo>, got '$REPO'" >&2; exit 2 ;;
  */*) ;;
  *) echo "$PROG: expected <owner>/<repo>, got '$REPO'" >&2; exit 2 ;;
esac

# Merge settings: squash only, head branch deleted on merge.
gh api -X PATCH "repos/$REPO" \
  -F allow_squash_merge=true \
  -F allow_merge_commit=false \
  -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true >/dev/null

# Rulesets defined on this repository (not inherited) with this name.
IDS=$(gh api --paginate "repos/$REPO/rulesets?includes_parents=false" \
  --jq ".[] | select(.name == \"$NAME\") | .id")
COUNT=$(printf '%s\n' "$IDS" | grep -c . || true)

if [ "$COUNT" -gt 1 ]; then
  echo "$PROG: $COUNT rulesets named $NAME in $REPO; delete the extras by hand first. Ids:" $IDS >&2
  exit 1
fi

if [ "$COUNT" -eq 1 ]; then
  METHOD=PUT
  ENDPOINT="repos/$REPO/rulesets/$IDS"
else
  METHOD=POST
  ENDPOINT="repos/$REPO/rulesets"
fi

ID=$(gh api -X "$METHOD" "$ENDPOINT" --input - --jq .id <<EOF
{
  "name": "$NAME",
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
EOF
)

if [ "$METHOD" = POST ]; then
  echo "Created ruleset $NAME (id $ID) on $REPO."
else
  echo "Updated ruleset $NAME (id $ID) on $REPO."
fi

# Print the result, so that a run is its own evidence.
echo "Merge settings:"
gh api "repos/$REPO" \
  --jq '{allow_squash_merge, allow_merge_commit, allow_rebase_merge, delete_branch_on_merge}'
echo "Ruleset:"
gh api "repos/$REPO/rulesets/$ID" \
  --jq '{id, name, enforcement, conditions, rules, bypass_actors}'

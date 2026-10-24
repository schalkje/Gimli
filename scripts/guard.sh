#!/usr/bin/env sh
# Decide whether a non-interactive skill run may post a comment under a heading.
#
#   guard.sh <issue> <heading>   print one "post: ..." or "skip: ..." reason line
#
# Exit 0: post. Exit 1: do not post. Exit 2: usage error. Exit 3: gh failed.
# Works on issues and pull requests.
# See scripts/README.md and .claude/skills/_shared/preamble.md, section 4.

# No set -e: every exit here is explicit, so a stray failure can never
# surface as exit 1 and be read as "skip".
set -u

LIB="$(dirname "$0")/lib.sh"
[ -r "$LIB" ] || { echo "guard.sh: lib.sh not found next to the script" >&2; exit 3; }
. "$LIB"

[ $# -eq 2 ] || usage
ISSUE=$1
HEADING=$2
require_number "$ISSUE"
NL='
'
case "$HEADING" in
  *"$NL"*) echo "$PROG: heading must be a single line" >&2; exit 2 ;;
esac
# Normalise the heading the way the comment's first line is normalised.
HEADING=$(printf '%s' "$HEADING" | sed 's/[ \t\r]*$//')
if [ -z "$HEADING" ]; then
  echo "$PROG: heading must not be empty" >&2
  exit 2
fi

# One line per fact, the comment's first line last since only it is free text.
# gh's --jq cannot take the heading as a variable, so the shell compares it.
QUERY='query($owner:String!,$repo:String!,$n:Int!){repository(owner:$owner,name:$repo){issueOrPullRequest(number:$n){... on Issue{createdAt lastEditedAt comments(last:1){nodes{body createdAt includesCreatedEdit url}}} ... on PullRequest{createdAt lastEditedAt comments(last:1){nodes{body createdAt includesCreatedEdit url}}}}}}'
JQ='.data.repository.issueOrPullRequest | (.lastEditedAt // .createdAt) as $body | .comments.nodes[0] as $c | if $c == null then "none" else "comment", $c.url, $c.createdAt, $body, ($c.includesCreatedEdit | tostring), ($body > $c.createdAt | tostring), ($c.body | split("\n")[0] | sub("[ \t\r]+$"; "")) end'
if ! FACTS=$(gh api graphql -F owner='{owner}' -F repo='{repo}' -F n="$ISSUE" -f query="$QUERY" --jq "$JQ"); then
  echo "$PROG: could not read issue or pull request #$ISSUE" >&2
  exit 3
fi

KIND=""; URL=""; POSTED=""; BODY_TIME=""; EDITED=""; BODY_LATER=""; FIRST=""
{
  IFS= read -r KIND
  IFS= read -r URL
  IFS= read -r POSTED
  IFS= read -r BODY_TIME
  IFS= read -r EDITED
  IFS= read -r BODY_LATER
  IFS= read -r FIRST
} <<FACTS_EOF
$FACTS
FACTS_EOF

case "$KIND" in
  none) echo "post: no comments"; exit 0 ;;
  comment) ;;
  *) echo "$PROG: unexpected gh output" >&2; exit 3 ;;
esac

if [ "$FIRST" != "$HEADING" ]; then
  echo "post: latest comment $URL is not headed '$HEADING'"
  exit 0
fi
if [ "$EDITED" = "true" ]; then
  echo "post: latest comment $URL is headed '$HEADING' but was edited after it was posted"
  exit 0
fi
if [ "$BODY_LATER" = "true" ]; then
  echo "post: body last changed $BODY_TIME, after $URL was posted $POSTED"
  exit 0
fi
echo "skip: $URL posted $POSTED; body last changed $BODY_TIME, not after it"
exit 1

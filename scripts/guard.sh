#!/usr/bin/env sh
# Decide whether a non-interactive skill run may post a comment under a heading.
#
#   guard.sh <issue> <heading>   print one "post: ..." or "skip: ..." reason line
#
# Exit 0: post. Exit 1: do not post. Exit 2: usage error. Exit 3: gh failed.
# See scripts/README.md and .claude/skills/_shared/preamble.md, section 4.

set -eu

. "$(dirname "$0")/lib.sh"

[ $# -eq 2 ] || usage
ISSUE=$1
HEADING=$2
require_number "$ISSUE"
if [ -z "$HEADING" ]; then
  echo "$PROG: heading must not be empty" >&2
  exit 2
fi

# One line per fact, the comment's first line last since only it is free text.
# gh's --jq cannot take the heading as a variable, so the shell compares it.
if ! FACTS=$(gh api graphql -F owner='{owner}' -F repo='{repo}' -F n="$ISSUE" \
  -f query='query($owner:String!,$repo:String!,$n:Int!){repository(owner:$owner,name:$repo){issue(number:$n){createdAt lastEditedAt comments(last:1){nodes{body createdAt includesCreatedEdit url}}}}}' \
  --jq '.data.repository.issue
    | (.lastEditedAt // .createdAt) as $body
    | .comments.nodes[0] as $c
    | if $c == null then "none"
      else "comment", $c.url, $c.createdAt, $body,
        ($c.includesCreatedEdit | tostring),
        ($body > $c.createdAt | tostring),
        ($c.body | split("\n")[0] | sub("[ \t\r]+$"; ""))
      end'); then
  echo "$PROG: could not read issue #$ISSUE" >&2
  exit 3
fi

if [ "$FACTS" = "none" ]; then
  echo "post: no comments"
  exit 0
fi

fact() { printf '%s\n' "$FACTS" | sed -n "${1}p"; }
URL=$(fact 2)
POSTED=$(fact 3)
BODY_TIME=$(fact 4)
EDITED=$(fact 5)
BODY_LATER=$(fact 6)
FIRST=$(fact 7)

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

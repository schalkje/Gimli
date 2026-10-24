#!/usr/bin/env sh
# Set the risk tier label on a GitHub issue or pull request.
#
#   risk.sh <issue>                   print the current tier, or "none"
#   risk.sh <issue> <tier> [note...]  post a comment, then replace the risk label
#
# Tiers: low medium high critical
# See docs/risk-assessment.md and docs/lifecycle.md, section "Stage status".

set -eu

. "$(dirname "$0")/lib.sh"

TIERS="low medium high critical"

parse_args "$@"

if [ -n "$TARGET" ] && ! in_list "$TARGET" "$TIERS"; then
  echo "$PROG: unknown tier '$TARGET'. Valid: $TIERS" >&2
  exit 2
fi

# Current risk labels, without the prefix. Fails if the issue does not exist.
CURRENT=$(gh issue view "$ISSUE" --json labels \
  --jq '[.labels[].name | select(startswith("risk:")) | sub("^risk:"; "")] | join(" ")')

check_canonical risk "$ISSUE" "$CURRENT" "$TIERS"
OLD=${CURRENT:-none}

if [ -z "$TARGET" ]; then
  echo "$OLD"
  exit 0
fi

if [ "$OLD" = "$TARGET" ]; then
  echo "#$ISSUE: already risk:$TARGET"
  exit 0
fi

# Every current risk label except the target. The target is never removed:
# gh applies --remove-label after --add-label, so removing and adding the
# same label would leave the issue with no risk label at all.
REMOVE=""
for t in $CURRENT; do
  [ "$t" = "$TARGET" ] && continue
  REMOVE="${REMOVE:+$REMOVE,}risk:$t"
done

# Comment first: if a later step fails, the issue is documented but unchanged,
# which is easier to recover than a changed but undocumented issue.
post_comment "$ISSUE" "Risk: $OLD → $TARGET" "$NOTE"

swap_labels "$ISSUE" "$REMOVE" "risk:$TARGET"

echo "#$ISSUE: $OLD → $TARGET"

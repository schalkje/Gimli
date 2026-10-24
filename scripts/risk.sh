#!/usr/bin/env sh
# Set the risk tier label on a GitHub issue.
#
#   risk.sh <issue>                   print the current tier, or "none"
#   risk.sh <issue> <tier> [note...]  post a comment, then replace the risk label
#
# Tiers: low medium high critical
# See docs/risk-assessment.md and docs/lifecycle.md, section "Stage status".

set -eu

TIERS="low medium high critical"

usage() {
  sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

is_tier() {
  for t in $TIERS; do
    [ "$t" = "$1" ] && return 0
  done
  return 1
}

[ $# -ge 1 ] || usage
ISSUE=$1
case "$ISSUE" in
  ''|*[!0-9]*) echo "risk.sh: issue must be a number, got '$ISSUE'" >&2; exit 2 ;;
esac
TARGET=${2:-}
NOTE=""
if [ $# -ge 3 ]; then
  shift 2
  NOTE="$*"
fi

if [ -n "$TARGET" ] && ! is_tier "$TARGET"; then
  echo "risk.sh: unknown tier '$TARGET'. Valid: $TIERS" >&2
  exit 2
fi

# Current risk labels, without the prefix. Fails if the issue does not exist.
CURRENT=$(gh issue view "$ISSUE" --json labels \
  --jq '[.labels[].name | select(startswith("risk:")) | sub("^risk:"; "")] | join(" ")')
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

COMMENT="Risk: $OLD → $TARGET"
if [ -n "$NOTE" ]; then
  COMMENT="$COMMENT

$NOTE"
fi

# Comment first: if a later step fails, the issue is documented but unchanged,
# which is easier to recover than a changed but undocumented issue.
gh issue comment "$ISSUE" --body "$COMMENT" >/dev/null

if [ -n "$REMOVE" ]; then
  gh issue edit "$ISSUE" --remove-label "$REMOVE" --add-label "risk:$TARGET" >/dev/null
else
  gh issue edit "$ISSUE" --add-label "risk:$TARGET" >/dev/null
fi

echo "#$ISSUE: $OLD → $TARGET"

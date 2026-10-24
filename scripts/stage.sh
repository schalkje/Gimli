#!/usr/bin/env sh
# Move a GitHub issue through the Gimli lifecycle stages.
#
#   stage.sh <issue>                   print the current stage, or "none"
#   stage.sh <issue> <stage> [note]    replace the stage label and post a comment
#   stage.sh <issue> close [note]      remove the stage label, comment, close the issue
#
# Stages: refine plan build test evidence assess review merge
# See docs/lifecycle.md, section "Stage status".

set -eu

STAGES="refine plan build test evidence assess review merge"

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

[ $# -ge 1 ] || usage
ISSUE=$1
case "$ISSUE" in
  ''|*[!0-9]*) echo "stage.sh: issue must be a number, got '$ISSUE'" >&2; exit 2 ;;
esac
TARGET=${2:-}
NOTE=${3:-}

if [ -n "$TARGET" ] && [ "$TARGET" != "close" ]; then
  valid=0
  for s in $STAGES; do
    [ "$s" = "$TARGET" ] && valid=1
  done
  if [ "$valid" -eq 0 ]; then
    echo "stage.sh: unknown stage '$TARGET'. Valid: $STAGES close" >&2
    exit 2
  fi
fi

# Current stage labels (normally zero or one). Fails if the issue does not exist.
CURRENT=$(gh issue view "$ISSUE" --json labels \
  --jq '[.labels[].name | select(startswith("stage:")) | sub("^stage:"; "")] | join(" ")')
OLD=${CURRENT:-none}

if [ -z "$TARGET" ]; then
  echo "$OLD"
  exit 0
fi

REMOVE=""
for s in $CURRENT; do
  REMOVE="${REMOVE:+$REMOVE,}stage:$s"
done

COMMENT="Stage: $OLD → $TARGET"
[ -n "$NOTE" ] && COMMENT="$COMMENT

$NOTE"

if [ "$TARGET" = "close" ]; then
  if [ -n "$REMOVE" ]; then
    gh issue edit "$ISSUE" --remove-label "$REMOVE" >/dev/null
  fi
  gh issue close "$ISSUE" --comment "$COMMENT" >/dev/null
else
  if [ -n "$REMOVE" ]; then
    gh issue edit "$ISSUE" --remove-label "$REMOVE" --add-label "stage:$TARGET" >/dev/null
  else
    gh issue edit "$ISSUE" --add-label "stage:$TARGET" >/dev/null
  fi
  gh issue comment "$ISSUE" --body "$COMMENT" >/dev/null
fi

echo "#$ISSUE: $OLD → $TARGET"

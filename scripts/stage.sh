#!/usr/bin/env sh
# Move a GitHub issue through the Gimli lifecycle stages.
#
#   stage.sh <issue>                   print the current stage, or "none"
#   stage.sh <issue> <stage> [note...]  post a comment, then replace the stage label
#   stage.sh <issue> close [note...]    post a comment, remove the stage label, close
#
# Stages: refine plan build test evidence assess review merge
# See docs/lifecycle.md, section "Stage status".

set -eu

STAGES="refine plan build test evidence assess review merge"

usage() {
  sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
  exit 2
}

is_stage() {
  for s in $STAGES; do
    [ "$s" = "$1" ] && return 0
  done
  return 1
}

[ $# -ge 1 ] || usage
ISSUE=$1
case "$ISSUE" in
  ''|*[!0-9]*) echo "stage.sh: issue must be a number, got '$ISSUE'" >&2; exit 2 ;;
esac
TARGET=${2:-}
NOTE=""
if [ $# -ge 3 ]; then
  shift 2
  NOTE="$*"
fi

if [ -n "$TARGET" ] && [ "$TARGET" != "close" ] && ! is_stage "$TARGET"; then
  echo "stage.sh: unknown stage '$TARGET'. Valid: $STAGES close" >&2
  exit 2
fi

# State and current stage labels. Fails if the issue does not exist.
INFO=$(gh issue view "$ISSUE" --json labels,state \
  --jq '.state + " " + ([.labels[].name | select(startswith("stage:")) | sub("^stage:"; "")] | join(" "))')
STATE=${INFO%% *}
CURRENT=${INFO#"$STATE"}
CURRENT=${CURRENT# }

REMOVE=""
for s in $CURRENT; do
  if ! is_stage "$s"; then
    echo "stage.sh: issue #$ISSUE carries a non-canonical stage label; fix it by hand first. Found: $CURRENT" >&2
    exit 1
  fi
  REMOVE="${REMOVE:+$REMOVE,}stage:$s"
done
OLD=${CURRENT:-none}

if [ -z "$TARGET" ]; then
  echo "$OLD"
  exit 0
fi

if [ "$TARGET" != "close" ] && [ "$OLD" = "$TARGET" ]; then
  echo "#$ISSUE: already at $TARGET"
  exit 0
fi

COMMENT="Stage: $OLD → $TARGET"
if [ -n "$NOTE" ]; then
  COMMENT="$COMMENT

$NOTE"
fi

# Comment first: if a later step fails, the issue is documented but unmoved,
# which is easier to recover than a moved but undocumented issue.
gh issue comment "$ISSUE" --body "$COMMENT" >/dev/null

if [ "$TARGET" = "close" ]; then
  if [ -n "$REMOVE" ]; then
    gh issue edit "$ISSUE" --remove-label "$REMOVE" >/dev/null
  fi
  if [ "$STATE" != "CLOSED" ]; then
    gh issue close "$ISSUE" >/dev/null
  fi
else
  if [ "$STATE" = "CLOSED" ]; then
    gh issue reopen "$ISSUE" >/dev/null
  fi
  if [ -n "$REMOVE" ]; then
    gh issue edit "$ISSUE" --remove-label "$REMOVE" --add-label "stage:$TARGET" >/dev/null
  else
    gh issue edit "$ISSUE" --add-label "stage:$TARGET" >/dev/null
  fi
fi

echo "#$ISSUE: $OLD → $TARGET"

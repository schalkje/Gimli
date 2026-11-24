#!/usr/bin/env sh
# Move a GitHub issue through the Gimli lifecycle stages.
#
#   stage.sh <issue>                   print the current stage, or "none"
#   stage.sh <issue> <stage> [note...]  post a comment, then replace the stage label
#   stage.sh <issue> close [note...]    post a comment, remove the stage label, close
#   stage.sh <issue> parent [note...]   post a comment, remove the stage label, keep state
#
# Stages: refine plan build test evidence assess review merge
# See docs/lifecycle.md, sections "Stage status" and "Parent issues".

set -eu

. "$(dirname "$0")/lib.sh"

STAGES="refine plan build test evidence assess review merge"

parse_args "$@"

if [ -n "$TARGET" ] && ! in_list "$TARGET" "$STAGES close parent"; then
  echo "$PROG: unknown stage '$TARGET'. Valid: $STAGES close parent" >&2
  exit 2
fi

# State and current stage labels. Fails if the issue does not exist.
INFO=$(gh issue view "$ISSUE" --json labels,state \
  --jq '.state + " " + ([.labels[].name | select(startswith("stage:")) | sub("^stage:"; "")] | join(" "))')
STATE=${INFO%% *}
CURRENT=${INFO#"$STATE"}
CURRENT=${CURRENT# }

check_canonical stage "$ISSUE" "$CURRENT" "$STAGES"
REMOVE=""
for s in $CURRENT; do
  REMOVE="${REMOVE:+$REMOVE,}stage:$s"
done
OLD=${CURRENT:-none}

if [ -z "$TARGET" ]; then
  echo "$OLD"
  exit 0
fi

if [ "$TARGET" = "parent" ] && [ -z "$CURRENT" ]; then
  echo "#$ISSUE: no stage label"
  exit 0
fi

if [ "$TARGET" != "close" ] && [ "$OLD" = "$TARGET" ]; then
  echo "#$ISSUE: already at $TARGET"
  exit 0
fi

# Comment first: if a later step fails, the issue is documented but unmoved,
# which is easier to recover than a moved but undocumented issue.
post_comment "$ISSUE" "Stage: $OLD → $TARGET" "$NOTE"

if [ "$TARGET" = "close" ]; then
  swap_labels "$ISSUE" "$REMOVE" ""
  if [ "$STATE" != "CLOSED" ]; then
    gh issue close "$ISSUE" >/dev/null
  fi
elif [ "$TARGET" = "parent" ]; then
  swap_labels "$ISSUE" "$REMOVE" ""
else
  if [ "$STATE" = "CLOSED" ]; then
    gh issue reopen "$ISSUE" >/dev/null
  fi
  swap_labels "$ISSUE" "$REMOVE" "stage:$TARGET"
fi

echo "#$ISSUE: $OLD → $TARGET"

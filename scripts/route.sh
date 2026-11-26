#!/usr/bin/env sh
# Print the agent, model and effort for a task of a change folder.
#
#   route.sh <kind> <complexity>   print "<agent> <model> <effort>"
#
# Kinds: design spec test-design implement test-unit test-e2e docs review
# Complexity: low medium high
# The table is the routing table in docs/specs/task-routing/spec.md;
# scripts/tests/route_test.sh checks this script against it.

set -eu

. "$(dirname "$0")/lib.sh"

KINDS="design spec test-design implement test-unit test-e2e docs review"
LEVELS="low medium high"

[ $# -eq 2 ] || usage >&2

KIND=$1
LEVEL=$2

if ! in_list "$KIND" "$KINDS"; then
  echo "$PROG: unknown kind '$KIND'. Valid: $KINDS" >&2
  exit 2
fi
if ! in_list "$LEVEL" "$LEVELS"; then
  echo "$PROG: unknown complexity '$LEVEL'. Valid: $LEVELS" >&2
  exit 2
fi

case "$KIND/$LEVEL" in
  design/low)        CELL="sonnet medium" ;;
  design/medium)     CELL="sonnet high" ;;
  design/high)       CELL="opus high" ;;
  spec/low)          CELL="sonnet medium" ;;
  spec/medium)       CELL="sonnet high" ;;
  spec/high)         CELL="opus high" ;;
  test-design/low)    CELL="sonnet medium" ;;
  test-design/medium) CELL="sonnet high" ;;
  test-design/high)   CELL="opus high" ;;
  implement/low)     CELL="sonnet low" ;;
  implement/medium)  CELL="sonnet medium" ;;
  implement/high)    CELL="opus high" ;;
  test-unit/low)     CELL="haiku low" ;;
  test-unit/medium)  CELL="sonnet low" ;;
  test-unit/high)    CELL="sonnet medium" ;;
  test-e2e/low)      CELL="sonnet low" ;;
  test-e2e/medium)   CELL="sonnet medium" ;;
  test-e2e/high)     CELL="opus high" ;;
  docs/low)          CELL="haiku low" ;;
  docs/medium)       CELL="sonnet medium" ;;
  docs/high)         CELL="opus high" ;;
  review/low)        CELL="sonnet high" ;;
  review/medium)     CELL="opus medium" ;;
  review/high)       CELL="opus high" ;;
  *) echo "$PROG: no route for $KIND/$LEVEL" >&2; exit 2 ;;
esac

echo "gimli-$KIND $CELL"

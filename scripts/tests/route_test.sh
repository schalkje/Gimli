#!/usr/bin/env sh
# Test scripts/route.sh against the routing table in the task routing spec.
#
#   sh scripts/tests/route_test.sh
#
# Covers ROUTE-1.1 to ROUTE-1.4, ROUTE-2.1 to ROUTE-2.3 and ROUTE-5.1 in
# docs/specs/task-routing/spec.md. Prints one line per check and a summary;
# exits 1 if any check fails. Uses no network and no gh.

set -u

HERE=$(dirname "$0")
ROUTE="$HERE/../route.sh"
SPEC="$HERE/../../docs/specs/task-routing/spec.md"

PASS=0
FAIL=0

ok() {
  PASS=$((PASS + 1))
  echo "ok   $1"
}

not_ok() {
  FAIL=$((FAIL + 1))
  echo "FAIL $1"
}

# check_route <label> <kind> <complexity> <expected stdout>
check_route() {
  _out=$(sh "$ROUTE" "$2" "$3" 2>/dev/null)
  _status=$?
  if [ "$_status" -eq 0 ] && [ "$_out" = "$4" ]; then
    ok "$1: $2 $3 -> $_out"
  else
    not_ok "$1: $2 $3 -> '$_out' (status $_status), expected '$4'"
  fi
}

# check_invalid <label> <args...>: status 2 and nothing on standard output.
check_invalid() {
  _label=$1
  shift
  _out=$(sh "$ROUTE" "$@" 2>/dev/null)
  _status=$?
  if [ "$_status" -eq 2 ] && [ -z "$_out" ]; then
    ok "$_label: route.sh $* -> status 2, no output"
  else
    not_ok "$_label: route.sh $* -> '$_out' (status $_status), expected status 2 and no output"
  fi
}

# The rows of the table under Requirement ROUTE-1, as
# "<kind> <model> <effort> <model> <effort> <model> <effort>" per line.
ROWS=$(awk '
  /^### Requirement ROUTE-1:/ { inreq = 1; next }
  inreq && /^#/ { exit }
  inreq && /^\| *[a-z]/ && !/^\| *Kind *\|/ {
    line = $0
    gsub(/^\| *| *\|$/, "", line)
    n = split(line, cell, / *\| */)
    if (n == 4) print cell[1], cell[2], cell[3], cell[4]
  }
' "$SPEC")

CELLS=0
# ROUTE-1.4: every cell of the spec's table.
while read -r kind lm le mm me hm he; do
  [ -n "$kind" ] || continue
  check_route "ROUTE-1.4" "$kind" low "gimli-$kind $lm $le"
  check_route "ROUTE-1.4" "$kind" medium "gimli-$kind $mm $me"
  check_route "ROUTE-1.4" "$kind" high "gimli-$kind $hm $he"
  CELLS=$((CELLS + 3))
done <<EOF
$ROWS
EOF

# A parse that finds too few cells must not pass.
if [ "$CELLS" -eq 21 ]; then
  ok "ROUTE-1.4: the spec's table has 21 cells"
else
  not_ok "ROUTE-1.4: the spec's table has $CELLS cells, expected 21"
fi

check_route "ROUTE-1.1" implement high "gimli-implement opus high"
check_route "ROUTE-1.2" docs low "gimli-docs haiku low"
check_route "ROUTE-1.3" review low "gimli-review sonnet high"

check_invalid "ROUTE-2.1" deploy low
check_invalid "ROUTE-2.2" implement extreme
check_invalid "ROUTE-2.3"
check_invalid "ROUTE-2.3" implement
check_invalid "ROUTE-2.3" implement high extra
check_invalid "ROUTE-2.3" --tables

# ROUTE-5.1: --table prints every cell, in the table's order, one line each,
# and exits 0. The expected lines come from the same $ROWS as ROUTE-1.4.
EXPECTED=$(while read -r kind lm le mm me hm he; do
  [ -n "$kind" ] || continue
  echo "$kind low gimli-$kind $lm $le"
  echo "$kind medium gimli-$kind $mm $me"
  echo "$kind high gimli-$kind $hm $he"
done <<EOF
$ROWS
EOF
)
TABLE=$(sh "$ROUTE" --table 2>/dev/null)
TABLE_STATUS=$?
if [ "$TABLE_STATUS" -eq 0 ] && [ "$TABLE" = "$EXPECTED" ]; then
  ok "ROUTE-5.1: route.sh --table prints the 21 cells in table order, status 0"
else
  not_ok "ROUTE-5.1: route.sh --table -> status $TABLE_STATUS, output differs from the spec's table"
  echo "$TABLE" | sed 's/^/     got: /'
fi

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]

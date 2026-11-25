#!/usr/bin/env sh
# Test scripts/route.sh against the routing table in the task routing spec.
#
#   sh scripts/tests/route_test.sh
#
# Covers ROUTE-1.1 to ROUTE-1.4 and ROUTE-2.1 to ROUTE-2.3 in
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

# check_invalid <label> <expected on stderr> <args...>: status 2, nothing on
# standard output, and standard error contains the expected text, or equals
# it exactly when the expected text starts with "=".
check_invalid() {
  _label=$1
  _want=$2
  shift 2
  _err=$(sh "$ROUTE" "$@" 2>&1 >/dev/null)
  _out=$(sh "$ROUTE" "$@" 2>/dev/null)
  _status=$?
  case "$_want" in
    "=$_err") _named=yes ;;
    =*) _named=no ;;
    *) case "$_err" in
         *"$_want"*) _named=yes ;;
         *) _named=no ;;
       esac ;;
  esac
  if [ "$_status" -eq 2 ] && [ -z "$_out" ] && [ "$_named" = yes ]; then
    ok "$_label: route.sh $* -> status 2, no output, names '$_want'"
  else
    not_ok "$_label: route.sh $* -> '$_out' (status $_status), stderr '$_err'; expected status 2, no output, and '$_want'"
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

# The kinds in the spec's table, in order. A parse that finds no rows, or
# rows without three cells, must not pass.
SPEC_KINDS=$(echo "$ROWS" | awk 'NF { printf "%s%s", sep, $1; sep = " " }')
NKINDS=$(echo "$SPEC_KINDS" | wc -w | tr -d ' ')
if [ "$NKINDS" -gt 0 ] && [ "$CELLS" -eq $((NKINDS * 3)) ]; then
  ok "ROUTE-1.4: the spec's table has $CELLS cells for $NKINDS kinds"
else
  not_ok "ROUTE-1.4: the spec's table has $CELLS cells for $NKINDS kinds, expected three per kind"
fi

check_route "ROUTE-1.1" implement high "gimli-implement opus high"
check_route "ROUTE-1.2" docs low "gimli-docs haiku low"
check_route "ROUTE-1.3" review low "gimli-review sonnet high"

# ROUTE-2.1 compares the whole message, so route.sh naming a kind the spec
# lacks, or lacking one it has, fails here.
USAGE="route.sh <kind> <complexity>"
check_invalid "ROUTE-2.1" "=route.sh: unknown kind 'deploy'. Valid: $SPEC_KINDS" deploy low
check_invalid "ROUTE-2.2" "Valid: low medium high" implement extreme
check_invalid "ROUTE-2.3" "$USAGE"
check_invalid "ROUTE-2.3" "$USAGE" implement
check_invalid "ROUTE-2.3" "$USAGE" implement high extra

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]

#!/usr/bin/env sh
# List every scenario of the specs with whether something shows it holds.
#
#   trace.sh [<specs> <tests>]   print "<ID> <status> <source>" per scenario
#
# Reads <specs>/*/spec.md (not _template) and runs <tests>/*_test.sh with sh;
# the defaults are docs/specs and scripts/tests of this repository.
# Status: tested (a test file exits 0 and prints "ok <ID>:"), evidence or
# not-yet (a "**Verified by:**" line under the scenario), failing, uncovered.
# The source is "-" when there is none. Exit 1 when a scenario is uncovered or
# failing, or a test file exits non-zero. The rules are in
# docs/specs/traceability/spec.md; scripts/tests/trace_test.sh checks them.

set -eu

. "$(dirname "$0")/lib.sh"

case $# in
  0) ROOT=$(dirname "$0")/..
     SPECS=$ROOT/docs/specs
     TESTS=$ROOT/scripts/tests ;;
  2) SPECS=$1
     TESTS=$2 ;;
  *) usage >&2 ;;
esac

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
trap 'exit 130' INT TERM
: > "$WORK/records"
BAD=0

# lib.sh turned globbing off; the two loops below need it.
set +f

# Scenario records "S<TAB>ID<TAB>has<TAB>text", in file and heading order.
for f in "$SPECS"/*/spec.md; do
  [ -e "$f" ] || continue
  case $f in */_template/spec.md) continue ;; esac
  awk '
    { sub(/\r$/, "") }
    /^#/ {
      cur = ""
      if (match($0, /^#### Scenario [A-Z]+-[0-9]+\.[0-9]+:/)) {
        cur = substr($0, 15, RLENGTH - 15)
        print "S\t" cur "\t0\t"
      }
      next
    }
    cur != "" && index($0, "**Verified by:**") == 1 && !(cur in seen) {
      seen[cur] = 1
      t = substr($0, 17)
      sub(/^[ \t]+/, "", t)
      sub(/[ \t]+$/, "", t)
      print "V\t" cur "\t" t
    }
  ' "$f" >> "$WORK/records"
done

# Check records "R<TAB>file<TAB>exit<TAB>ok|FAIL<TAB>ID", one per check line.
for f in "$TESTS"/*_test.sh; do
  [ -e "$f" ] || continue
  st=0
  sh "$f" > "$WORK/out" 2>/dev/null < /dev/null || st=$?
  [ "$st" -eq 0 ] || BAD=1
  awk -v base="$(basename "$f")" -v st="$st" '
    { sub(/\r$/, "") }
    /^ok +[A-Z]+-[0-9]+\.[0-9]+:/ {
      match($0, /[A-Z]+-[0-9]+\.[0-9]+:/)
      print "R\t" base "\t" st "\tok\t" substr($0, RSTART, RLENGTH - 1)
    }
    /^FAIL [A-Z]+-[0-9]+\.[0-9]+:/ {
      print "R\t" base "\t" st "\tFAIL\t" substr($0, 6, index($0, ":") - 6)
    }
  ' "$WORK/out" >> "$WORK/records"
done

# Combine: order and text from the S and V records, checks from the R records.
awk -F'\t' '
  $1 == "S" { n++; ids[n] = $2; next }
  $1 == "V" {
    t = substr($0, length($2) + 4)
    if (t != "") { vb[$2] = t; has[$2] = 1 }
    next
  }
  $1 == "R" {
    bad = ($4 == "FAIL" || $3 != 0)
    if (bad && !($5 in failing)) failing[$5] = $2
    if (!bad && !($5 in tested)) tested[$5] = $2
  }
  END {
    for (i = 1; i <= n; i++) {
      id = ids[i]
      if (id in failing)     { s = "failing";  src = failing[id] }
      else if (id in tested) { s = "tested";   src = tested[id] }
      else if (id in has) {
        t = vb[id]
        if (t ~ /^not yet([ \t:]|$)/) {
          s = "not-yet"
          src = substr(t, 8)
          sub(/^[ \t]*:?/, "", src)
          sub(/^[ \t]+/, "", src)
          sub(/[ \t]+$/, "", src)
          if (src == "") src = "-"
        } else { s = "evidence"; src = t }
      } else { s = "uncovered"; src = "-" }
      print id " " s " " src
    }
  }
' "$WORK/records" > "$WORK/lines"

cat "$WORK/lines"
if grep -Eq '^[^ ]+ (uncovered|failing) ' "$WORK/lines"; then
  BAD=1
fi
exit "$BAD"

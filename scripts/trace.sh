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
# failing, a test file exits non-zero, a "#### Scenario" line is not a
# well-formed heading, or two headings share an ID; exit 2 on a usage error
# or a path that is not a folder. The rules are in
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

for d in "$SPECS" "$TESTS"; do
  if [ ! -d "$d" ]; then
    echo "trace.sh: not a folder: $d" >&2
    exit 2
  fi
done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
trap 'exit 130' INT TERM
: > "$WORK/records"
BAD=0

# lib.sh turned globbing off; the two loops below need it.
set +f

# Records, in file and heading order: "S<TAB>ID<TAB>file:line" per scenario
# heading; "V<TAB>file:line<TAB>text" for the first non-empty Verified by
# line under the heading at file:line; "M<TAB>file:line<TAB>text" per
# "#### Scenario" line that does not parse; "U<TAB>file:line" per code
# block still open at the end of its file. Fences and headings may be
# indented up to three spaces, as in Markdown. A fence closes only on the
# same character, at least as many times; a backtick run with a backtick
# after it is inline code, not a fence. A heading is #s and a space.
for f in "$SPECS"/*/spec.md; do
  [ -e "$f" ] || continue
  case $f in */_template/spec.md) continue ;; esac
  awk '
    { sub(/\r$/, "")
      match($0, /^ */)
      l = (RLENGTH <= 3) ? substr($0, RLENGTH + 1) : "" }
    l ~ /^(```|~~~)/ {
      c = substr(l, 1, 1)
      n = 0
      while (substr(l, n + 1, 1) == c) n++
      rest = substr(l, n + 1)
      if (!fence) {
        if (c == "`" && index(rest, "`") > 0) next
        fence = 1; fc = c; fl = n; at = FILENAME ":" FNR
      } else if (c == fc && n >= fl && rest ~ /^[ \t]*$/) fence = 0
      next
    }
    fence { next }
    l ~ /^#+( |$)/ {
      cur = ""
      if (match(l, /^#### Scenario [A-Z]+-[0-9]+\.[0-9]+:/)) {
        cur = FILENAME ":" FNR
        print "S\t" substr(l, 15, RLENGTH - 15) "\t" cur
      } else if (l ~ /^#### Scenario( |$)/) {
        print "M\t" FILENAME ":" FNR "\t" l
      }
      next
    }
    cur != "" && index($0, "**Verified by:**") == 1 && !(cur in seen) {
      t = substr($0, 17)
      sub(/^[ \t]+/, "", t)
      sub(/[ \t]+$/, "", t)
      if (t != "") { seen[cur] = 1; print "V\t" cur "\t" t }
    }
    END { if (fence) print "U\t" at }
  ' "$f" >> "$WORK/records"
done

# Check records "R<TAB>file<TAB>exit<TAB>ok|FAIL<TAB>ID", one per check line.
for f in "$TESTS"/*_test.sh; do
  [ -e "$f" ] || continue
  st=0
  sh "$f" > "$WORK/out" 2> "$WORK/err" < /dev/null || st=$?
  if [ "$st" -ne 0 ]; then
    BAD=1
    echo "trace.sh: $(basename "$f") exited $st" >&2
    tail -n 5 "$WORK/err" | sed 's/^/  /' >&2
  fi
  awk -v base="$(basename "$f")" -v st="$st" '
    { sub(/\r$/, "") }
    /^ok +[A-Z]+-[0-9]+\.[0-9]+:/ {
      match($0, /[A-Z]+-[0-9]+\.[0-9]+:/)
      print "R\t" base "\t" st "\tok\t" substr($0, RSTART, RLENGTH - 1)
    }
    /^FAIL +[A-Z]+-[0-9]+\.[0-9]+:/ {
      match($0, /[A-Z]+-[0-9]+\.[0-9]+:/)
      print "R\t" base "\t" st "\tFAIL\t" substr($0, RSTART, RLENGTH - 1)
    }
  ' "$WORK/out" >> "$WORK/records"
done

# Combine: order and text from the S and V records, checks from the R records.
awk -F'\t' '
  $1 == "S" { n++; ids[n] = $2; locs[n] = $3; next }
  $1 == "V" { vb[$2] = substr($0, length($2) + 4); has[$2] = 1; next }
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
      else if (locs[i] in has) {
        t = vb[locs[i]]
        if (tolower(t) ~ /^not yet([ \t:]|$)/) {
          s = "not-yet"
          src = substr(t, 8)
          sub(/^[ \t]*:?/, "", src)
          sub(/^[ \t]+/, "", src)
          sub(/[ \t]+$/, "", src)
          if (src == "") src = "-"
        } else if (t ~ /\[[^]]+\]\([^)]+\)/) { s = "evidence"; src = t }
        else { s = "uncovered"; src = "-" }
      } else { s = "uncovered"; src = "-" }
      print id " " s " " src
    }
  }
' "$WORK/records" > "$WORK/lines"

cat "$WORK/lines"
TAB=$(printf '\t')
while IFS=$TAB read -r kind loc text; do
  case $kind in
    M) echo "trace.sh: $loc: not a scenario heading: $text" >&2 ;;
    U) echo "trace.sh: $loc: code block not closed" >&2 ;;
    *) continue ;;
  esac
  BAD=1
done < "$WORK/records"
awk -F'\t' '
  $1 == "S" {
    if ($2 in at) print "trace.sh: " $3 ": duplicate scenario ID " $2 ", first at " at[$2]
    else at[$2] = $3
  }
' "$WORK/records" > "$WORK/dups"
if [ -s "$WORK/dups" ]; then
  cat "$WORK/dups" >&2
  BAD=1
fi
if grep -Eq '^[^ ]+ (uncovered|failing) ' "$WORK/lines"; then
  BAD=1
fi
exit "$BAD"

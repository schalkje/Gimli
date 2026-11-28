#!/usr/bin/env sh
# Test scripts/trace.sh against the traceability spec.
#
#   sh scripts/tests/trace_test.sh
#
# Covers TRACE-1.1 to TRACE-5.5 in docs/specs/traceability/spec.md; the cases
# are in docs/changes/65-traceability/test-design.md and, for TRACE-1.7, 1.8,
# 3.1, 3.4 and 5.5, docs/changes/68-traceability-gaps/test-design.md. Each case builds fixture
# spec and test folders in a temporary directory and runs trace.sh on them,
# never on scripts/tests, so this test does not run itself. Prints one line
# per check and a summary; exits 1 if any check fails. Uses no network and
# no gh.

set -u

HERE=$(cd "$(dirname "$0")" && pwd)
TRACE="$HERE/../trace.sh"

PASS=0
FAIL=0
CR=$(printf '\r')

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
trap 'exit 130' INT TERM

ok() {
  PASS=$((PASS + 1))
  echo "ok   $1"
}

not_ok() {
  FAIL=$((FAIL + 1))
  echo "FAIL $1"
}

# lines <line>...: one argument per line, for expected output.
lines() {
  printf '%s\n' "$@"
}

# fx <case> [specs folder name] [tests folder name]: a fresh fixture; sets D, S, T.
fx() {
  D=$TMP/$1
  S=$D/${2:-specs}
  T=$D/${3:-tests}
  mkdir -p "$S" "$T"
}

# mkspec <name> <scenario>...: $S/<name>/spec.md. A scenario is "ID" or
# "ID|text", the text becoming a "**Verified by:** text" paragraph under it.
mkspec() {
  _name=$1
  shift
  mkdir -p "$S/$_name"
  {
    echo "# Spec"
    echo
    _last=
    for _a in "$@"; do
      _id=${_a%%|*}
      _req=${_id%.*}
      if [ "$_req" != "$_last" ]; then
        echo "### Requirement $_req: R"
        echo
        _last=$_req
      fi
      echo "#### Scenario $_id: S"
      echo
      echo "- GIVEN g"
      echo "- WHEN w"
      echo "- THEN t"
      echo
      case $_a in
        *"|"*) echo "**Verified by:** ${_a#*|}"; echo ;;
      esac
    done
  } > "$S/$_name/spec.md"
}

# mktest <file> <script line>...: $T/<file>, one script line per argument.
mktest() {
  _file=$1
  shift
  mkdir -p "$(dirname "$T/$_file")"
  for _l in "$@"; do
    printf '%s\n' "$_l"
  done > "$T/$_file"
}

# mkcheck <file> <exit> <"ok ID" | "FAIL ID">...: a test file printing those
# check lines and exiting with <exit>.
mkcheck() {
  _file=$1
  _exit=$2
  shift 2
  mkdir -p "$(dirname "$T/$_file")"
  {
    for _l in "$@"; do
      echo "echo '$_l: works'"
    done
    echo "exit $_exit"
  } > "$T/$_file"
}

# tocrlf <file>...: rewrite the files with CRLF line endings.
tocrlf() {
  for _f in "$@"; do
    sed "s/\$/$CR/" "$_f" > "$_f.crlf" && mv "$_f.crlf" "$_f"
  done
}

# check_run <label> <expected status> <expected stdout> <args...>: run
# trace.sh, compare the whole standard output and the status, and never
# accept a carriage return. Returns 1 on a mismatch. With IDONLY set, only
# the first column of the output is compared.
check_run() {
  _label=$1
  _est=$2
  _exp=$3
  shift 3
  _out=$(sh "$TRACE" "$@" 2> "$TMP/err" < /dev/null)
  _st=$?
  _cr=
  case $_out in *"$CR"*) _cr=" (carriage return in output)" ;; esac
  if [ -n "${IDONLY:-}" ]; then
    _out=$(printf '%s\n' "$_out" | cut -d' ' -f1)
  fi
  if [ "$_st" -eq "$_est" ] && [ "$_out" = "$_exp" ] && [ -z "$_cr" ]; then
    ok "$_label"
    return 0
  fi
  not_ok "$_label: got '$(printf '%s' "$_out" | tr '\n' '|')' status $_st$_cr, expected '$(printf '%s' "$_exp" | tr '\n' '|')' status $_est"
  return 1
}

# chk <label> <status> <expected>: check_run on the fixture folders.
chk() {
  check_run "$1" "$2" "$3" "$S" "$T"
}

# chk_ids: like chk, comparing only the ID column.
chk_ids() {
  IDONLY=1
  check_run "$1" "$2" "$3" "$S" "$T"
  IDONLY=
}

# check_err <label> <fixed text>: the last run wrote the text on standard error.
check_err() {
  if grep -F -q -- "$2" "$TMP/err"; then
    ok "$1"
  else
    not_ok "$1: standard error was '$(cat "$TMP/err")'"
  fi
}

# check_no_file <label> <file>: the file does not exist.
check_no_file() {
  if [ ! -e "$2" ]; then
    ok "$1"
  else
    not_ok "$1: $2 exists, a test file was run"
  fi
}

U1='https://example.org/1'
NL='
'
TAB=$(printf '\t')

# hand <name> <line>...: $S/<name>/spec.md written by hand: the shape of
# mkspec's (title, requirement, scenario CAP-1.1, GIVEN/WHEN/THEN, blank line),
# then the lines as given, with no blank line added. With NONL set, no final
# newline.
hand() {
  _hn=$1
  shift
  mkdir -p "$S/$_hn"
  {
    printf '# Spec\n\n### Requirement CAP-1: R\n\n#### Scenario CAP-1.1: S\n\n- GIVEN g\n- WHEN w\n- THEN t\n\n'
    printf '%s\n' "$@"
  } > "$S/$_hn/spec.md"
  if [ -n "${NONL:-}" ]; then
    printf '%s' "$(cat "$S/$_hn/spec.md")" > "$S/$_hn/spec.tmp" && mv "$S/$_hn/spec.tmp" "$S/$_hn/spec.md"
  fi
}

# pick_locale <candidate>...: the first locale in which the glob puts a before
# B ("a B"), nothing if there is none.
pick_locale() {
  _pd=$TMP/probe
  if [ ! -d "$_pd" ]; then
    mkdir -p "$_pd"
    : > "$_pd/B"
    : > "$_pd/a"
  fi
  for _c in "$@"; do
    _g=$(LC_ALL=$_c sh -c 'cd "$1" && set -- *; echo "$*"' _ "$_pd" 2> /dev/null)
    if [ "$_g" = "a B" ]; then
      echo "$_c"
      return 0
    fi
  done
  return 0
}

# loc_chk <label> <status> <expected>: chk with LC_ALL set to the picked
# locale for this run only (not in a subshell, so the counters keep).
loc_chk() {
  _was=${LC_ALL+x}
  _old=${LC_ALL-}
  if [ -n "$LOC" ]; then
    LC_ALL=$LOC
    export LC_ALL
  fi
  chk "$1" "$2" "$3"
  _lr=$?
  if [ -n "$_was" ]; then
    LC_ALL=$_old
  else
    unset LC_ALL
  fi
  return $_lr
}

# rerun_test <file> <specs> <tests> <command> <first line> <ID>: a test file
# in $T that counts its calls in $0.calls and, on its first call only, runs
# <command> trace.sh <specs> <tests>, keeping status, output and error in
# $0.st, $0.out and $0.err. It prints "ok <ID>: works" and exits 0.
rerun_test() {
  mktest "$1" "$5" 'echo x >> "$0.calls"' \
    'if [ "$(wc -l < "$0.calls" | tr -d " ")" -eq 1 ]; then' \
    "  $4 '$TRACE' '$2' '$3' > \"\$0.out\" 2> \"\$0.err\"; echo \$? > \"\$0.st\"" \
    'fi' "echo 'ok $6: works'" 'exit 0'
}

# check_refused <label> <test file> <message>: the rerun the test file made
# was refused: status 2, no output, the message alone on standard error, one call.
check_refused() {
  _rst=$(cat "$2.st" 2> /dev/null)
  _rout=$(cat "$2.out" 2> /dev/null)
  _rerr=$(cat "$2.err" 2> /dev/null)
  _rn=$(wc -l < "$2.calls" 2> /dev/null | tr -d ' ')
  if [ "$_rst" = 2 ] && [ -z "$_rout" ] && [ "$_rerr" = "$3" ] && [ "$_rn" = 1 ]; then
    ok "$1"
    return 0
  fi
  not_ok "$1: status '$_rst', output '$_rout', error '$_rerr', calls '$_rn'"
  return 1
}

# t55 <label> <command> <specs arg> <tests arg>: TRACE-5.5 case a on the
# current fixture, the test rerunning trace.sh with <command> on the given
# arguments. Returns 1 if any check fails.
t55() {
  mkspec a CAP-1.1
  rerun_test a_test.sh "$3" "$4" "$2" : CAP-1.1
  _pt=$(cd "$T" && pwd -P)
  _tr=0
  chk "$1, outer run" 0 "CAP-1.1 tested a_test.sh" || _tr=1
  check_refused "$1, inner run refused" "$T/a_test.sh" "trace.sh: already running the tests in $_pt" || _tr=1
  return $_tr
}

# run_with <TRACE_RUNNING value> <args>...: trace.sh with that value set;
# sets _out and _st, standard error in $TMP/err.
run_with() {
  _v=$1
  shift
  _out=$(env TRACE_RUNNING="$_v" sh "$TRACE" "$@" 2> "$TMP/err" < /dev/null)
  _st=$?
}

# check_last <label> <status> <stdout>: the last run_with gave those.
check_last() {
  if [ "$_st" -eq "$2" ] && [ "$_out" = "$3" ]; then
    ok "$1"
    return 0
  fi
  not_ok "$1: got '$_out' status $_st, expected '$3' status $2"
  return 1
}

# check_err_is <label> <text>: standard error is exactly that one line.
check_err_is() {
  if [ "$(cat "$TMP/err")" = "$2" ]; then
    ok "$1"
  else
    not_ok "$1: standard error was '$(cat "$TMP/err")'"
  fi
}

# check_line <label> <file> <line>: the file holds the line as a whole line.
check_line() {
  if grep -x -F -q -- "$3" "$2" 2> /dev/null; then
    ok "$1"
  else
    not_ok "$1: '$3' is not a line of $2"
  fi
}

# check_nocr <label>: no carriage return on standard error.
check_nocr() {
  if grep -q "$CR" "$TMP/err"; then
    not_ok "$1: carriage return on standard error"
  else
    ok "$1"
  fi
}

LOC=$(pick_locale en_US.UTF-8 $(locale -a 2> /dev/null | grep -i 'utf-\{0,1\}8'))

# ---- TRACE-1.1: Every scenario

fx 11a
mkspec a CAP-1.1 CAP-1.2
mkspec b OTH-1.1
chk_ids "TRACE-1.1: a, every scenario of every spec in order" 1 "$(lines CAP-1.1 CAP-1.2 OTH-1.1)"

fx 11b
mkspec b OTH-1.1
mkspec a CAP-1.2 CAP-1.1
chk_ids "TRACE-1.1: b, spec folders by name and scenarios in file order" 1 "$(lines CAP-1.2 CAP-1.1 OTH-1.1)"

fx 11c
mkspec a CAP-1.1
mkdir "$S/b"
printf '# Title\n\n### Requirement OTH-1: R\n\n## Retired scenario IDs\n\n- OTH-1.1\n' > "$S/b/spec.md"
chk_ids "TRACE-1.1: c, no line for a requirement or a spec without scenarios" 1 "CAP-1.1"

fx 11d
mkspec a CAP-1.1
echo '- see Scenario CAP-9.9 for more' >> "$S/a/spec.md"
printf '#### Scenario CAP-8.8: Not a spec\n' > "$S/README.md"
chk_ids "TRACE-1.1: d, prose and loose files are not scenarios" 1 "CAP-1.1"

fx 11e
mkspec a CAP-1.1 CAP-1.2
mkspec b OTH-1.1
tocrlf "$S/a/spec.md" "$S/b/spec.md"
chk_ids "TRACE-1.1: e, CRLF specs give the same IDs and no CR" 1 "$(lines CAP-1.1 CAP-1.2 OTH-1.1)"

# ---- TRACE-1.2: Template left out

fx 12a
mkspec _template CAP-1.1 CAP-1.2 CAP-2.1
mkspec real "OTH-1.1|not yet: r"
chk "TRACE-1.2: a, the template has no lines" 0 "OTH-1.1 not-yet r"

fx 12b
mkspec _template CAP-1.1 CAP-1.2 CAP-2.1
mkspec real "OTH-1.1|not yet: r"
mkcheck a_test.sh 0 "ok CAP-1.1"
chk "TRACE-1.2: b, a test naming a template ID adds nothing" 0 "OTH-1.1 not-yet r"

fx 12c
mkspec _template CAP-1.1
chk "TRACE-1.2: c, only a template gives no output" 0 ""

# ---- TRACE-1.3: Malformed scenario heading

fx 13a
mkspec a "CAP-1.1|not yet: r"
echo '#### Scenario CAP-1.2 S' >> "$S/a/spec.md"
chk "TRACE-1.3: a, a heading without a colon gives no line and fails" 1 "CAP-1.1 not-yet r"
check_err "TRACE-1.3: a, standard error names the file and line" "a/spec.md:13: not a scenario heading: #### Scenario CAP-1.2 S"

fx 13b
mkspec a "CAP-1.1|not yet: r"
echo '#### Scenario C4P-1.2: S' >> "$S/a/spec.md"
chk "TRACE-1.3: b, a prefix with a digit is malformed" 1 "CAP-1.1 not-yet r"
check_err "TRACE-1.3: b, standard error names it" "not a scenario heading: #### Scenario C4P-1.2: S"

fx 13c
mkspec a "CAP-1.1|not yet: r"
echo '#### Scenarios' >> "$S/a/spec.md"
chk "TRACE-1.3: c, another heading is not malformed" 0 "CAP-1.1 not-yet r"

fx 13d
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' '####  Scenario CAP-1.2: two spaces' '### Scenario CAP-1.3: level' '#### Scenario: CAP-1.4 colon first' "####$(printf '\t')Scenario CAP-1.5: tab" >> "$S/a/spec.md"
chk "TRACE-1.3: d, near misses at any level are malformed" 1 "CAP-1.1 not-yet r"
check_err "TRACE-1.3: d, two spaces named" "a/spec.md:13: not a scenario heading"
check_err "TRACE-1.3: d, wrong level named" "a/spec.md:14: not a scenario heading"
check_err "TRACE-1.3: d, colon first named" "a/spec.md:15: not a scenario heading"
check_err "TRACE-1.3: d, tab named" "a/spec.md:16: not a scenario heading"

# ---- TRACE-1.4: Code blocks left out

fx 14a
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' '```' '#### Scenario EX-1.1: S' '#### Scenario bad' '```' '' '**Verified by:** [run](https://example.org/9)' >> "$S/a/spec.md"
chk "TRACE-1.4: a, headings in a fenced block are not scenarios" 0 "CAP-1.1 not-yet r"

fx 14b
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' '~~~' '#### Scenario EX-1.1: S' '~~~' >> "$S/a/spec.md"
chk "TRACE-1.4: b, a tilde fence too" 0 "CAP-1.1 not-yet r"

fx 14c
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' '~~~md' '```sh' 'echo hi' '~~~' '' '#### Scenario CAP-1.2: After' '' '**Verified by:** not yet: s' >> "$S/a/spec.md"
chk "TRACE-1.4: c, the other fence character does not close a block" 0 "$(lines 'CAP-1.1 not-yet r' 'CAP-1.2 not-yet s')"

fx 14d
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' '````' '```' '#### Scenario EX-1.1: S' '```' '````' >> "$S/a/spec.md"
chk "TRACE-1.4: d, a shorter fence does not close a block" 0 "CAP-1.1 not-yet r"

# ---- TRACE-1.5: Duplicate scenario ID

fx 15a
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' '#### Scenario CAP-1.1: Copy' >> "$S/a/spec.md"
chk "TRACE-1.5: a, an ID used twice in a file fails" 1 "$(lines 'CAP-1.1 not-yet r' 'CAP-1.1 uncovered -')"
check_err "TRACE-1.5: a, standard error names both places" "a/spec.md:13: duplicate scenario ID CAP-1.1, first at"

fx 15b
mkspec a "CAP-1.1|not yet: r"
mkspec b "CAP-1.1|not yet: s"
chk_ids "TRACE-1.5: b, an ID used in two files fails" 1 "$(lines CAP-1.1 CAP-1.1)"
check_err "TRACE-1.5: b, standard error names the second file" "b/spec.md:5: duplicate scenario ID CAP-1.1"

fx 15c
mkspec a CAP-1.1
mkspec b "CAP-1.1|not yet: s"
chk "TRACE-1.5: c, each heading keeps its own Verified by line" 1 "$(lines 'CAP-1.1 uncovered -' 'CAP-1.1 not-yet s')"

# ---- TRACE-1.6: Code block not closed

fx 16a
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' '```sh' '#### Scenario CAP-1.2: Hidden' >> "$S/a/spec.md"
chk "TRACE-1.6: a, an open code block at the end of a file fails" 1 "CAP-1.1 not-yet r"
check_err "TRACE-1.6: a, standard error names where it opened" "a/spec.md:13: code block not closed"

fx 16b
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' '```sh' 'echo' '  ```' '#### Scenario CAP-1.2: After' '' '**Verified by:** not yet: s' >> "$S/a/spec.md"
chk "TRACE-1.6: b, a closing fence indented up to three spaces closes" 0 "$(lines 'CAP-1.1 not-yet r' 'CAP-1.2 not-yet s')"

fx 16c
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' '```foo``` text' '#### Scenario CAP-1.2: After' '' '**Verified by:** not yet: s' >> "$S/a/spec.md"
chk "TRACE-1.6: c, inline code at the start of a line is not a fence" 0 "$(lines 'CAP-1.1 not-yet r' 'CAP-1.2 not-yet s')"

fx 16d
mkspec a "CAP-1.1|not yet: r"
# The blank line before the four-space line ends the Verified by paragraph:
# without it the line would be a continuation of the paragraph (TRACE-3.4 s).
printf '%s\n' '   #### Scenario CAP-1.2: Three' '' '**Verified by:** not yet: s' '' '    #### Scenario CAP-1.3: Four' >> "$S/a/spec.md"
chk "TRACE-1.6: d, a heading indented up to three spaces counts, four does not" 0 "$(lines 'CAP-1.1 not-yet r' 'CAP-1.2 not-yet s')"

# ---- TRACE-1.7: Heading in another case

fx 17a
mkspec a "CAP-1.1|not yet: r"
echo '#### scenario CAP-1.2: Name' >> "$S/a/spec.md"
chk "TRACE-1.7: a, lower case scenario is malformed" 1 "CAP-1.1 not-yet r"
check_err "TRACE-1.7: a, standard error names it" "a/spec.md:13: not a scenario heading: #### scenario CAP-1.2: Name"

fx 17b
mkspec a "CAP-1.1|not yet: r"
echo '#### SCENARIO CAP-1.2: Name' >> "$S/a/spec.md"
chk "TRACE-1.7: b, upper case SCENARIO is malformed" 1 "CAP-1.1 not-yet r"
check_err "TRACE-1.7: b, standard error names it" "a/spec.md:13: not a scenario heading: #### SCENARIO CAP-1.2: Name"

fx 17c
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' '#### ScEnArIo CAP-1.2: Mixed' '### scenario CAP-1.3: Level' '#### scenario' "####${TAB}SCENARIO CAP-1.4: Tab" >> "$S/a/spec.md"
chk "TRACE-1.7: c, mixed case, other level, bare word and tab are malformed" 1 "CAP-1.1 not-yet r"
check_err "TRACE-1.7: c, mixed case named" "a/spec.md:13: not a scenario heading"
check_err "TRACE-1.7: c, other level named" "a/spec.md:14: not a scenario heading"
check_err "TRACE-1.7: c, bare word named" "a/spec.md:15: not a scenario heading"
check_err "TRACE-1.7: c, tab named" "a/spec.md:16: not a scenario heading"

fx 17d
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' '#### Scenarios' '#### scenarios' '#### SCENARIOS' >> "$S/a/spec.md"
chk "TRACE-1.7: d, a heading about scenarios in any case is prose" 0 "CAP-1.1 not-yet r"
if [ ! -s "$TMP/err" ]; then
  ok "TRACE-1.7: d, nothing on standard error"
else
  not_ok "TRACE-1.7: d, standard error was '$(cat "$TMP/err")'"
fi

fx 17e
mkspec a CAP-1.1
printf '%s\n' '#### scenario CAP-1.2: Name' '' '**Verified by:** [run](https://example.org/1)' >> "$S/a/spec.md"
chk "TRACE-1.7: e, a malformed heading ends the scope of the one above" 1 "CAP-1.1 uncovered -"

fx 17f
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' '```' '#### scenario CAP-1.2: Name' '#### SCENARIO CAP-1.3: Name' '```' >> "$S/a/spec.md"
chk "TRACE-1.7: f, a code block is skipped" 0 "CAP-1.1 not-yet r"
if [ ! -s "$TMP/err" ]; then
  ok "TRACE-1.7: f, nothing on standard error"
else
  not_ok "TRACE-1.7: f, standard error was '$(cat "$TMP/err")'"
fi

fx 17g
mkspec a "CAP-1.1|not yet: r"
echo '#### scenario CAP-1.2: Name' >> "$S/a/spec.md"
tocrlf "$S/a/spec.md"
chk "TRACE-1.7: g, CRLF spec gives the same line" 1 "CAP-1.1 not-yet r"
check_err "TRACE-1.7: g, standard error names it" "a/spec.md:13: not a scenario heading: #### scenario CAP-1.2: Name"
check_nocr "TRACE-1.7: g, no carriage return on standard error"

# ---- TRACE-1.8: Byte order in any locale

# t18a <label> <line 1> <line 2>: spec folders B (OTH-1.1) and a (CAP-1.1).
t18a() {
  fx 18a
  mkspec B "OTH-1.1|not yet: r"
  mkspec a "CAP-1.1|not yet: s"
  loc_chk "$1" 0 "$(lines "$2" "$3")"
}

if [ -n "$LOC" ]; then
  t18a "TRACE-1.8: a, B before a under $LOC" 'OTH-1.1 not-yet r' 'CAP-1.1 not-yet s'
else
  t18a "TRACE-1.8: a, B before a (no locale found in which the glob puts a before B; checked in the current locale)" 'OTH-1.1 not-yet r' 'CAP-1.1 not-yet s'
fi

fx 18b
mkspec a CAP-1.1
mkcheck B_test.sh 0 "ok CAP-1.1"
mkcheck a_test.sh 0 "ok CAP-1.1"
loc_chk "TRACE-1.8: b, the first test file in byte order is the source${LOC:+ under $LOC}" 0 "CAP-1.1 tested B_test.sh"

if [ -z "$(pick_locale C POSIX)" ]; then
  ok "TRACE-1.8: c, the locale picker rejects C and POSIX"
else
  not_ok "TRACE-1.8: c, the locale picker rejects C and POSIX: picked '$(pick_locale C POSIX)'"
fi

# ---- TRACE-2.1: Passing check

fx 21a
mkspec a CAP-1.1
mkcheck a_test.sh 0 "ok CAP-1.1"
chk "TRACE-2.1: a, passing check is tested" 0 "CAP-1.1 tested a_test.sh"

fx 21b
mkspec a CAP-1.1 CAP-1.2
mktest a_test.sh "echo 'ok CAP-1.1: works'" "echo '2 passed, 0 failed'" 'exit 0'
mkcheck b_test.sh 0 "ok CAP-1.2"
chk "TRACE-2.1: b, each line names its own file" 0 "$(lines 'CAP-1.1 tested a_test.sh' 'CAP-1.2 tested b_test.sh')"

fx 21c
mkspec a CAP-1.1
mkcheck a_test.sh 0 "ok CAP-1.1"
mkcheck b_test.sh 0 "ok CAP-1.1"
chk "TRACE-2.1: c, first file in sorted order is the source" 0 "CAP-1.1 tested a_test.sh"

fx 21d
mkspec a CAP-1.1
mktest a_test.sh "printf 'ok CAP-1.1: works\\r\\n'" 'exit 0'
chk "TRACE-2.1: d, CRLF check line" 0 "CAP-1.1 tested a_test.sh"

fx 21e
mkspec a CAP-1.1
mktest a_test.sh "echo 'ok   CAP-1.1: works'" 'exit 0'
chk "TRACE-2.1: e, several spaces after ok" 0 "CAP-1.1 tested a_test.sh"

fx 21f
mkspec a CAP-1.1 CAP-1.10
mkcheck a_test.sh 0 "ok CAP-1.10"
chk "TRACE-2.1: f, IDs match exactly" 1 "$(lines 'CAP-1.1 uncovered -' 'CAP-1.10 tested a_test.sh')"

fx 21g
mkspec a CAP-1.1
mkcheck a_test.sh 0 "ok CAP-1.1" "ok NOPE-9.9"
chk "TRACE-2.1: g, an unknown ID adds no line" 0 "CAP-1.1 tested a_test.sh"

fx 21h
mkspec a CAP-1.1
mktest a_test.sh "echo 'ok CAP-1.1 works'" 'exit 0'
mktest b_test.sh "echo ' ok CAP-1.1: works'" 'exit 0'
chk "TRACE-2.1: h, no colon or an indent is not a check line" 1 "CAP-1.1 uncovered -"

# ---- TRACE-2.2: Failing check

fx 22a
mkspec a CAP-1.1
mkcheck a_test.sh 1 "FAIL CAP-1.1"
chk "TRACE-2.2: a, FAIL line is failing" 1 "CAP-1.1 failing a_test.sh"

fx 22b
mkspec a CAP-1.1
mkcheck a_test.sh 1 "ok CAP-1.1"
chk "TRACE-2.2: b, ok line but non-zero exit is failing" 1 "CAP-1.1 failing a_test.sh"

fx 22c
mkspec a CAP-1.1
mkcheck a_test.sh 0 "FAIL CAP-1.1"
chk "TRACE-2.2: c, FAIL line with exit 0 is failing" 1 "CAP-1.1 failing a_test.sh"

fx 22d
mkspec a CAP-1.1
mkcheck a_test.sh 0 "ok CAP-1.1"
mkcheck b_test.sh 1 "FAIL CAP-1.1"
chk "TRACE-2.2: d, failing wins over passing" 1 "CAP-1.1 failing b_test.sh"

fx 22e
mkspec a CAP-1.1
mkcheck a_test.sh 1 "FAIL CAP-1.1"
mkcheck b_test.sh 0 "ok CAP-1.1"
chk "TRACE-2.2: e, source is the failing file, not the first" 1 "CAP-1.1 failing a_test.sh"

fx 22f
mkspec a CAP-1.1 CAP-1.2
mkcheck a_test.sh 1 "ok CAP-1.1" "FAIL CAP-1.2"
chk "TRACE-2.2: f, every scenario the file names fails" 1 "$(lines 'CAP-1.1 failing a_test.sh' 'CAP-1.2 failing a_test.sh')"

fx 22g
mkspec a "CAP-1.1|[run]($U1)"
mkcheck a_test.sh 1 "FAIL CAP-1.1"
chk "TRACE-2.2: g, failing wins over a Verified by line" 1 "CAP-1.1 failing a_test.sh"

fx 22h
mkspec a CAP-1.1
mktest a_test.sh "printf 'FAIL CAP-1.1: broken\\r\\n'" 'exit 1'
chk "TRACE-2.2: h, CRLF FAIL line" 1 "CAP-1.1 failing a_test.sh"

fx 22i
mkspec a CAP-1.1
mktest a_test.sh "echo 'FAIL  CAP-1.1: broken'" 'exit 0'
mkcheck b_test.sh 0 "ok CAP-1.1"
chk "TRACE-2.2: i, FAIL with several spaces is failing" 1 "CAP-1.1 failing a_test.sh"

# ---- TRACE-2.3: ID named but not checked

fx 23a
mkspec a CAP-1.1
mktest a_test.sh '# CAP-1.1 is checked below' 'exit 0'
chk "TRACE-2.3: a, a comment naming the ID is not a check" 1 "CAP-1.1 uncovered -"

fx 23b
mkspec a CAP-1.1
mktest a_test.sh '# ok CAP-1.1: works' 'exit 0'
chk "TRACE-2.3: b, a commented ok line is not a check" 1 "CAP-1.1 uncovered -"

fx 23c
mkspec a CAP-1.1
mktest a_test.sh 'if false; then echo "ok CAP-1.1: works"; fi' 'exit 0'
chk "TRACE-2.3: c, the file is run, not grepped" 1 "CAP-1.1 uncovered -"

fx 23d
mkspec a CAP-1.1
mktest a_test.sh 'echo "checking CAP-1.1"' 'echo "skipped: ok CAP-1.1: works"' 'exit 0'
chk "TRACE-2.3: d, a line not starting with ok is not a check" 1 "CAP-1.1 uncovered -"

fx 23e
mkspec a CAP-1.1
mktest a_test.sh '# CAP-1.1 mentioned here' 'exit 0'
mkcheck b_test.sh 0 "ok CAP-1.1"
chk "TRACE-2.3: e, a mention does not hide a real check" 0 "CAP-1.1 tested b_test.sh"

# ---- TRACE-3.1: Evidence

fx 31a
mkspec a "CAP-1.1|[fixture run]($U1)"
chk "TRACE-3.1: a, Verified by line is evidence" 0 "CAP-1.1 evidence [fixture run]($U1)"

fx 31b
mkspec a "CAP-1.1|[fixture run]($U1)"
mkcheck a_test.sh 0 "ok CAP-1.1"
chk "TRACE-3.1: b, a passing check beats the line" 0 "CAP-1.1 tested a_test.sh"

fx 31c
mkspec a "CAP-1.1|[fixture run]($U1)"
tocrlf "$S/a/spec.md"
chk "TRACE-3.1: c, CRLF spec gives no CR" 0 "CAP-1.1 evidence [fixture run]($U1)"

fx 31d
mkspec a CAP-1.1 "CAP-1.2|[run](https://example.org/2)"
chk "TRACE-3.1: d, the line belongs to the heading above it" 1 "$(lines 'CAP-1.1 uncovered -' 'CAP-1.2 evidence [run](https://example.org/2)')"

fx 31e
mkdir "$S/a"
printf '# Spec\n\n### Requirement CAP-1: R\n\n**Verified by:** [run](https://example.org/3)\n\n#### Scenario CAP-1.1: S\n\n- GIVEN g\n' > "$S/a/spec.md"
chk "TRACE-3.1: e, a line above the scenario heading belongs to none" 1 "CAP-1.1 uncovered -"

fx 31f
mkspec a "CAP-1.1|   [run]($U1)   "
chk "TRACE-3.1: f, the text is trimmed" 0 "CAP-1.1 evidence [run]($U1)"

fx 31g
mkspec a CAP-1.1
mkspec b "OTH-1.1|[run](https://example.org/4)"
chk "TRACE-3.1: g, a line in the next file does not reach back" 1 "$(lines 'CAP-1.1 uncovered -' 'OTH-1.1 evidence [run](https://example.org/4)')"

fx 31h
mkspec a CAP-1.1
mkspec b OTH-1.1
printf 'Verified by: [run](%s)\n' "$U1" >> "$S/a/spec.md"
printf ' **Verified by:** [run](%s)\n' "$U1" >> "$S/b/spec.md"
chk "TRACE-3.1: h, no bold or an indent is not a Verified by line" 1 "$(lines 'CAP-1.1 uncovered -' 'OTH-1.1 uncovered -')"

fx 31i
mkdir "$S/a"
printf '#### Scenario CAP-1.1: S\n\n#66 tracks this\n\n**Verified by:** [run](%s)\n' "$U1" > "$S/a/spec.md"
chk "TRACE-3.1: i, a # line that is not a heading keeps the scope" 0 "CAP-1.1 evidence [run]($U1)"

fx 31j
mkspec a "CAP-1.1|"
printf '**Verified by:** [run](%s)\n' "$U1" >> "$S/a/spec.md"
chk "TRACE-3.1: j, an empty line does not hide the next one" 0 "CAP-1.1 evidence [run]($U1)"

fx 31k
NONL=1 hand a "**Verified by:** [run]($U1)"
chk "TRACE-3.1: k, the end of the file ends the paragraph" 0 "CAP-1.1 evidence [run]($U1)"

# ---- TRACE-3.4: Wrapped Verified by paragraph

fx 34a
mkspec a "CAP-1.1|not yet: waits for the stub${NL}and the review, #66"
chk "TRACE-3.4: a, a wrapped not yet paragraph" 0 "CAP-1.1 not-yet waits for the stub and the review, #66"

fx 34b
mkspec a "CAP-1.1|see [fixture${NL}run]($U1)"
chk "TRACE-3.4: b, a link split over two lines counts" 0 "CAP-1.1 evidence see [fixture run]($U1)"

fx 34c
mkspec a "CAP-1.1|[run](${NL}$U1)"
chk "TRACE-3.4: c, joined with one space, nothing removed" 0 "CAP-1.1 evidence [run]( $U1)"

fx 34d
mkspec a "CAP-1.1|not yet: a${NL}b${NL}c"
chk "TRACE-3.4: d, any number of lines" 0 "CAP-1.1 not-yet a b c"

fx 34e
mkspec a "CAP-1.1|not yet: first   ${NL}    second line  "
chk "TRACE-3.4: e, pieces trimmed and joined by one space" 0 "CAP-1.1 not-yet first second line"

fx 34f
mkspec a "CAP-1.1|not${NL}yet: r"
chk "TRACE-3.4: f, not yet split over the lines still starts the text" 0 "CAP-1.1 not-yet r"

fx 34g
mkspec a "CAP-1.1|[run]($U1)${NL}not yet reviewed"
chk "TRACE-3.4: g, starts with a link, so evidence" 0 "CAP-1.1 evidence [run]($U1) not yet reviewed"

fx 34h
mkspec a "CAP-1.1|${NL}[run]($U1)"
chk "TRACE-3.4: h, the label alone on its line leaves no leading space" 0 "CAP-1.1 evidence [run]($U1)"

fx 34i
mkspec a "CAP-1.1|not yet: a${NL}b"
printf '%s\n' "**Verified by:** [run]($U1)" >> "$S/a/spec.md"
chk "TRACE-3.4: i, the first non-empty paragraph wins" 0 "CAP-1.1 not-yet a b"

fx 34j
mkspec a "CAP-1.1|not yet: waits for the stub${NL}and the review, #66"
tocrlf "$S/a/spec.md"
chk "TRACE-3.4: j, CRLF spec gives no carriage return" 0 "CAP-1.1 not-yet waits for the stub and the review, #66"

fx 34k
NONL=1 hand a '**Verified by:** not yet: a' 'b'
chk "TRACE-3.4: k, the end of the file ends the paragraph" 0 "CAP-1.1 not-yet a b"

fx 34l
mkspec a "CAP-1.1|see the${NL}pull request"
chk "TRACE-3.4: l, wrapped text with neither a link nor not yet is no paragraph" 1 "CAP-1.1 uncovered -"

fx 34m
mkspec a "CAP-1.1|not yet: r"
printf '%s\n' "see [run]($U1)" >> "$S/a/spec.md"
chk "TRACE-3.4: m, a blank line ends the paragraph" 0 "CAP-1.1 not-yet r"

fx 34n
mkspec a "CAP-1.1|TODO"
printf '%s\n' "[run]($U1)" >> "$S/a/spec.md"
chk "TRACE-3.4: n, later prose is not a paragraph of the scenario" 1 "CAP-1.1 uncovered -"

fx 34o
hand a '**Verified by:** not yet: r' "   $TAB" "[run]($U1)"
chk "TRACE-3.4: o, a line of only spaces and tabs is blank" 0 "CAP-1.1 not-yet r"

fx 34p
hand a '**Verified by:** not yet: r' '#### Scenario CAP-1.2: S'
chk "TRACE-3.4: p, a scenario heading ends the paragraph" 1 "$(lines 'CAP-1.1 not-yet r' 'CAP-1.2 uncovered -')"

fx 34q
hand a '**Verified by:** not yet: r' '## Other heading' '' "**Verified by:** [run]($U1)"
chk "TRACE-3.4: q, a heading of any level ends it" 0 "CAP-1.1 not-yet r"

fx 34r
hand a '**Verified by:** not yet: r' '```sh' '#### Scenario EX-1.1: S' '```' "tail [run]($U1)"
chk "TRACE-3.4: r, a backtick fence ends the paragraph" 0 "CAP-1.1 not-yet r"
fx 34r2
hand a '**Verified by:** not yet: r' '~~~sh' '#### Scenario EX-1.1: S' '~~~' "tail [run]($U1)"
chk "TRACE-3.4: r, a tilde fence ends the paragraph" 0 "CAP-1.1 not-yet r"

fx 34s
hand a '**Verified by:** not yet: r' '   #### Scenario CAP-1.2: S'
chk "TRACE-3.4: s, a heading indented three spaces ends the paragraph" 1 "$(lines 'CAP-1.1 not-yet r' 'CAP-1.2 uncovered -')"
fx 34s2
hand a '**Verified by:** not yet: r' '    #### Scenario CAP-1.2: S'
chk "TRACE-3.4: s, four spaces is a continuation line" 0 "CAP-1.1 not-yet r #### Scenario CAP-1.2: S"

fx 34t
hand a '**Verified by:** not yet: waits' '#66 tracks this'
chk "TRACE-3.4: t, a # line that is not a heading is joined" 0 "CAP-1.1 not-yet waits #66 tracks this"

fx 34u
mkspec a "CAP-1.1|[run]($U1)${NL}more"
mkcheck a_test.sh 0 "ok CAP-1.1"
chk "TRACE-3.4: u, a passing check beats the paragraph" 0 "CAP-1.1 tested a_test.sh"

# ---- TRACE-3.2: Not yet

fx 32a
mkspec a "CAP-1.1|not yet: needs a gh stub, #1"
chk "TRACE-3.2: a, not yet with a reason" 0 "CAP-1.1 not-yet needs a gh stub, #1"

fx 32b
mkspec a "CAP-1.1|not yet"
chk "TRACE-3.2: b, not yet without a reason" 0 "CAP-1.1 not-yet -"

fx 32c
mkspec a "CAP-1.1|not yet: r"
mkcheck a_test.sh 0 "ok CAP-1.1"
chk "TRACE-3.2: c, a passing check beats not yet" 0 "CAP-1.1 tested a_test.sh"

fx 32d
mkspec a "CAP-1.1|[run]($U1), not yet reviewed"
chk "TRACE-3.2: d, not yet counts only at the start" 0 "CAP-1.1 evidence [run]($U1), not yet reviewed"

fx 32e
mkspec a "CAP-1.1|not yet: needs a gh stub, #1"
tocrlf "$S/a/spec.md"
chk "TRACE-3.2: e, CRLF spec gives no CR" 0 "CAP-1.1 not-yet needs a gh stub, #1"

fx 32f
mkspec a "CAP-1.1|Not yet: later" "CAP-1.2|NOT YET"
chk "TRACE-3.2: f, not yet in any case" 0 "$(lines 'CAP-1.1 not-yet later' 'CAP-1.2 not-yet -')"

# ---- TRACE-3.3: Neither evidence nor not yet

fx 33a
mkspec a "CAP-1.1|TODO" "CAP-1.2|see the pull request" "CAP-1.3|[run]" "CAP-1.4|notyet"
chk "TRACE-3.3: a, text without a link covers nothing" 1 "$(lines 'CAP-1.1 uncovered -' 'CAP-1.2 uncovered -' 'CAP-1.3 uncovered -' 'CAP-1.4 uncovered -')"

fx 33b
mkspec a "CAP-1.1|see [run]($U1)"
chk "TRACE-3.3: b, a link anywhere in the text is evidence" 0 "CAP-1.1 evidence see [run]($U1)"

# ---- TRACE-4.1: Uncovered scenario

fx 41a
mkspec a CAP-1.1
mkcheck a_test.sh 0 "ok OTH-1.1"
chk "TRACE-4.1: a, nothing shows the scenario holds" 1 "CAP-1.1 uncovered -"

fx 41b
mkspec a "CAP-1.1|[run]($U1)" CAP-1.2
chk "TRACE-4.1: b, an empty tests folder hides no scenario" 1 "$(lines "CAP-1.1 evidence [run]($U1)" 'CAP-1.2 uncovered -')"
if [ ! -s "$TMP/err" ]; then
  ok "TRACE-4.1: b, nothing on standard error"
else
  not_ok "TRACE-4.1: b, standard error was '$(cat "$TMP/err")'"
fi

fx 41c
mkspec a CAP-1.1 CAP-1.2
mktest helper.sh "echo 'ok CAP-1.1: works'" 'exit 0'
mktest x_test.txt "echo 'ok CAP-1.1: works'" 'exit 0'
chk "TRACE-4.1: c, only *_test.sh files count" 1 "$(lines 'CAP-1.1 uncovered -' 'CAP-1.2 uncovered -')"

fx 41d
mkspec a "CAP-1.1|" "CAP-1.2|   "
chk "TRACE-4.1: d, an empty Verified by line covers nothing" 1 "$(lines 'CAP-1.1 uncovered -' 'CAP-1.2 uncovered -')"

# ---- TRACE-4.2: Every scenario covered

fx 42a
mkspec a CAP-1.1 "CAP-1.2|[run]($U1)" "CAP-1.3|not yet: r"
mkcheck a_test.sh 0 "ok CAP-1.1"
chk "TRACE-4.2: a, tested, evidence and not-yet exit 0" 0 "$(lines 'CAP-1.1 tested a_test.sh' "CAP-1.2 evidence [run]($U1)" 'CAP-1.3 not-yet r')"

fx 42b
mkspec a "CAP-1.1|not yet: r"
chk "TRACE-4.2: b, only not-yet exits 0" 0 "CAP-1.1 not-yet r"

fx 42c
chk "TRACE-4.2: c, empty folders give no output and exit 0" 0 ""

fx 42d
mkspec a CAP-1.1 "CAP-1.2|[run]($U1)" "CAP-1.3|not yet: r"
mkcheck a_test.sh 0 "ok CAP-1.1"
mktest b_test.sh 'exit 1'
chk "TRACE-4.2: d, a failing file that names nothing fails the run" 1 "$(lines 'CAP-1.1 tested a_test.sh' "CAP-1.2 evidence [run]($U1)" 'CAP-1.3 not-yet r')"

fx 42e
mkspec a CAP-1.1 "CAP-1.2|[run]($U1)" "CAP-1.3|not yet: r"
mkcheck a_test.sh 0 "ok CAP-1.1"
mkcheck b_test.sh 1 "ok NOPE-9.9"
chk "TRACE-4.2: e, a failing file naming an unknown ID fails the run" 1 "$(lines 'CAP-1.1 tested a_test.sh' "CAP-1.2 evidence [run]($U1)" 'CAP-1.3 not-yet r')"

# ---- TRACE-4.3: Failing test file named

fx 43a
mkspec a "CAP-1.1|not yet: r"
mktest a_test.sh 'echo setup broke >&2' 'exit 3'
mkcheck b_test.sh 0 "ok OTH-1.1"
chk "TRACE-4.3: a, a test file that exits non-zero fails the run" 1 "CAP-1.1 not-yet r"
check_err "TRACE-4.3: a, standard error names the file and status" "trace.sh: a_test.sh exited 3"
check_err "TRACE-4.3: a, followed by the end of its standard error" "  setup broke"
if grep -q b_test.sh "$TMP/err"; then
  not_ok "TRACE-4.3: b, a passing file is not named: $(cat "$TMP/err")"
else
  ok "TRACE-4.3: b, a passing file is not named"
fi

fx 43c
mkspec a "CAP-1.1|not yet: r"
mktest a_test.sh "echo 'FAIL NOPE-1.1: x'" "echo 'FAIL CAP-1.1 : x'" 'exit 0'
chk "TRACE-4.3: c, a FAIL line no scenario takes still fails the run" 1 "CAP-1.1 not-yet r"
check_err "TRACE-4.3: c, standard error names the file" "trace.sh: a_test.sh printed a FAIL line but exited 0"

# ---- TRACE-5.1: Other folders

fx 51a
mkspec a CAP-1.1
mkcheck a_test.sh 0 "ok CAP-1.1"
mkdir -p "$D/cwd/docs/specs/decoy" "$D/cwd/scripts/tests"
printf '#### Scenario OTH-9.9: Decoy\n' > "$D/cwd/docs/specs/decoy/spec.md"
printf '%s\n' "echo 'FAIL OTH-9.9: decoy'" ': > ran' 'exit 1' > "$D/cwd/scripts/tests/decoy_test.sh"
cd "$D/cwd" || exit 1
chk "TRACE-5.1: a, the folders given are read, not the current directory's" 0 "CAP-1.1 tested a_test.sh"
cd "$HERE" || exit 1
check_no_file "TRACE-5.1: a, the decoy test was not run" "$D/cwd/ran"

fx 51b "my specs" "my tests"
mkspec a CAP-1.1 "CAP-1.2|[run]($U1)"
mkcheck a_test.sh 0 "ok CAP-1.1"
cd "$D" || exit 1
check_run "TRACE-5.1: b, relative folder names with a space" 0 "$(lines 'CAP-1.1 tested a_test.sh' "CAP-1.2 evidence [run]($U1)")" "my specs" "my tests"
cd "$HERE" || exit 1

fx 51c
mkspec a CAP-1.1
mkcheck a_test.sh 0 "ok CAP-1.1"
check_run "TRACE-5.1: c, folders with a trailing slash" 0 "CAP-1.1 tested a_test.sh" "$S/" "$T/"

fx 51d
mkspec a CAP-1.1
mkspec sub/deeper OTH-2.2
mkcheck a_test.sh 0 "ok CAP-1.1"
mkcheck sub/b_test.sh 0 "ok CAP-1.1" "ok OTH-2.2"
chk "TRACE-5.1: d, no recursion" 0 "CAP-1.1 tested a_test.sh"

# ---- TRACE-5.2: Wrong number of arguments

USAGE='trace.sh [<specs> <tests>]'

fx 52a
mkspec a CAP-1.1
mktest a_test.sh ': > "$0.ran"' 'exit 0'
check_run "TRACE-5.2: a, one argument is a usage error" 2 "" "$S"
check_err "TRACE-5.2: a, usage on standard error" "$USAGE"
check_run "TRACE-5.2: b, three arguments are a usage error" 2 "" "$S" "$T" extra
check_err "TRACE-5.2: b, usage on standard error" "$USAGE"
check_run "TRACE-5.2: c, four arguments are a usage error" 2 "" "$S" "$T" extra more
check_err "TRACE-5.2: c, usage on standard error" "$USAGE"
check_no_file "TRACE-5.2: d, no test file was run" "$T/a_test.sh.ran"

# ---- TRACE-5.3: Missing folder

fx 53a
mkspec a "CAP-1.1|not yet: r"
mktest a_test.sh ': > "$0.ran"' 'exit 0'
check_run "TRACE-5.3: a, a missing specs folder exits 2" 2 "" "$D/nope" "$T"
check_err "TRACE-5.3: a, standard error names it" "trace.sh: not a folder: $D/nope"
check_no_file "TRACE-5.3: a, no test file was run" "$T/a_test.sh.ran"
check_run "TRACE-5.3: b, a missing tests folder exits 2" 2 "" "$S" "$D/nope"
check_err "TRACE-5.3: b, standard error names it" "trace.sh: not a folder: $D/nope"
: > "$D/file"
check_run "TRACE-5.3: c, a file is not a folder" 2 "" "$D/file" "$T"

# ---- TRACE-5.4: No run from inside a test

# A copy of trace.sh in a fixture repository, so that a broken guard runs
# the fixture's tests, not this one.
fx 54a
R=$D/repo
mkdir -p "$R/scripts/tests" "$R/docs/specs/a"
cp "$TRACE" "$HERE/../lib.sh" "$R/scripts/"
printf '#### Scenario CAP-1.1: S\n' > "$R/docs/specs/a/spec.md"
printf ': > "$0.ran"\necho "ok CAP-1.1: works"\n' > "$R/scripts/tests/a_test.sh"
_out=$(TRACE_RUNNING=1 sh "$R/scripts/trace.sh" 2> "$TMP/err" < /dev/null)
_st=$?
if [ "$_st" -eq 2 ] && [ -z "$_out" ]; then
  ok "TRACE-5.4: a, no arguments inside a test run exits 2"
else
  not_ok "TRACE-5.4: a, no arguments inside a test run exits 2: got status $_st"
fi
check_err "TRACE-5.4: a, standard error says why" "trace.sh: already running the tests"
check_no_file "TRACE-5.4: a, no test file was run" "$R/scripts/tests/a_test.sh.ran"
_out=$(env -u TRACE_RUNNING sh "$R/scripts/trace.sh" 2> "$TMP/err" < /dev/null)
_st=$?
if [ "$_st" -eq 0 ] && [ "$_out" = "CAP-1.1 tested a_test.sh" ]; then
  ok "TRACE-5.4: c, outside a test run, no arguments read the repository's folders"
else
  not_ok "TRACE-5.4: c, outside a test run, no arguments read the repository's folders: got '$_out' status $_st"
fi
fx 54b
mkspec a "CAP-1.1|not yet: r"
mktest a_test.sh 'printf "%s\n" "$TRACE_RUNNING" > "$0.env"' 'exit 0'
chk "TRACE-5.4: b, folders given still run" 0 "CAP-1.1 not-yet r"
if grep -x -F -q -- "$(cd "$T" && pwd -P)" "$T/a_test.sh.env" 2>/dev/null; then
  ok "TRACE-5.4: b, the tests run with their tests folder in TRACE_RUNNING"
else
  not_ok "TRACE-5.4: b, the tests run with their tests folder in TRACE_RUNNING"
fi

# ---- TRACE-5.5: No rerun of a tests folder from inside a test

fx 55a
t55 "TRACE-5.5: a" sh "$S" "$T"

fx 55b1
t55 "TRACE-5.5: b, tests folder as ../tests" sh "$S" "$T/../tests"
fx 55b2
t55 "TRACE-5.5: b, tests folder with a trailing slash" sh "$S" "$T/"
fx 55b3
t55 "TRACE-5.5: b, tests folder with a trailing /." sh "$S" "$T/."
fx 55b4
t55 "TRACE-5.5: b, tests folder as ./tests" sh "$S" "$D/./tests"

fx 55c
ln -s "$T" "$D/link" 2> /dev/null
if [ -L "$D/link" ]; then
  t55 "TRACE-5.5: c, symbolic link" sh "$S" "$D/link"
else
  ok "TRACE-5.5: c, symbolic link (skipped: no symbolic links here)"
fi

# fx2: a second pair of folders S2 and T2 in the current fixture.
fx2() {
  S2=$D/specs2
  T2=$D/tests2
  mkdir -p "$S2" "$T2"
}

fx 55d
fx2
_s=$S
_t=$T
S=$S2
T=$T2
mkspec b OTH-1.1
mktest b_test.sh 'echo "ok OTH-1.1: works"' ': > "$0.ran"' 'exit 0'
S=$_s
T=$_t
mkspec a CAP-1.1
rerun_test a_test.sh "$S2" "$T2" sh : CAP-1.1
chk "TRACE-5.5: d, outer run" 0 "CAP-1.1 tested a_test.sh"
if [ "$(cat "$T/a_test.sh.st" 2> /dev/null)" = 0 ] && [ "$(cat "$T/a_test.sh.out" 2> /dev/null)" = "OTH-1.1 tested b_test.sh" ] && [ -e "$T2/b_test.sh.ran" ]; then
  ok "TRACE-5.5: d, another tests folder runs its tests"
else
  not_ok "TRACE-5.5: d, another tests folder runs its tests: status '$(cat "$T/a_test.sh.st" 2> /dev/null)', output '$(cat "$T/a_test.sh.out" 2> /dev/null)'"
fi

fx 55e
fx2
_s=$S
_t=$T
S=$S2
T=$T2
mkspec b OTH-1.1
rerun_test b_test.sh "$_s" "$_t" sh 'printf "%s\n" "$TRACE_RUNNING" > "$0.rec"' OTH-1.1
S=$_s
T=$_t
mkspec a CAP-1.1
rerun_test a_test.sh "$S2" "$T2" sh : CAP-1.1
chk "TRACE-5.5: e, outer run" 0 "CAP-1.1 tested a_test.sh"
PT=$(cd "$T" && pwd -P)
PT2=$(cd "$T2" && pwd -P)
check_refused "TRACE-5.5: e, the rerun from the second folder is refused" "$T2/b_test.sh" "trace.sh: already running the tests in $PT"
check_line "TRACE-5.5: e, the value holds the first tests folder" "$T2/b_test.sh.rec" "$PT"
check_line "TRACE-5.5: e, the value holds the second tests folder" "$T2/b_test.sh.rec" "$PT2"
if [ "$(wc -l < "$T/a_test.sh.calls" | tr -d ' ')" = 1 ]; then
  ok "TRACE-5.5: e, the first test ran once"
else
  not_ok "TRACE-5.5: e, the first test ran $(wc -l < "$T/a_test.sh.calls") times"
fi

fx 55f
mkspec a CAP-1.1
mktest a_test.sh 'printf "%s\n" "$TRACE_RUNNING" > "$0.rec"' 'echo "ok CAP-1.1: works"' 'exit 0'
PT=$(cd "$T" && pwd -P)
run_with /some/other "$S" "$T"
check_last "TRACE-5.5: f, a value from above does not stop an unrelated folder" 0 "CAP-1.1 tested a_test.sh"
check_line "TRACE-5.5: f, the value from above is kept" "$T/a_test.sh.rec" /some/other
check_line "TRACE-5.5: f, the tests folder is added" "$T/a_test.sh.rec" "$PT"

fx 55g
mkspec a CAP-1.1
mktest a_test.sh ': > "$0.ran"' 'echo "ok CAP-1.1: works"' 'exit 0'
PT=$(cd "$T" && pwd -P)
run_with "/some/other${NL}$PT" "$S" "$T"
check_last "TRACE-5.5: g, the folder as any line of the value is refused" 2 ""
check_err_is "TRACE-5.5: g, standard error is the refusal" "trace.sh: already running the tests in $PT"
check_no_file "TRACE-5.5: g, no test file was run" "$T/a_test.sh.ran"

fx 55h specs "my tests"
t55 "TRACE-5.5: h, a folder with a space" sh "$S" "$T"
fx 55h2 specs "my tests"
mkspec a CAP-1.1
mktest a_test.sh ': > "$0.ran"' 'echo "ok CAP-1.1: works"' 'exit 0'
run_with "$(cd "$D" && pwd -P)/my" "$S" "$T"
check_last "TRACE-5.5: h, a prefix of the folder is no match" 0 "CAP-1.1 tested a_test.sh"
if [ -e "$T/a_test.sh.ran" ]; then
  ok "TRACE-5.5: h, the tests ran"
else
  not_ok "TRACE-5.5: h, the tests did not run"
fi

fx 55i
mkspec a CAP-1.1
run_with "$(cd "$T" && pwd -P)" "$S" "$D/nope"
check_last "TRACE-5.5: i, a missing folder is not a folder, not a rerun" 2 ""
check_err_is "TRACE-5.5: i, standard error is the missing folder message" "trace.sh: not a folder: $D/nope"

# j is 5.4 a, kept: no arguments are refused whatever TRACE_RUNNING holds.
_out=$(TRACE_RUNNING=1 sh "$R/scripts/trace.sh" 2> "$TMP/err" < /dev/null)
_st=$?
if [ "$_st" -eq 2 ] && [ -z "$_out" ]; then
  ok "TRACE-5.5: j, no arguments are refused whatever TRACE_RUNNING holds"
else
  not_ok "TRACE-5.5: j, no arguments are refused: got '$_out' status $_st"
fi
check_err_is "TRACE-5.5: j, the refusal text is TRACE-5.4's" "trace.sh: already running the tests; a test must pass folders"

# ---- Trial break: the helper must be able to fail

fx tb
mkspec a CAP-1.1
mkcheck a_test.sh 1 "FAIL CAP-1.1"
if (chk "trial-break: inner" 0 "CAP-1.1 tested a_test.sh") > /dev/null; then
  not_ok "trial-break: check_run passed on a wrong line"
else
  ok "trial-break: check_run fails on a wrong line"
fi

# TB2: the TRACE-1.8 fixture checked against glob order must fail.
if (t18a "trial-break: inner" 'CAP-1.1 not-yet s' 'OTH-1.1 not-yet r') > /dev/null; then
  not_ok "trial-break: the byte order check passed on the glob order"
else
  ok "trial-break: the byte order check fails on the glob order"
fi

# TB3: with the guard unable to act, the rerun check must fail.
fx tb3
if (t55 "trial-break: inner" "env -u TRACE_RUNNING sh" "$S" "$T") > /dev/null; then
  not_ok "trial-break: the rerun check passed on an unguarded rerun"
else
  ok "trial-break: the rerun check fails on an unguarded rerun"
fi

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

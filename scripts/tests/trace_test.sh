#!/usr/bin/env sh
# Test scripts/trace.sh against the traceability spec.
#
#   sh scripts/tests/trace_test.sh
#
# Covers TRACE-1.1 to TRACE-5.3 in docs/specs/traceability/spec.md; the cases
# are in docs/changes/65-traceability/test-design.md. Each case builds fixture
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
chk "TRACE-1.5: a, an ID used twice in a file fails" 1 "$(lines 'CAP-1.1 not-yet r' 'CAP-1.1 not-yet r')"
check_err "TRACE-1.5: a, standard error names both places" "a/spec.md:13: duplicate scenario ID CAP-1.1, first at"

fx 15b
mkspec a "CAP-1.1|not yet: r"
mkspec b "CAP-1.1|not yet: s"
chk_ids "TRACE-1.5: b, an ID used in two files fails" 1 "$(lines CAP-1.1 CAP-1.1)"
check_err "TRACE-1.5: b, standard error names the second file" "b/spec.md:5: duplicate scenario ID CAP-1.1"

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
mktest a_test.sh 'exit 3'
mkcheck b_test.sh 0 "ok OTH-1.1"
chk "TRACE-4.3: a, a test file that exits non-zero fails the run" 1 "CAP-1.1 not-yet r"
check_err "TRACE-4.3: a, standard error names the file and status" "trace.sh: a_test.sh exited 3"
if grep -q b_test.sh "$TMP/err"; then
  not_ok "TRACE-4.3: b, a passing file is not named: $(cat "$TMP/err")"
else
  ok "TRACE-4.3: b, a passing file is not named"
fi

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

# ---- Trial break: the helper must be able to fail

fx tb
mkspec a CAP-1.1
mkcheck a_test.sh 1 "FAIL CAP-1.1"
if (chk "trial-break: inner" 0 "CAP-1.1 tested a_test.sh") > /dev/null; then
  not_ok "trial-break: check_run passed on a wrong line"
else
  ok "trial-break: check_run fails on a wrong line"
fi

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1

# Shared helpers for the lifecycle scripts. Sourced, not run:
#
#   . "$(dirname "$0")/lib.sh"
#
# Holds only what at least two of stage.sh, risk.sh, and guard.sh use.
# Rules that belong to one script, such as the order of comment and label
# changes, stay in that script. See scripts/README.md.

PROG=$(basename "$0")

# Print the calling script's header comment, without the shebang, and exit 2.
usage() {
  awk 'NR == 1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
  exit 2
}

# in_list <word> <list>: succeed if <word> is one of the words in <list>.
in_list() {
  for _w in $2; do
    [ "$_w" = "$1" ] && return 0
  done
  return 1
}

# require_number <value>: exit 2 unless <value> is a plain issue number.
require_number() {
  case "$1" in
    ''|*[!0-9]*) echo "$PROG: issue must be a number, got '$1'" >&2; exit 2 ;;
  esac
}

# parse_args "$@": set ISSUE, TARGET, and NOTE from <issue> [<target> [note...]].
# Words after the target are joined into the note.
parse_args() {
  [ $# -ge 1 ] || usage
  ISSUE=$1
  require_number "$ISSUE"
  TARGET=${2:-}
  NOTE=""
  if [ $# -ge 3 ]; then
    shift 2
    NOTE="$*"
  fi
}

# check_canonical <kind> <issue> <current> <valid>: exit 1 if any word of
# <current> is not in <valid>.
check_canonical() {
  for _c in $3; do
    if ! in_list "$_c" "$4"; then
      echo "$PROG: issue #$2 carries a non-canonical $1 label; fix it by hand first. Found: $3" >&2
      exit 1
    fi
  done
}

# post_comment <issue> <first-line> [note]: comment with the note, if any,
# below a blank line.
post_comment() {
  _body=$2
  if [ -n "${3:-}" ]; then
    _body="$_body

$3"
  fi
  gh issue comment "$1" --body "$_body" >/dev/null
}

# swap_labels <issue> <remove> <add>: one label edit. <remove> is a
# comma-separated list; either argument may be empty.
swap_labels() {
  _issue=$1
  _remove=$2
  _add=$3
  set --
  if [ -n "$_remove" ]; then
    set -- "$@" --remove-label "$_remove"
  fi
  if [ -n "$_add" ]; then
    set -- "$@" --add-label "$_add"
  fi
  if [ $# -gt 0 ]; then
    gh issue edit "$_issue" "$@" >/dev/null
  fi
}

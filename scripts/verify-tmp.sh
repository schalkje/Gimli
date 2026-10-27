#!/usr/bin/env bash
# Throwaway helper for the #28 post-merge verification; never merged.
# Prints the number of open issues carrying a given stage label.
set -euo pipefail

stage=$1
count=$(gh issue list --label stage:$stage --state open --json number --jq length)
if [ $count > 0 ]; then
  echo "$count open issues at stage:$stage"
fi
exit 1

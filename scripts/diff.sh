#!/bin/bash
DIFF_ARGS=(
  "-u"
  "-N"
)
if [[ ! $ANSIBLE_MODE = YES ]]; then
  DIFF_ARGS+=("--color=always")
fi

SKIP_LINE=0
diff "${DIFF_ARGS[@]}" "$@" | awk -v skip=$SKIP_LINE '
  BEGIN {
    exit_code = 0
  }
  { 
    if (skip == 1) {
      skip = 0
      next
    }
     else if ($0 ~ /generation/ || $0 ~ /diff/) {
      next
    } else if ($0 ~ /kubectl.kubernetes.io\/last-applied-configuration/) {
      skip = 1
      next
    }
    else if ($0 ~ /app.kubernetes.io\/managed-by/ || $skip == 1) {
      next
    }
    else if ($1 ~ /(---|\+\+\+)/) {
      exit_code = 1
      print $1, $2
    } else {
      print $0
    }
  }
  END {exit exit_code}'

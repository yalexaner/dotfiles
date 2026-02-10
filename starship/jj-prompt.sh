#!/bin/sh
# starship custom module: jujutsu (jj) prompt info

case "$1" in
  branch)
    # closest bookmark: on @ or nearest ancestor
    bm=$(jj log -r 'ancestors(@) & bookmarks()' --limit 1 --no-graph -T 'bookmarks.join(", ")' 2>/dev/null)
    [ -n "$bm" ] && printf ' %s' "$bm"
    ;;
  info)
    # status (● dirty / ○ clean) + description first line
    jj log -r @ --no-graph -T 'if(empty, "○", "●") ++ if(description.first_line(), " " ++ description.first_line(), "")' 2>/dev/null
    ;;
esac

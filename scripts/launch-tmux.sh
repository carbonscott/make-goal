#!/usr/bin/env bash
# Start a /goal campaign in its own tmux session, with Remote Control on.
# usage: launch-tmux.sh <slug> [permission-mode]
# Run from the folder that holds .goal/<slug>.json. The session is named
# goal-<slug>; attach with `tmux attach -t goal-<slug>`, or open the
# Remote Control session of the same name from claude.ai or the app.
# MG_TMUX_SOCKET=<name> uses a private tmux server (tmux -L), for tests.
# Exit codes: 0 started · 1 usage · 2 no tmux or claude · 3 session exists
#             4 waiting at the folder-trust prompt · 5 not confirmed in time
set -u
slug=${1:-}; mode=${2:-}
[ -n "$slug" ] || { echo "usage: launch-tmux.sh <slug> [permission-mode]" >&2; exit 1; }
contract=".goal/$slug.json"
goal="/goal work until all done_when conditions are met in @$contract"
fallback() { echo "Start it yourself instead: run claude in $PWD and enter"; echo "  $goal"; }

[ -f "$contract" ] || { echo "no $contract in $PWD" >&2; exit 1; }
for bin in tmux claude; do
  command -v "$bin" >/dev/null || { echo "$bin not found on PATH."; fallback; exit 2; }
done

S="goal-$slug"
T=(tmux); [ -n "${MG_TMUX_SOCKET:-}" ] && T=(tmux -L "$MG_TMUX_SOCKET")
if "${T[@]}" has-session -t "=$S" 2>/dev/null; then
  echo "tmux session $S already exists; not starting a second campaign."
  echo "  attach: ${T[*]} attach -t $S"; fallback; exit 3
fi

args=(claude --name "$S" --remote-control "$S")
[ -n "$mode" ] && args+=(--permission-mode "$mode")
args+=(-- "$goal")
cmd="$(printf '%q ' "${args[@]}"); echo '[claude exited; shell kept open]'; exec bash"
TMUX= LANG=${LANG:-C.UTF-8} "${T[@]}" new-session -d -s "$S" -x 160 -y 45 -c "$PWD" "$cmd" || exit 2

# The /goal line is Claude's first message. Wait for Claude's "Goal set:", or
# report the folder-trust prompt, which this script never answers.
for _ in $(seq 60); do
  sleep 1
  pane=$("${T[@]}" capture-pane -p -t "=$S:" 2>/dev/null) || break
  if grep -q "Yes, I trust this folder" <<<"$pane"; then
    echo "$S is waiting at Claude Code's folder-trust prompt for $PWD."
    echo "Attach (${T[*]} attach -t $S) and choose whether to trust it;"
    echo "if you trust it, the campaign starts on its own."
    exit 4
  fi
  if grep -q "Goal set:" <<<"$pane"; then
    echo "Started $S in $PWD${mode:+ (permission mode: $mode)}."
    echo "  attach:         ${T[*]} attach -t $S"
    rc=""
    for _ in $(seq 15); do   # the Remote Control line follows "Goal set:"
      "${T[@]}" capture-pane -p -t "=$S:" 2>/dev/null | grep -q "remote-control is active" && { rc=1; break; }
      sleep 1
    done
    if [ -n "$rc" ]; then
      echo "  Remote Control: $S (active)"
    else
      echo "  Remote Control: not confirmed on screen; run /remote-control in the session"
    fi
    exit 0
  fi
done
echo "Could not confirm that $S started the campaign. Last screen:"
"${T[@]}" capture-pane -p -t "=$S:" 2>/dev/null | grep -v '^\s*$' | tail -8
exit 5

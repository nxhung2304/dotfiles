#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
home_dir="$work_dir/home"
current_repo="$home_dir/Dev/personal/mobile"
open_repo="$home_dir/Dev/personal/backend"
new_repo="$home_dir/Dev/rights/plugin"
mkdir -p "$work_dir/bin" "$current_repo" "$open_repo" "$new_repo"
git init -q "$current_repo"

workspaces_json='{"result":{"workspaces":[{"workspace_id":"w9","label":"backend","agent_status":"idle"}]}}'

cat >"$work_dir/bin/herdr" <<EOF
#!/usr/bin/env bash
case "\$1 \$2" in
    "pane current") echo '{"result":{"pane":{"cwd":"$current_repo"}}}' ;;
    "workspace list") echo '$workspaces_json' ;;
    "pane list") echo '{"result":{"panes":[{"workspace_id":"w9","cwd":"$open_repo"}]}}' ;;
    "agent list") echo "{\"result\":{\"agents\":[\$(cat "$work_dir/agents")]}}" ;;
    "workspace create") echo '{"result":{"root_pane":{"pane_id":"p42"}}}' ;;
    "pane send-text") echo "\$3 \$4" >>"$work_dir/sent" ;;
esac
EOF
cat >"$work_dir/bin/fzf" <<EOF
#!/usr/bin/env bash
cat >"$work_dir/candidates"
cat "$work_dir/picked"
EOF
printf '#!/usr/bin/env bash\nexit 0\n' >"$work_dir/bin/zoxide"
chmod +x "$work_dir/bin/herdr" "$work_dir/bin/fzf" "$work_dir/bin/zoxide"

pair_with() {
    local picked_repo=$1
    local agents_json=$2
    rm -f "$work_dir/sent"
    echo "$picked_repo" >"$work_dir/picked"
    echo "$agents_json" >"$work_dir/agents"
    echo | PATH="$work_dir/bin:$PATH" HOME="$home_dir" bash "$repo_dir/scripts/herdr/peer-pair" >/dev/null
    cat "$work_dir/sent" 2>/dev/null || echo "nothing"
}

idle_claude='{"workspace_id":"w9","pane_id":"p7","agent":"claude","agent_status":"idle"}'
busy_claude='{"workspace_id":"w9","pane_id":"p7","agent":"claude","agent_status":"working"}'
idle_codex='{"workspace_id":"w9","pane_id":"p5","agent":"codex","agent_status":"idle"}'

new_repo_result=$(pair_with "$new_repo" "")
is_current_repo_offered=false
grep -qx "$current_repo" "$work_dir/candidates" && is_current_repo_offered=true

check "new repo starts a named Claude" "p42 claude -n plugin" "$new_repo_result"
check "current repo is not offered" "false" "$is_current_repo_offered"
check "idle Claude gets renamed" "p7 /rename backend" "$(pair_with "$open_repo" "$idle_claude")"
check "only Claude is renamed next to Codex" "p7 /rename backend" \
    "$(pair_with "$open_repo" "$idle_codex,$idle_claude")"
check "Codex alone gets nothing" "nothing" "$(pair_with "$open_repo" "$idle_codex")"
check "busy Claude gets nothing" "nothing" "$(pair_with "$open_repo" "$busy_claude")"
check "cancelled picker does nothing" "nothing" "$(pair_with "" "")"

finish_tests

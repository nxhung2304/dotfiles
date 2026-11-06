#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin" "$work_dir/home"

cat >"$work_dir/bin/herdr" <<EOF
#!/usr/bin/env bash
case "\$1 \$2" in
    "workspace list") echo '{"result":{"workspaces":[]}}' ;;
    "pane list") echo '{"result":{"panes":[]}}' ;;
    "workspace create") echo '{"result":{"root_pane":{"pane_id":"p1"}}}' ;;
    "pane send-text") echo "\$4" >>"$work_dir/sent" ;;
esac
EOF
printf '#!/usr/bin/env bash\nexit 0\n' >"$work_dir/bin/zoxide"
chmod +x "$work_dir/bin/herdr" "$work_dir/bin/zoxide"

open_project() {
    rm -f "$work_dir/sent"
    PATH="$work_dir/bin:$PATH" HOME="$work_dir/home" bash "$repo_dir/scripts/herdr-sessionizer" "$1"
    cat "$work_dir/sent" 2>/dev/null || echo "nothing"
}

mkdir -p "$work_dir/both" "$work_dir/old-only" "$work_dir/none"
touch "$work_dir/both/.herdr-sessionizer" "$work_dir/both/.tmux-sessionizer" "$work_dir/old-only/.tmux-sessionizer"

check "new hydrate file wins" "source $work_dir/both/.herdr-sessionizer" "$(open_project "$work_dir/both")"
check "old hydrate file still works" "source $work_dir/old-only/.tmux-sessionizer" "$(open_project "$work_dir/old-only")"
check "no hydrate file sends nothing" "nothing" "$(open_project "$work_dir/none")"
touch "$work_dir/home/.herdr-sessionizer"
check "home hydrate file is the fallback" "source $work_dir/home/.herdr-sessionizer" "$(open_project "$work_dir/none")"

finish_tests

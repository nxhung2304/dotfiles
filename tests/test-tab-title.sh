#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin"

cat >"$work_dir/bin/herdr" <<EOF
#!/usr/bin/env bash
case "\$1 \$2" in
    "pane get") echo '{"result":{"pane":{"tab_id":"w1:t1","terminal_title_stripped":"'"\$FAKE_TITLE"'"}}}' ;;
    "tab get") echo '{"result":{"tab":{"label":"'"\$FAKE_LABEL"'"}}}' ;;
    "tab rename") echo "\$3 \$4" >"$work_dir/renamed" ;;
esac
EOF

cat >"$work_dir/bin/claude" <<EOF
#!/usr/bin/env bash
cat >/dev/null
echo called >>"$work_dir/model_calls"
[[ -z "\${FAKE_MODEL_FAIL:-}" ]] || exit 1
echo "\$FAKE_MODEL_OUTPUT"
EOF
chmod +x "$work_dir/bin/herdr" "$work_dir/bin/claude"

run_tab_title() {
    local title=$1 label=$2 herdr_env=${3:-1}
    rm -f "$work_dir/renamed" "$work_dir/model_calls"
    LC_ALL=C PATH="$work_dir/bin:$PATH" HERDR_ENV="$herdr_env" HERDR_PANE_ID=w1:p1 \
        FAKE_TITLE="$title" FAKE_LABEL="$label" FAKE_MODEL_OUTPUT="${FAKE_MODEL_OUTPUT:-}" \
        bash "$repo_dir/scripts/herdr/tab-title" </dev/null
    cat "$work_dir/renamed" 2>/dev/null || echo "not renamed"
}

model_calls() {
    cat "$work_dir/model_calls" 2>/dev/null || echo "no model call"
}

check "renames an unnamed tab with a kebab-case title" \
    "w1:t1 c-fix-login-bug" "$(run_tab_title "Fix login bug" "c")"
run_tab_title "Fix login bug" "c" >/dev/null
check "does not call the model for an English title" "no model call" "$(model_calls)"

check "keeps at most four words" \
    "w1:t1 c-add-automatic-tab-rename" "$(run_tab_title "Add automatic tab rename hook for herdr" "c")"

check "keeps the last word when the cut lands on a word boundary" \
    "w1:t1 c-flutter-tools-statusline" "$(run_tab_title "flutter tools statusline neovim" "c")"

check "translates a non-English title through the model" \
    "w1:t1 c-flutter-tools-statusline" \
    "$(FAKE_MODEL_OUTPUT="Flutter Tools Statusline" run_tab_title "Trạng thái flutter-tools trên statusline" "c")"
FAKE_MODEL_OUTPUT="x" run_tab_title "Trạng thái" "c" >/dev/null
check "calls the model once for a non-English title" "called" "$(model_calls)"

check "leaves the tab alone when the model fails" \
    "not renamed" "$(FAKE_MODEL_FAIL=1 run_tab_title "Trạng thái flutter-tools" "c")"
check "keeps a tab that already has a custom name" \
    "not renamed" "$(run_tab_title "Fix login bug" "c-old-title")"
check "ignores the generic Claude Code title" \
    "not renamed" "$(run_tab_title "Claude Code" "c")"
check "does nothing outside herdr" \
    "not renamed" "$(run_tab_title "Fix login bug" "c" 0)"

finish_tests

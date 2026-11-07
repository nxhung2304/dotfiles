#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin"

cat >"$work_dir/bin/npm" <<EOF
#!/usr/bin/env bash
package_marker="$work_dir/\$(basename "\${!#}")-installed"
case "\$1" in
    list) [ -f "\$package_marker" ] ;;
    uninstall) rm -f "\$package_marker" ;;
esac
EOF
chmod +x "$work_dir/bin/npm"

remove_leftovers() {
    local home_dir=$1 answers=$2
    (
        export HOME=$home_dir PATH="$work_dir/bin:$PATH"
        DOTFILES_DIR="$home_dir/dotfiles"
        source "$repo_dir/scripts/install/common.sh"
        source "$repo_dir/scripts/install/ai.sh"
        printf '%b' "$answers" | remove_codex_gemini_leftovers >/dev/null 2>&1
    )
}

home_dir="$work_dir/home"
mkdir -p "$home_dir/.codex/sessions" "$home_dir/.gemini"
ln -s ../dotfiles/.codex/config.toml "$home_dir/.codex/config.toml"
ln -s ../dotfiles/.codex/rules "$home_dir/.codex/rules"
ln -s ../dotfiles/.gemini/settings.json "$home_dir/.gemini/settings.json"
ln -s /somewhere/else "$home_dir/.codex/own-link"
echo "token" >"$home_dir/.codex/auth.json"
touch "$work_dir/gemini-cli-installed" "$work_dir/codex-installed"

remove_leftovers "$home_dir" 'y\nn\n'
check "old codex config link removed" "missing" "$(describe_path "$home_dir/.codex/config.toml")"
check "old codex rules link removed" "missing" "$(describe_path "$home_dir/.codex/rules")"
check "old gemini settings link removed" "missing" "$(describe_path "$home_dir/.gemini/settings.json")"
check "link not made by dotfiles kept" "link" "$(describe_path "$home_dir/.codex/own-link")"
check "codex own data kept" "token" "$(cat "$home_dir/.codex/auth.json")"
check "codex sessions kept" "dir" "$(describe_path "$home_dir/.codex/sessions")"
check "gemini uninstalled after yes" "missing" "$(describe_path "$work_dir/gemini-cli-installed")"
check "codex kept after no" "file" "$(describe_path "$work_dir/codex-installed")"

exit_code=0
remove_leftovers "$work_dir/empty-home" '' || exit_code=$?
check "succeeds when nothing is left" "0" "$exit_code"

finish_tests

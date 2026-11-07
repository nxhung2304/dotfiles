#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
bundled_plugins=(git)

enabled_plugins=$(sed -n '/^plugins=(/,/^)/p' "$repo_dir/.zshrc" | sed '1d;$d' | tr -d ' ')

while IFS= read -r plugin; do
    [[ " ${bundled_plugins[*]} " == *" $plugin "* ]] && continue
    plugin_state=missing
    grep -qE "plugins/$plugin\"|for plugin in .*\b$plugin\b" "$repo_dir/scripts/install/shell.sh" && plugin_state=installed
    check "shell.sh installs enabled plugin $plugin" "installed" "$plugin_state"
done <<<"$enabled_plugins"

check "git config parses" "0" "$(git config -f "$repo_dir/.config/git/config" --list >/dev/null 2>&1; echo $?)"
check "zshrc ripgrep path points to a tracked file" "1" \
    "$(grep -c 'RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"' "$repo_dir/.zshrc")"
[[ -f "$repo_dir/.config/ripgrep/config" ]] && ripgrep_config_state=present || ripgrep_config_state=missing
check "ripgrep config exists in repo" "present" "$ripgrep_config_state"

finish_tests

#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mkdir -p "$work_dir/bin"

cat >"$work_dir/bin/mise" <<EOF
#!/usr/bin/env bash
[[ \$1 == which && -f "$work_dir/mise-gradle-installed" ]]
EOF
chmod +x "$work_dir/bin/mise"

remove_leftovers() {
    local home_dir=$1 answers=$2
    (
        export HOME=$home_dir PATH="$work_dir/bin:$PATH"
        source "$repo_dir/scripts/install/common.sh"
        source "$repo_dir/scripts/install/mobile.sh"
        printf '%b' "$answers" | remove_sdkman_leftovers >/dev/null 2>&1
    )
}

no_gradle_home="$work_dir/no-gradle-home"
mkdir -p "$no_gradle_home/.sdkman/candidates/gradle"
remove_leftovers "$no_gradle_home" 'y\n'
check "SDKMAN kept until mise has Gradle" "dir" "$(describe_path "$no_gradle_home/.sdkman")"

touch "$work_dir/mise-gradle-installed"

kept_home="$work_dir/kept-home"
mkdir -p "$kept_home/.sdkman/candidates/gradle"
remove_leftovers "$kept_home" 'n\n'
check "SDKMAN kept after no" "dir" "$(describe_path "$kept_home/.sdkman")"

removed_home="$work_dir/removed-home"
mkdir -p "$removed_home/.sdkman/candidates/gradle"
remove_leftovers "$removed_home" 'y\n'
check "SDKMAN removed after yes" "missing" "$(describe_path "$removed_home/.sdkman")"

exit_code=0
remove_leftovers "$work_dir/clean-home" '' || exit_code=$?
check "succeeds when SDKMAN was never installed" "0" "$exit_code"

check ".zshrc no longer loads SDKMAN" "0" "$(grep -c 'sdkman' "$repo_dir/.zshrc" || true)"

finish_tests

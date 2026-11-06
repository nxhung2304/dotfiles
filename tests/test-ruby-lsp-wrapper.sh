#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
mason_dir="$work_dir/home/.local/share/nvim/mason/packages/ruby-lsp"
mason_ruby_dir="$work_dir/runtimes/ruby/3.3.11/bin"
mkdir -p "$mason_dir/bin" "$mason_ruby_dir" "$work_dir/project-bin"

printf '#!%s/ruby\n' "$mason_ruby_dir" >"$mason_dir/bin/ruby-lsp"
cat >"$mason_dir/ruby-lsp" <<EOF
#!/usr/bin/env bash
echo "BUNDLE_GEMFILE=\${BUNDLE_GEMFILE:-none} args=\$*" >"$work_dir/launched"
EOF
cat >"$mason_ruby_dir/ruby" <<EOF
#!/usr/bin/env bash
echo "\$*" >>"$work_dir/mason-ruby-calls"
case "\$*" in
    *Gem.path*) echo "/gems" ;;
    *bundler*) echo "2.5.0" ;;
esac
EOF
chmod +x "$mason_dir/ruby-lsp" "$mason_ruby_dir/ruby"

use_project_ruby() {
    cat >"$work_dir/project-bin/ruby" <<EOF
#!/usr/bin/env bash
printf '%s' "$1"
EOF
    chmod +x "$work_dir/project-bin/ruby"
}

launch_wrapper() {
    rm -f "$work_dir/launched" "$work_dir/mason-ruby-calls"
    HOME="$work_dir/home" PATH="$work_dir/project-bin:$PATH" \
        bash "$repo_dir/scripts/nvim/ruby-lsp-wrapper" --stdio
    cat "$work_dir/launched"
}

use_project_ruby "3.3.11"
check "same Ruby as Mason runs ruby-lsp directly" "BUNDLE_GEMFILE=none args=--stdio" "$(launch_wrapper)"
check "same Ruby does not touch Mason's Ruby" "missing" "$(describe_path "$work_dir/mason-ruby-calls")"

use_project_ruby "2.7.8"
check "different Ruby uses the isolated bundle" \
    "BUNDLE_GEMFILE=$work_dir/home/.cache/ruby-lsp-isolated/Gemfile args=--stdio" "$(launch_wrapper)"
check "different Ruby runs Mason's own Ruby from the shebang" "file" "$(describe_path "$work_dir/mason-ruby-calls")"

finish_tests

#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/helpers.sh"

rules_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.claude/code-rules" && pwd)

resolve_rule_file() {
    local file_name=$1
    local candidate
    for candidate in "$rules_dir/$file_name" "$rules_dir"/*/"$file_name"; do
        if [[ -f $candidate ]]; then
            echo "$candidate"
            return 0
        fi
    done

    return 1
}

index_rows() {
    awk -F'|' '/^\| \*\*/ {
        gsub(/^ +| +$/, "", $3); gsub(/^ +| +$/, "", $4); gsub(/ /, "", $5)
        sub(/ \(.*$/, "", $4)
        split($5, line_range, "-")
        print $3 "\t" $4 "\t" line_range[1] "\t" line_range[2]
    }' "$rules_dir/index.md"
}

is_markdown_heading() {
    local line=$1
    [[ $line == \#* ]]
}

mentions_section() {
    local line=$1
    local section=$2
    [[ $line == *"$section"* ]]
}

range_fits_file() {
    local last_line=$1
    local line_count=$2
    [[ $last_line -le $line_count ]]
}

find_mismatches() {
    local file_name section first_line last_line rule_file heading line_count
    while IFS=$'\t' read -r file_name section first_line last_line; do
        if ! rule_file=$(resolve_rule_file "$file_name"); then
            echo "$file_name: file not found"
            continue
        fi

        heading=$(sed -n "${first_line}p" "$rule_file")
        line_count=$(wc -l <"$rule_file")

        if is_markdown_heading "$heading" && mentions_section "$heading" "$section" &&
            range_fits_file "$last_line" "$line_count"; then
            continue
        fi

        echo "$file_name:$first_line-$last_line expected [$section], found [$heading]"
    done < <(index_rows)
}

has_index_rows=false
[[ -n $(index_rows) ]] && has_index_rows=true

check "index has rows to verify" "true" "$has_index_rows"
check "every index row points at its section heading" "" "$(find_mismatches)"

finish_tests

#!/usr/bin/env bash
set -uo pipefail

tests_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
failed_tests=()

for test_file in "$tests_dir"/test-*.sh; do
    echo "=== $(basename "$test_file")"
    if ! bash "$test_file"; then
        failed_tests+=("$(basename "$test_file")")
    fi
done

if [[ ${#failed_tests[@]} -gt 0 ]]; then
    echo "FAILED: ${failed_tests[*]}"

    exit 1
fi

echo "All tests passed"

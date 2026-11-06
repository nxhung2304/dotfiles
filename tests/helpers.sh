#!/usr/bin/env bash

failure_count=0

check() {
    local description=$1 expected=$2 actual=$3
    if [[ $expected == "$actual" ]]; then
        echo "  PASS $description"
    else
        echo "  FAIL $description: expected [$expected], got [$actual]"
        failure_count=$((failure_count + 1))
    fi
}

finish_tests() {
    [[ $failure_count -eq 0 ]]
}

copy_repo_to() {
    local destination=$1
    local repo_dir
    repo_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
    mkdir -p "$destination"
    (cd "$repo_dir" && tar --exclude=.git -cf - .) | (cd "$destination" && tar -xf -)
}

describe_path() {
    local path=$1
    if [ -L "$path" ]; then
        echo "link"
    elif [ -d "$path" ]; then
        echo "dir"
    elif [ -e "$path" ]; then
        echo "file"
    else
        echo "missing"
    fi
}

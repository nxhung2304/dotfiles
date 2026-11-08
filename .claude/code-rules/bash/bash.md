# Bash Scripts

Conventions taken from the existing scripts in this repo. When a file already does it differently, follow that file (see Precedence in index.md).

## Script setup
- Start with `#!/usr/bin/env bash`.
- Standalone scripts set `set -euo pipefail` right after the shebang.
- Files meant to be sourced (install modules, shared helpers) do not set it; the caller decides.
- Put script-wide constants near the top as `readonly NAME=value`.

## Functions and variables
- Declare every function variable with `local`, and name positional args at the top: `local workspace_id=$1`.
- Quote every expansion: `"$var"`, `"${array[@]}"`.
- Use `[[ ... ]]` for tests.
- Silence commands whose output is not used with `>/dev/null`; keep stderr unless the failure is expected.

## Data
- Parse JSON with `jq`, never with grep/sed.
- Keep a multi-step jq or awk filter on its own indented lines instead of one long line.

## Checks
- Must pass `shellcheck -S error` (CI runs it on every shell script).
- New behaviour in a script under `scripts/` gets a test in `tests/test-<script>.sh`: stub external commands (herdr, fzf, gh, zoxide...) in a temp `bin/` on `PATH`, assert with `check` from `tests/helpers.sh`, end with `finish_tests`.

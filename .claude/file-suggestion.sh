#!/bin/bash
query=$(jq -r '.query // ""')
cd "${CLAUDE_PROJECT_DIR:-$PWD}" || exit 0
rg --files --follow --hidden --no-messages -g '!.git' | rg -i -F -- "$query" | head -15

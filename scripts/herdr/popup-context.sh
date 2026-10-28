export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

if [[ -n ${HERDR_ACTIVE_PANE_ID:-} ]]; then
    export HERDR_PANE_ID=$HERDR_ACTIVE_PANE_ID
fi

pick() {
    fzf --prompt="$1> " --height=100% --reverse "${@:2}"
}

pause_on_failure() {
    echo
    read -r -p "failed - press enter to close" _
}

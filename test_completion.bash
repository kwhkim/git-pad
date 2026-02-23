#!/usr/bin/env bash
set -euo pipefail

# Load completion environment
# Try Git Bash (Windows) paths first, then fall back to Linux paths
load_completion() {
    local git_bash_completion="/mingw64/share/git/completion/git-completion.bash"
    local linux_bash_completion="/usr/share/bash-completion/bash_completion"
    local linux_git_completion="/usr/share/bash-completion/completions/git"

    if [[ -f "$git_bash_completion" ]]; then
        # Git Bash on Windows bundles git completion directly
        source "$git_bash_completion"
    elif [[ -f "$linux_bash_completion" ]]; then
        source "$linux_bash_completion"
        [[ -f "$linux_git_completion" ]] && source "$linux_git_completion"
    else
        echo "ERROR: Could not find bash-completion files." >&2
        exit 1
    fi
}

load_completion
source ./autocompletion.bash

# Simulate:
# git pad e<TAB>
echo '- Testing git pad e<TAB>'
COMP_WORDS=(git pad e)
COMP_CWORD=2
COMP_LINE="git pad e"
COMP_POINT=${#COMP_LINE}

_git_pad

printf '%s\n' "${COMPREPLY[@]}"
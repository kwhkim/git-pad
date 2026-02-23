#!/usr/bin/env bash
set -euo pipefail

# Load completion environment
source /usr/share/bash-completion/bash_completion
source /usr/share/bash-completion/completions/git
source ./autocompletion.sh

# # Simulate:
# # git pad edit P<TAB>
# COMP_WORDS=(git pad edit P)
# COMP_CWORD=3
# COMP_LINE="git pad edit P"
# COMP_POINT=${#COMP_LINE}
# 
# _git_pad
# 
# printf '%s\n' "${COMPREPLY[@]}"


# Simulate:
# git pad e<TAB>
echo '- Testing git pad e<TAB>'
COMP_WORDS=(git pad e)
COMP_CWORD=2
COMP_LINE="git pad e"
COMP_POINT=${#COMP_LINE}

_git_pad

printf '%s\n' "${COMPREPLY[@]}"

#!/bin/bash
# shellcheck disable=SC2016
if [ ! -f "git-pad" ] || [ ! -f "autocompletion.sh" ]; then
  echo '!E: Not in git-pad directory';
  exit 1
fi

block='
## git-pad
PATH=$PATH:'"$PWD"';
export PATH;
source '"$(realpath autocompletion.sh);"

shell_name="$(basename "$SHELL")"

case "$shell_name" in
  bash) rc="$HOME/.bashrc" ;;
  zsh)  rc="$HOME/.zshrc" ;;
  *) echo "Unsupported shell"; exit 1 ;;
esac

grep -q '## git-pad' "$rc" 2>/dev/null || echo "$block" >> "$rc"
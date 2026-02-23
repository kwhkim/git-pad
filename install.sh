#!/usr/bin/env bash
# shellcheck disable=SC2016
if [ ! -f "git-pad" ] || [ ! -f "autocompletion.sh" ]; then
  echo '!E: Not in git-pad directory';
  exit 1
fi

block='
## git-pad
PATH=$PATH:'"$PWD"';
export PATH;
. '"$PWD/autocompletion.sh;"

shell_name="$(basename "$SHELL")"

case "$shell_name" in
  bash) rc="$HOME/.bashrc" ;;
  zsh)  rc="$HOME/.zshrc" ;;
  *) echo "Unsupported shell"; exit 1 ;;
esac

if grep -q '## git-pad' "$rc" 2>/dev/null; then
  echo '!W: Looks like it is already installed'
  echo '--------------------------------------'
  grep -C 5 '## git-pad' "$rc"
else
  echo "$block" >> "$rc" && echo "Installed successfully. Restart your shell."
fi
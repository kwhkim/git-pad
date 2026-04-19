#!/usr/bin/env sh
# shellcheck disable=SC2016
if [ ! -f "git-pad" ] || { [ ! -f "autocompletion.bash" ] && [ ! -f "autocompletion.zsh" ]; } ; then
  echo '!E: Not in git-pad directory';
  exit 1
fi

# On Windows/Git Bash, $SHELL may be unset or a Windows path
# so detect the shell via version variables instead
if [ -n "${ZSH_VERSION:-}" ]; then
    shell_name="zsh"
elif [ -n "${BASH_VERSION:-}" ]; then
    shell_name="bash"
else
    shell_name="$(basename "${SHELL:-unknown}")"
fi

# On Windows, $HOME may be unset
if [ -z "${HOME:-}" ]; then
    HOME="$(cd ~ && pwd)"
fi

case "$shell_name" in
  bash)
        rc="$HOME/.bashrc"
        block='
## git-pad
PATH=$PATH:'"$PWD"'
export PATH
. '"$PWD"'/autocompletion.bash'
        ;;
  zsh)
        rc="$HOME/.zshrc"
        block='
## git-pad
PATH=$PATH:'"$PWD"'
export PATH
. '"$PWD"'/autocompletion.zsh'
        ;;
  *) echo "Unsupported shell: $shell_name"; exit 1 ;;
esac

if grep -q '## git-pad' "$rc" 2>/dev/null; then
  echo '!W: Looks like it is already installed'
  echo '--------------------------------------'
  grep -C 5 '## git-pad' "$rc"
else
  echo "$block" >> "$rc" && echo "Installed successfully. Restart your shell."
fi

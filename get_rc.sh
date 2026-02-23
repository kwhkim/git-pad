if [[ -n "${ZSH_VERSION:-}" ]]; then
    shell_name="zsh"
elif [[ -n "${BASH_VERSION:-}" ]]; then
    shell_name="bash"
else
    shell_name="$(basename "${SHELL:-unknown}")"
fi

# On Windows, $HOME may be unset
if [[ -z "${HOME:-}" ]]; then
    HOME="$(cd ~ && pwd)"
fi

case "$shell_name" in
    bash)
        rc="$HOME/.bashrc"
        ;;
    zsh)
        rc="$HOME/.zshrc"
        ;;
    *) echo "Unsupported shell: $shell_name"; exit 1 ;;
esac

echo "$rc"